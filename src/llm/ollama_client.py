import httpx

from src.config import settings
from src.logger import get_logger

logger = get_logger(__name__)
_client: httpx.AsyncClient | None = None


def _get_client() -> httpx.AsyncClient:
    global _client
    if _client is None:
        _client = httpx.AsyncClient(
            timeout=settings.ollama_timeout,
            limits=httpx.Limits(max_keepalive_connections=10, max_connections=20),
        )
    return _client


async def close_client() -> None:
    global _client
    if _client is not None:
        await _client.aclose()
        _client = None


async def generate(prompt: str, temperature: float = 0.1) -> str:
    """Call Ollama API and return the generated text."""
    payload = {
        "model": settings.ollama_model,
        "prompt": prompt,
        "stream": False,
        "keep_alive": settings.ollama_keep_alive,
        "options": {
            "temperature": temperature,
            "num_predict": settings.ollama_num_predict,
        },
    }

    url = f"{settings.ollama_base_url}/api/generate"

    client = _get_client()
    logger.debug(f"Llamando Ollama: {settings.ollama_model}")
    response = await client.post(url, json=payload)
    response.raise_for_status()
    data = response.json()
    text = data.get("response", "").strip()
    logger.debug(f"Ollama respondió: {len(text)} chars")
    return text


async def check_health() -> bool:
    """Check if Ollama is reachable and the model is available."""
    try:
        client = _get_client()
        response = await client.get(f"{settings.ollama_base_url}/api/tags", timeout=5)
        if response.status_code != 200:
            return False
        tags = response.json().get("models", [])
        model_names = [t.get("name", "") for t in tags]
        return any(settings.ollama_model in name for name in model_names)
    except Exception:
        return False
