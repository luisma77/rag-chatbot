"""
auth.py — Optional API key authentication.

Set API_KEY in .env to enable. Leave empty for local/dev (no auth).

Usage in routes:
    from src.api.auth import require_api_key
    @router.post("/chat", dependencies=[Depends(require_api_key)])
"""
from fastapi import Depends, HTTPException, Security, status
from fastapi.security import APIKeyHeader

from src.config import settings

_header_scheme = APIKeyHeader(name="X-API-Key", auto_error=False)


async def require_api_key(key: str = Security(_header_scheme)) -> None:
    """FastAPI dependency — passes through if API_KEY is not configured."""
    if not settings.api_key:
        return  # Auth disabled — development / local mode
    if key != settings.api_key:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="API key inválida o ausente. Incluye el header: X-API-Key: <clave>",
        )
