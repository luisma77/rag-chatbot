from docx import Document

from src.logger import get_logger

logger = get_logger(__name__)


def extract_docx(file_path: str) -> str:
    doc = Document(file_path)
    paragraphs = [p.text for p in doc.paragraphs if p.text.strip()]
    text = "\n\n".join(paragraphs)
    logger.debug(f"DOCX '{file_path}': {len(paragraphs)} párrafos, {len(text)} chars")
    return text
