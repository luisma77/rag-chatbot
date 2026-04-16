import asyncio
import time
from typing import Optional

from fastapi import APIRouter
from pydantic import BaseModel

from src.cache.conversation_memory import conversation_memory
from src.cache.response_cache import ResponseCache
from src.config import settings
from src.llm.ollama_client import generate
from src.llm.prompt_builder import build_prompt, build_conversational_prompt

from src.logger import get_logger
from src.vectordb.chroma_store import chroma_store

router = APIRouter()
logger = get_logger(__name__)

_cache = ResponseCache(ttl_seconds=settings.cache_ttl_seconds)
_semaphore = asyncio.Semaphore(settings.max_concurrent_llm)


class ChatRequest(BaseModel):
    question: str
    session_id: Optional[str] = None


@router.post("/chat")
async def chat(req: ChatRequest):
    start = time.time()
    question = req.question.strip()

    # 1. Cache check
    cached = _cache.get(question)
    if cached:
        return {**cached, "cached": True, "response_time_ms": int((time.time() - start) * 1000)}

    # 2. Semantic search
    hits = chroma_store.query(question, top_k=settings.top_k)

    # 3. Get conversation history for this session
    session_id = req.session_id or "default"
    history = conversation_memory.get(session_id)

    # 4. Threshold filter — below threshold → conversational LLM answer (no doc context)
    top_score = hits[0]["score"] if hits else 0.0
    if top_score < settings.similarity_threshold:
        logger.info(
            f"Sin contexto relevante (score={top_score:.3f} < {settings.similarity_threshold}) "
            "— respuesta conversacional"
        )
        conv_prompt = build_conversational_prompt(question, history=history)
        async with _semaphore:
            answer = await generate(conv_prompt, temperature=0.7)

        # Store in memory
        conversation_memory.add(session_id, "user", question)
        conversation_memory.add(session_id, "assistant", answer)

        return {
            "answer": answer,
            "cached": False,
            "response_time_ms": int((time.time() - start) * 1000),
        }

    # 5. Build RAG prompt and call LLM (rate-limited via semaphore)
    prompt = build_prompt(question, hits, history=history)
    async with _semaphore:
        answer = await generate(prompt)

    # 6. Determine confidence for caching
    avg_score = sum(h["score"] for h in hits) / len(hits)
    confidence = "high" if avg_score >= settings.cache_threshold else "low"

    # 7. Store in conversation memory
    conversation_memory.add(session_id, "user", question)
    conversation_memory.add(session_id, "assistant", answer)

    response = {
        "answer": answer,
        "cached": False,
        "response_time_ms": int((time.time() - start) * 1000),
    }

    # 8. Cache if high confidence
    if confidence == "high":
        _cache.set(question, response)

    return response
