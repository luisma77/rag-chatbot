from src.ingestion.chunker import chunk_text


def test_short_text_returns_single_chunk():
    chunks = chunk_text("Texto corto", chunk_size=800, overlap=100)
    assert len(chunks) == 1
    assert chunks[0]["text"] == "Texto corto"


def test_long_text_splits_into_multiple_chunks():
    text = "palabra " * 200  # ~1400 chars
    chunks = chunk_text(text, chunk_size=800, overlap=100)
    assert len(chunks) > 1


def test_chunks_respect_max_size():
    text = "palabra " * 200
    chunks = chunk_text(text, chunk_size=800, overlap=100)
    for chunk in chunks:
        assert len(chunk["text"]) <= 950


def test_chunk_has_required_fields():
    chunks = chunk_text("Texto de prueba", chunk_size=800, overlap=100)
    assert "text" in chunks[0]
    assert "chunk_index" in chunks[0]


def test_empty_text_returns_empty_list():
    assert chunk_text("") == []
    assert chunk_text("   ") == []
