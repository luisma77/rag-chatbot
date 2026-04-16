import hashlib
import time
from typing import Optional

from src.logger import get_logger

logger = get_logger(__name__)


class ResponseCache:
    def __init__(self, ttl_seconds: int = 7200):
        self._store: dict = {}
        self._ttl = ttl_seconds

    def _key(self, question: str) -> str:
        normalised = question.strip().lower()
        return hashlib.sha256(normalised.encode("utf-8")).hexdigest()

    def get(self, question: str) -> Optional[dict]:
        key = self._key(question)
        entry = self._store.get(key)
        if entry is None:
            return None
        value, expires_at = entry
        if time.time() > expires_at:
            del self._store[key]
            logger.debug("Cache: entrada expirada eliminada")
            return None
        logger.debug("Cache hit")
        return value

    def set(self, question: str, response: dict) -> None:
        key = self._key(question)
        self._store[key] = (response, time.time() + self._ttl)
        logger.debug(f"Cache: nueva entrada ({len(self._store)} total)")

    def size(self) -> int:
        now = time.time()
        expired = [k for k, (_, exp) in self._store.items() if now > exp]
        for k in expired:
            del self._store[k]
        return len(self._store)
