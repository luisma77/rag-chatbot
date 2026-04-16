from langchain_text_splitters import RecursiveCharacterTextSplitter

from src.logger import get_logger

logger = get_logger(__name__)


def chunk_text(
    text: str,
    chunk_size: int = 800,
    overlap: int = 100,
) -> list:
    """Split text into overlapping chunks with metadata.

    Returns list of dicts: {"text": str, "chunk_index": int}
    """
    if not text or not text.strip():
        return []

    splitter = RecursiveCharacterTextSplitter(
        chunk_size=chunk_size,
        chunk_overlap=overlap,
        separators=["\n\n", "\n", ". ", " ", ""],
    )

    pieces = splitter.split_text(text)
    chunks = [
        {"text": piece.strip(), "chunk_index": idx}
        for idx, piece in enumerate(pieces)
        if piece.strip()
    ]

    logger.debug(f"Chunking: {len(text)} chars → {len(chunks)} chunks")
    return chunks
