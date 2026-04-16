import pytest
from unittest.mock import patch, AsyncMock, MagicMock
from fastapi.testclient import TestClient


@pytest.fixture
def client():
    from src.main import app
    return TestClient(app)


def test_chat_returns_answer(client):
    chunks = [{"text": "Info relevante", "score": 0.8, "source_file": "doc.pdf", "chunk_index": 0}]
    with patch("src.api.chat.chroma_store") as mock_store, \
         patch("src.api.chat.generate", new_callable=AsyncMock, return_value="La respuesta es X"), \
         patch("src.api.chat._cache") as mock_cache:
        mock_cache.get.return_value = None
        mock_store.query.return_value = chunks
        response = client.post("/chat", json={"question": "¿Cuál es el proceso?"})
    assert response.status_code == 200
    data = response.json()
    assert "answer" in data
    assert "sources" in data
    assert "confidence" in data


def test_chat_returns_conversational_when_below_threshold(client):
    """Below threshold → LLM is called with conversational prompt (no static fallback)."""
    chunks = [{"text": "Info poco relevante", "score": 0.3, "source_file": "doc.pdf", "chunk_index": 0}]
    with patch("src.api.chat.chroma_store") as mock_store, \
         patch("src.api.chat.generate", new_callable=AsyncMock, return_value="Hola, ¿en qué puedo ayudarte?"), \
         patch("src.api.chat._cache") as mock_cache:
        mock_cache.get.return_value = None
        mock_store.query.return_value = chunks
        response = client.post("/chat", json={"question": "hola"})
    assert response.status_code == 200
    data = response.json()
    assert data["confidence"] == "none"
    assert data["sources"] == []
    assert "answer" in data
    assert len(data["answer"]) > 0


def test_chat_returns_cached_response(client):
    cached = {
        "answer": "Respuesta cacheada",
        "sources": [],
        "confidence": "high",
        "cached": True,
        "response_time_ms": 5,
    }
    with patch("src.api.chat._cache") as mock_cache:
        mock_cache.get.return_value = cached
        response = client.post("/chat", json={"question": "Pregunta cacheada"})
    assert response.status_code == 200
    assert response.json()["cached"] is True
