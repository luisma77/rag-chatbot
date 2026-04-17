#!/usr/bin/env python
"""
Shared reindex core.

This file stays internal to the repository and is invoked through
profile-specific wrappers so each runnable variant has its own entrypoint.
"""
import logging
import os
import sys

_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, _ROOT)

logging.getLogger("src").setLevel(logging.WARNING)
logging.getLogger("chromadb").setLevel(logging.ERROR)
logging.getLogger("sentence_transformers").setLevel(logging.ERROR)
logging.getLogger("transformers").setLevel(logging.ERROR)
logging.getLogger("httpx").setLevel(logging.ERROR)
logging.getLogger("urllib3").setLevel(logging.ERROR)


def _icon(status: str) -> str:
    return {"ok": "✓", "skipped": "~", "error": "✗", "deleted": "✗"}.get(status, "?")


def index_single(filepath: str, action: str) -> None:
    from pathlib import Path
    from src.ingestion.pipeline import process_file

    name = Path(filepath).name
    print(f"\n  Archivo : {name}")
    print(f"  Acción  : {action}")
    result = process_file(filepath, action)
    icon = _icon(result["status"])
    if result["status"] == "ok":
        print(f"  {icon} Indexado: {result.get('chunks_indexed', 0)} chunks")
    elif result["status"] == "deleted":
        print(f"  {icon} Chunks eliminados de ChromaDB")
    elif result["status"] == "skipped":
        print(f"  {icon} Omitido : {result.get('reason', '')}")
    else:
        print(f"  {icon} Error   : {result.get('error', result.get('reason', ''))}")


def index_all() -> None:
    from pathlib import Path
    import os as _os
    from src.config import settings
    from src.ingestion.pipeline import EXTRACTORS, process_file
    from src.vectordb.chroma_store import chroma_store

    doc_dir = Path(settings.documents_dir)
    if not doc_dir.exists():
        print(f"  [!] Carpeta no encontrada: {doc_dir}")
        return

    files = sorted(
        f for f in doc_dir.rglob("*")
        if f.is_file() and f.suffix.lower() in EXTRACTORS
    )

    if not files:
        print("  Sin documentos que procesar.")
        return

    total = len(files)
    indexed = 0
    skipped = 0
    errors = 0

    print(f"\n  {total} documento(s) encontrado(s):\n")

    for i, fp in enumerate(files, 1):
        name = fp.name
        current_mtime = str(int(_os.path.getmtime(str(fp))))
        stored_mtime = chroma_store.get_source_mtime(fp.name)
        pad = len(str(total))

        print(f"  [{i:>{pad}}/{total}] {name}")
        if stored_mtime == current_mtime:
            print("        ~ Sin cambios — ya indexado")
            skipped += 1
            continue

        print("        → Indexando... ", end="", flush=True)
        result = process_file(str(fp), "created")
        if result["status"] == "ok":
            print(f"{result.get('chunks_indexed', 0)} chunks ✓")
            indexed += 1
        else:
            reason = result.get("reason") or result.get("error", "")
            print(f"✗ {reason}")
            errors += 1

    print()
    print(f"  {'─' * 40}")
    print(f"  Nuevos      : {indexed}")
    print(f"  Sin cambios : {skipped}")
    print(f"  Errores     : {errors}")
    print(f"  Total       : {total}")
    print(f"  Vectores DB : {chroma_store.count()}")
    print()


if __name__ == "__main__":
    if not os.path.exists(os.path.join(_ROOT, "src", "main.py")):
        print("\n  [ERROR] Ejecuta este helper dentro de la repo del proyecto.\n")
        sys.exit(1)

    if len(sys.argv) >= 3:
        index_single(sys.argv[1], sys.argv[2])
    else:
        index_all()
