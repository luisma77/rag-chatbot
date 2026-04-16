import os
from pathlib import Path

from src.config import settings
from src.ingestion.cleaner import clean_text
from src.ingestion.chunker import chunk_text
from src.ingestion.extractors.text_extractor import extract_text
from src.ingestion.extractors.image_extractor import extract_image
from src.ingestion.extractors.docx_extractor import extract_docx
from src.ingestion.extractors.office_extractor import extract_pptx, extract_xlsx
from src.ingestion.extractors.pdf_extractor import extract_pdf
from src.logger import get_logger
from src.vectordb.chroma_store import chroma_store

logger = get_logger(__name__)

# Supported extensions → extractor function
EXTRACTORS = {
    ".pdf": extract_pdf,
    ".docx": extract_docx,
    ".pptx": extract_pptx,
    ".xlsx": extract_xlsx,
    ".txt": extract_text,
    ".md": extract_text,
    ".html": extract_text,
    ".htm": extract_text,
    ".jpg": extract_image,
    ".jpeg": extract_image,
    ".png": extract_image,
    ".tiff": extract_image,
    ".tif": extract_image,
    ".bmp": extract_image,
    ".webp": extract_image,
}


def process_file(file_path: str, action: str) -> dict:
    """Process a single file: extract, clean, chunk, and upsert into ChromaDB.

    action: 'created' | 'changed' | 'deleted' | 'renamed'
    Returns a result dict with status details.
    """
    path = Path(file_path)
    filename = path.name
    suffix = path.suffix.lower()

    if action == "deleted":
        chroma_store.delete_by_source(filename)
        logger.info(f"Eliminados chunks de '{filename}' (archivo borrado)")
        return {"action": "deleted", "source": filename, "status": "ok"}

    if suffix not in EXTRACTORS:
        logger.warning(f"Formato no soportado: '{suffix}' — archivo '{filename}' omitido")
        return {
            "action": action,
            "source": filename,
            "status": "skipped",
            "reason": f"unsupported format: {suffix}",
        }

    try:
        extractor = EXTRACTORS[suffix]
        raw_text = extractor(file_path)
    except Exception as exc:
        logger.error(f"Error extrayendo '{filename}': {exc}")
        return {"action": action, "source": filename, "status": "error", "error": str(exc)}

    if not raw_text.strip():
        logger.warning(f"'{filename}': sin texto extraíble, omitido")
        return {
            "action": action,
            "source": filename,
            "status": "skipped",
            "reason": "no text extracted",
        }

    cleaned = clean_text(raw_text)
    chunks = chunk_text(cleaned, settings.chunk_size, settings.chunk_overlap)

    if not chunks:
        return {
            "action": action,
            "source": filename,
            "status": "skipped",
            "reason": "no chunks after cleaning",
        }

    # Delete previous version if updating
    chroma_store.delete_by_source(filename)

    # Enrich chunks with file metadata (mtime lets process_all skip unchanged files)
    file_mtime = str(int(os.path.getmtime(file_path)))
    for chunk in chunks:
        chunk["source_file"] = filename
        chunk["file_mtime"] = file_mtime

    chroma_store.add_chunks(chunks)

    logger.info(f"'{filename}': {len(chunks)} chunks indexados")
    return {
        "action": action,
        "source": filename,
        "status": "ok",
        "chunks_indexed": len(chunks),
    }


def process_all(documents_dir: str = None) -> dict:
    """Process all supported files in the documents directory."""
    doc_dir = Path(documents_dir or settings.documents_dir)
    if not doc_dir.exists():
        return {"status": "error", "error": f"Directory not found: {doc_dir}"}

    results = []
    for file_path in doc_dir.rglob("*"):
        if not (file_path.is_file() and file_path.suffix.lower() in EXTRACTORS):
            continue

        # Skip files that are already indexed with the same modification time
        current_mtime = str(int(os.path.getmtime(str(file_path))))
        stored_mtime = chroma_store.get_source_mtime(file_path.name)
        if stored_mtime == current_mtime:
            logger.info(f"'{file_path.name}': sin cambios, ya indexado — omitido")
            results.append({"action": "skipped", "source": file_path.name,
                            "status": "skipped", "reason": "already indexed"})
            continue

        result = process_file(str(file_path), action="created")
        results.append(result)

    ok = sum(1 for r in results if r["status"] == "ok")
    logger.info(f"Ingesta completa: {ok}/{len(results)} archivos indexados")
    return {"total": len(results), "ok": ok, "results": results}
