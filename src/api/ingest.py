from fastapi import APIRouter
from pydantic import BaseModel

from src.ingestion.pipeline import process_file, process_all
from src.logger import get_logger

router = APIRouter()
logger = get_logger(__name__)


class FileIngestRequest(BaseModel):
    path: str
    action: str  # created | changed | deleted | renamed


@router.post("/ingest")
def ingest_all():
    """Scan documents directory and index all supported files."""
    logger.info("Ingesta completa iniciada")
    return process_all()


@router.post("/ingest/file")
def ingest_file(req: FileIngestRequest):
    """Index or remove a single file (called by FileSystemWatcher)."""
    logger.info(f"Ingesta de archivo: action={req.action} path={req.path}")
    return process_file(req.path, action=req.action)
