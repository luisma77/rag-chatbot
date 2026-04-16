import os
import tempfile
from unittest.mock import patch, MagicMock


def test_pipeline_routes_txt_to_text_extractor():
    from src.ingestion.pipeline import process_file
    with tempfile.NamedTemporaryFile(
        mode="w", suffix=".txt", encoding="utf-8", delete=False
    ) as f:
        f.write("Contenido de prueba " * 20)
        path = f.name
    try:
        mock_store = MagicMock()
        mock_store.delete_by_source.return_value = None
        mock_store.add_chunks.return_value = None
        with patch("src.ingestion.pipeline.chroma_store", mock_store):
            result = process_file(path, action="created")
        assert result["chunks_indexed"] > 0
        assert result["source"] == os.path.basename(path)
    finally:
        os.unlink(path)


def test_pipeline_delete_action_removes_chunks():
    from src.ingestion.pipeline import process_file
    mock_store = MagicMock()
    mock_store.delete_by_source.return_value = None
    with patch("src.ingestion.pipeline.chroma_store", mock_store):
        result = process_file("/fake/path/doc.pdf", action="deleted")
    mock_store.delete_by_source.assert_called_once_with("doc.pdf")
    assert result["action"] == "deleted"


def test_pipeline_unsupported_format_returns_skipped():
    from src.ingestion.pipeline import process_file
    result = process_file("/fake/path/file.xyz", action="created")
    assert result["status"] == "skipped"
