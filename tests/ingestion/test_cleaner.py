from src.ingestion.cleaner import clean_text


def test_normalises_excessive_whitespace():
    result = clean_text("Hola    mundo")
    assert "    " not in result


def test_normalises_excessive_newlines():
    result = clean_text("Línea 1\n\n\n\nLínea 2")
    assert "\n\n\n" not in result


def test_strips_leading_trailing():
    result = clean_text("  \n  Texto  \n  ")
    assert result == result.strip()


def test_content_preserved():
    result = clean_text("[Página 1]\n\nContenido")
    assert "Contenido" in result


def test_empty_string_returns_empty():
    assert clean_text("") == ""
    assert clean_text("   \n   ") == ""
