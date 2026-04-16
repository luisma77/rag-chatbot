import pytest
from unittest.mock import patch
from fastapi.testclient import TestClient


@pytest.fixture
def client():
    from src.main import app
    return TestClient(app)


def test_ingest_all_returns_200(client):
    with patch("src.api.ingest.process_all", return_value={"total": 3, "ok": 3, "results": []}):
        response = client.post("/ingest")
    assert response.status_code == 200
    assert response.json()["ok"] == 3


def test_ingest_file_created_returns_200(client):
    with patch("src.api.ingest.process_file", return_value={
        "action": "created", "source": "doc.pdf", "status": "ok", "chunks_indexed": 12
    }):
        response = client.post(
            "/ingest/file",
            json={"path": "C:/data/documents/doc.pdf", "action": "created"},
        )
    assert response.status_code == 200
    assert response.json()["chunks_indexed"] == 12


def test_ingest_file_deleted_returns_200(client):
    with patch("src.api.ingest.process_file", return_value={
        "action": "deleted", "source": "doc.pdf", "status": "ok"
    }):
        response = client.post(
            "/ingest/file",
            json={"path": "C:/data/doc.pdf", "action": "deleted"},
        )
    assert response.status_code == 200
