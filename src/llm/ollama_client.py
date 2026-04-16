import httpx

from src.config import settings
from src.logger import get_logger

logger = get_logger(__name__)


async def generate(prompt: str, temperature: float = 0.1) -> str:
    """Call Ollama API and return the generated text."""
    payload = {
        "model": settings.ollama_model,
        "prompt": prompt,
        "stream": False,
        "options": {
            "temperature": temperature,
            "num_predict": 512,
        },
    }

    url = f"{settings.ollama_base_url}/api/generate"

    async with httpx.AsyncClient(timeout=settings.ollama_timeout) as client:
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
        async with httpx.AsyncClient(timeout=5) as client:
            response = await client.get(f"{settings.ollama_base_url}/api/tags")
            if response.status_code != 200:
                return False
            tags = response.json().get("models", [])
            model_names = [t.get("name", "") for t in tags]
            return any(settings.ollama_model in name for name in model_names)
    except Exception:
        return False
