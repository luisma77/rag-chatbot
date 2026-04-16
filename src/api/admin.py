from fastapi import APIRouter

from src.ingestion.pipeline import process_all
from src.llm.ollama_client import check_health
from src.logger import get_logger
from src.vectordb.chroma_store import chroma_store

router = APIRouter()
logger = get_logger(__name__)


@router.get("/health")
async def health():
    ollama_ok = await check_health()
    vector_count = chroma_store.count()
    return {
        "status": "ok" if ollama_ok else "degraded",
        "ollama": "ok" if ollama_ok else "unreachable",
        "ollama_model": settings_model(),
        "chromadb": "ok",
        "chromadb_vectors": vector_count,
    }


@router.get("/stats")
def stats():
    return {
        "chromadb_vectors": chroma_store.count(),
    }


@router.post("/reindex")
def reindex():
    """Wipe ChromaDB collection and reindex all documents from scratch."""
    logger.warning("Reindexado completo iniciado — borrando colección existente")
    chroma_store.reset()
    result = process_all()
    logger.info(f"Reindexado completo: {result['ok']}/{result['total']} archivos")
    return result


def settings_model() -> str:
    from src.config import settings
    return settings.ollama_model
