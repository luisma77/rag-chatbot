from unittest.mock import patch, MagicMock


def _make_mock_collection():
    col = MagicMock()
    col.count.return_value = 0
    return col


def test_add_chunks_calls_collection_upsert():
    from src.vectordb.chroma_store import ChromaStore
    mock_col = _make_mock_collection()

    with patch("src.vectordb.chroma_store.chromadb.PersistentClient") as mock_client_cls, \
         patch("src.vectordb.chroma_store.encode") as mock_encode:
        mock_client = MagicMock()
        mock_client.get_or_create_collection.return_value = mock_col
        mock_client_cls.return_value = mock_client
        mock_encode.return_value = [[0.1] * 384, [0.2] * 384]

        store = ChromaStore()
        chunks = [
            {"text": "Chunk 1", "chunk_index": 0, "source_file": "doc.pdf"},
            {"text": "Chunk 2", "chunk_index": 1, "source_file": "doc.pdf"},
        ]
        store.add_chunks(chunks)

    mock_col.upsert.assert_called_once()


def test_delete_by_source_calls_collection_delete():
    from src.vectordb.chroma_store import ChromaStore
    mock_col = _make_mock_collection()
    mock_col.get.return_value = {"ids": ["id1", "id2"]}

    with patch("src.vectordb.chroma_store.chromadb.PersistentClient") as mock_client_cls:
        mock_client = MagicMock()
        mock_client.get_or_create_collection.return_value = mock_col
        mock_client_cls.return_value = mock_client

        store = ChromaStore()
        store.delete_by_source("doc.pdf")

    mock_col.delete.assert_called_once_with(ids=["id1", "id2"])


def test_query_returns_list_of_results():
    from src.vectordb.chroma_store import ChromaStore
    mock_col = _make_mock_collection()
    mock_col.count.return_value = 5
    mock_col.query.return_value = {
        "documents": [["Texto relevante"]],
        "metadatas": [[{"source_file": "doc.pdf", "chunk_index": 0}]],
        "distances": [[0.2]],
        "ids": [["id1"]],
    }

    with patch("src.vectordb.chroma_store.chromadb.PersistentClient") as mock_client_cls, \
         patch("src.vectordb.chroma_store.encode_one") as mock_enc:
        mock_client = MagicMock()
        mock_client.get_or_create_collection.return_value = mock_col
        mock_client_cls.return_value = mock_client
        mock_enc.return_value = [0.1] * 384

        store = ChromaStore()
        results = store.query("pregunta de prueba", top_k=5)

    assert len(results) == 1
    assert results[0]["text"] == "Texto relevante"
    assert "score" in results[0]
    assert "source_file" in results[0]
