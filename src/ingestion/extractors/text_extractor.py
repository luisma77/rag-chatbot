from pathlib import Path

import chardet
from bs4 import BeautifulSoup

from src.logger import get_logger

logger = get_logger(__name__)


def extract_text(file_path: str) -> str:
    path = Path(file_path)
    suffix = path.suffix.lower()

    raw = path.read_bytes()
    encoding = _detect_encoding(raw)
    text = raw.decode(encoding, errors="replace")

    if suffix in (".html", ".htm"):
        soup = BeautifulSoup(text, "html.parser")
        return soup.get_text(separator="\n")

    return text


def _detect_encoding(raw: bytes) -> str:
    result = chardet.detect(raw)
    return result.get("encoding") or "utf-8"
