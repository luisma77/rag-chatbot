import pytest
from unittest.mock import patch, AsyncMock
from fastapi.testclient import TestClient


@pytest.fixture
def client():
    from src.main import app
    return TestClient(app)


def test_health_returns_200(client):
    with patch("src.api.admin.check_health", new_callable=AsyncMock, return_value=True), \
         patch("src.api.admin.chroma_store") as mock_store:
        mock_store.count.return_value = 42
        response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] in ("ok", "degraded")
    assert "ollama" in data
    assert "chromadb_vectors" in data


def test_stats_returns_vector_count(client):
    with patch("src.api.admin.chroma_store") as mock_store:
        mock_store.count.return_value = 99
        response = client.get("/stats")
    assert response.status_code == 200
    assert response.json()["chromadb_vectors"] == 99
