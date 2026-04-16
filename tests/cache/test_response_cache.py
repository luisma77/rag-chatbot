import time
from src.cache.response_cache import ResponseCache


def test_cache_stores_and_retrieves():
    cache = ResponseCache(ttl_seconds=60)
    cache.set("¿Cuál es el proceso?", {"answer": "El proceso es X"})
    result = cache.get("¿Cuál es el proceso?")
    assert result is not None
    assert result["answer"] == "El proceso es X"


def test_cache_miss_returns_none():
    cache = ResponseCache(ttl_seconds=60)
    result = cache.get("Pregunta que no existe")
    assert result is None


def test_cache_expires_after_ttl():
    cache = ResponseCache(ttl_seconds=1)
    cache.set("Pregunta", {"answer": "Respuesta"})
    time.sleep(1.1)
    result = cache.get("Pregunta")
    assert result is None


def test_cache_is_stripped():
    cache = ResponseCache(ttl_seconds=60)
    cache.set("¿Cuál es el proceso?", {"answer": "X"})
    result = cache.get("  ¿Cuál es el proceso?  ")
    assert result is not None


def test_cache_size():
    cache = ResponseCache(ttl_seconds=60)
    cache.set("q1", {"answer": "a1"})
    cache.set("q2", {"answer": "a2"})
    assert cache.size() == 2
