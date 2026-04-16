from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import Depends, FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from src.api import chat, ingest, admin
from src.api.auth import require_api_key
from src.config import settings
from src.logger import get_logger

logger = get_logger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("RAG Chatbot iniciando...")
    # process_all() skips files already indexed with the same mtime — safe to always call
    from src.ingestion.pipeline import process_all
    from src.vectordb.chroma_store import chroma_store
    result = process_all()
    new_ok    = sum(1 for r in result.get("results", []) if r["status"] == "ok")
    skipped   = sum(1 for r in result.get("results", []) if r["status"] == "skipped")
    total     = result.get("total", 0)
    logger.info(
        f"Indexación al inicio: {new_ok} nuevos, {skipped} sin cambios, "
        f"{total} total — {chroma_store.count()} vectores en ChromaDB"
    )
    logger.info("Backend listo para recibir peticiones")
    yield
    logger.info("RAG Chatbot detenido")


app = FastAPI(
    title="RAG Chatbot Empresarial",
    description="API para consulta de documentación interna basada en RAG",
    version="1.0.0",
    lifespan=lifespan,
)

_origins = [o.strip() for o in settings.allowed_origins.split(",") if o.strip()]

app.add_middleware(
    CORSMiddleware,
    allow_origins=_origins,
    allow_methods=["GET", "POST", "DELETE"],
    allow_headers=["*"],
)

_auth = [Depends(require_api_key)]

app.include_router(chat.router,   dependencies=_auth, tags=["Chat"])
app.include_router(ingest.router, dependencies=_auth, tags=["Ingestion"])
app.include_router(admin.router,  dependencies=_auth, tags=["Admin"])

# Serve the chat UI at /static/chat.html
_static_dir = Path(__file__).parent / "static"
if _static_dir.exists():
    app.mount("/static", StaticFiles(directory=str(_static_dir)), name="static")
