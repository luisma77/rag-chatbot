import re

from src.logger import get_logger

logger = get_logger(__name__)


def clean_text(text: str) -> str:
    """Normalise extracted text: collapse whitespace, remove noise."""
    if not text or not text.strip():
        return ""

    # Replace Windows line endings
    text = text.replace("\r\n", "\n").replace("\r", "\n")

    # Collapse runs of spaces/tabs (not newlines)
    text = re.sub(r"[ \t]{2,}", " ", text)

    # Collapse more than 2 consecutive newlines into exactly 2
    text = re.sub(r"\n{3,}", "\n\n", text)

    # Remove lines that are only whitespace
    lines = [line.rstrip() for line in text.split("\n")]
    text = "\n".join(lines)

    return text.strip()
