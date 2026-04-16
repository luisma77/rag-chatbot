from fastapi.testclient import TestClient


def test_app_has_docs():
    from src.main import app
    client = TestClient(app)
    response = client.get("/docs")
    assert response.status_code == 200


def test_openapi_includes_endpoints():
    from src.main import app
    client = TestClient(app)
    response = client.get("/openapi.json")
    assert response.status_code == 200
    paths = response.json()["paths"]
    assert "/chat" in paths
    assert "/ingest" in paths
    assert "/health" in paths
