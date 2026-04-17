from functools import lru_cache

import httpx
from sentence_transformers import SentenceTransformer

from src.config import settings
from src.logger import get_logger

logger = get_logger(__name__)
_ollama_client: httpx.Client | None = None


@lru_cache(maxsize=1)
def _get_model() -> SentenceTransformer:
    logger.info(f"Cargando modelo de embeddings: {settings.embedding_model}")
    model = SentenceTransformer(settings.embedding_model)
    logger.info("Modelo de embeddings cargado")
    return model


def _get_ollama_client() -> httpx.Client:
    global _ollama_client
    if _ollama_client is None:
        _ollama_client = httpx.Client(timeout=settings.ollama_timeout)
    return _ollama_client


def close_embedding_clients() -> None:
    global _ollama_client
    if _ollama_client is not None:
        _ollama_client.close()
        _ollama_client = None


def _encode_with_ollama(texts: list[str]) -> list[list[float]]:
    client = _get_ollama_client()
    response = client.post(
        f"{settings.ollama_base_url}/api/embed",
        json={
            "model": settings.embedding_model,
            "input": texts,
        },
    )
    response.raise_for_status()
    embeddings = response.json().get("embeddings", [])
    if len(embeddings) != len(texts):
        raise ValueError("Ollama no devolvio el numero esperado de embeddings")
    return embeddings


def encode(texts: list) -> list:
    """Encode a list of texts into embedding vectors.

    Returns list of 384-dim float lists.
    """
    if settings.embedding_provider.lower() == "ollama":
        return _encode_with_ollama(texts)

    model = _get_model()
    embeddings = model.encode(
        texts,
        show_progress_bar=False,
        batch_size=settings.embedding_batch_size,
    )
    return embeddings.tolist()


def encode_one(text: str) -> list:
    """Encode a single text. Convenience wrapper around encode()."""
    return encode([text])[0]
