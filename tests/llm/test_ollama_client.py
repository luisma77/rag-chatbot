import pytest
from unittest.mock import AsyncMock, MagicMock, patch


@pytest.mark.asyncio
async def test_generate_returns_text():
    from src.llm.ollama_client import generate
    mock_response = MagicMock()
    mock_response.json.return_value = {"response": "Respuesta generada por el modelo"}
    mock_response.raise_for_status = MagicMock()

    mock_client = AsyncMock()
    mock_client.__aenter__ = AsyncMock(return_value=mock_client)
    mock_client.__aexit__ = AsyncMock(return_value=False)
    mock_client.post = AsyncMock(return_value=mock_response)

    with patch("src.llm.ollama_client.httpx.AsyncClient", return_value=mock_client):
        result = await generate("Prompt de prueba")

    assert result == "Respuesta generada por el modelo"
