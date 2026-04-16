from functools import lru_cache

from sentence_transformers import SentenceTransformer

from src.config import settings
from src.logger import get_logger

logger = get_logger(__name__)


@lru_cache(maxsize=1)
def _get_model() -> SentenceTransformer:
    logger.info(f"Cargando modelo de embeddings: {settings.embedding_model}")
    model = SentenceTransformer(settings.embedding_model)
    logger.info("Modelo de embeddings cargado")
    return model


def encode(texts: list) -> list:
    """Encode a list of texts into embedding vectors.

    Returns list of 384-dim float lists.
    """
    model = _get_model()
    embeddings = model.encode(texts, show_progress_bar=False, batch_size=32)
    return embeddings.tolist()


def encode_one(text: str) -> list:
    """Encode a single text. Convenience wrapper around encode()."""
    return encode([text])[0]
