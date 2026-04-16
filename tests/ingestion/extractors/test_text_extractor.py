import os
import tempfile


def test_extract_utf8_txt():
    from src.ingestion.extractors.text_extractor import extract_text
    with tempfile.NamedTemporaryFile(
        mode="w", suffix=".txt", encoding="utf-8", delete=False
    ) as f:
        f.write("Hola mundo desde texto plano")
        path = f.name
    try:
        result = extract_text(path)
        assert "Hola mundo desde texto plano" in result
    finally:
        os.unlink(path)


def test_extract_html_strips_tags():
    from src.ingestion.extractors.text_extractor import extract_text
    with tempfile.NamedTemporaryFile(
        mode="w", suffix=".html", encoding="utf-8", delete=False
    ) as f:
        f.write("<html><body><h1>Título</h1><p>Contenido importante</p></body></html>")
        path = f.name
    try:
        result = extract_text(path)
        assert "Título" in result
        assert "Contenido importante" in result
        assert "<h1>" not in result
    finally:
        os.unlink(path)


def test_extract_markdown():
    from src.ingestion.extractors.text_extractor import extract_text
    with tempfile.NamedTemporaryFile(
        mode="w", suffix=".md", encoding="utf-8", delete=False
    ) as f:
        f.write("# Cabecera\n\nPárrafo con **negrita**")
        path = f.name
    try:
        result = extract_text(path)
        assert "Cabecera" in result
        assert "Párrafo" in result
    finally:
        os.unlink(path)


def test_extract_latin1_txt():
    from src.ingestion.extractors.text_extractor import extract_text
    with tempfile.NamedTemporaryFile(mode="wb", suffix=".txt", delete=False) as f:
        f.write("Texto con acentos: café, niño".encode("latin-1"))
        path = f.name
    try:
        result = extract_text(path)
        assert "caf" in result
    finally:
        os.unlink(path)
