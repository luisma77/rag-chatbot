from unittest.mock import patch, MagicMock


def _make_mock_page(text: str, images: list = None):
    page = MagicMock()
    page.extract_text.return_value = text
    page.images = images or []
    return page


def test_native_text_page_uses_pdfplumber():
    from src.ingestion.extractors.pdf_extractor import extract_pdf
    long_text = "Este es un párrafo largo con más de cien caracteres " * 3
    mock_page = _make_mock_page(long_text)
    mock_pdf = MagicMock()
    mock_pdf.__enter__ = MagicMock(return_value=mock_pdf)
    mock_pdf.__exit__ = MagicMock(return_value=False)
    mock_pdf.pages = [mock_page]
    with patch("src.ingestion.extractors.pdf_extractor.pdfplumber.open", return_value=mock_pdf):
        result = extract_pdf("fake.pdf")
    assert "párrafo largo" in result
    mock_page.extract_text.assert_called_once()


def test_scanned_page_falls_back_to_ocr():
    from src.ingestion.extractors.pdf_extractor import extract_pdf
    mock_page = _make_mock_page("")
    mock_pdf = MagicMock()
    mock_pdf.__enter__ = MagicMock(return_value=mock_pdf)
    mock_pdf.__exit__ = MagicMock(return_value=False)
    mock_pdf.pages = [mock_page]
    with patch("src.ingestion.extractors.pdf_extractor.pdfplumber.open", return_value=mock_pdf), \
         patch(
             "src.ingestion.extractors.pdf_extractor._ocr_full_page",
             return_value="Texto OCR de página escaneada",
         ) as mock_ocr:
        result = extract_pdf("fake.pdf")
    mock_ocr.assert_called_once_with("fake.pdf", 1)
    assert "Texto OCR" in result


def test_mixed_page_fuses_text_and_image_ocr():
    from src.ingestion.extractors.pdf_extractor import extract_pdf
    images = [{"x0": 10, "top": 100, "x1": 200, "bottom": 300}]
    long_text = "Texto nativo de la página con suficientes caracteres " * 3
    mock_page = _make_mock_page(long_text, images=images)
    mock_pdf = MagicMock()
    mock_pdf.__enter__ = MagicMock(return_value=mock_pdf)
    mock_pdf.__exit__ = MagicMock(return_value=False)
    mock_pdf.pages = [mock_page]
    with patch("src.ingestion.extractors.pdf_extractor.pdfplumber.open", return_value=mock_pdf), \
         patch(
             "src.ingestion.extractors.pdf_extractor._ocr_embedded_images",
             return_value=["Texto en imagen embebida"],
         ):
        result = extract_pdf("fake.pdf")
    assert "Texto nativo" in result
    assert "Texto en imagen embebida" in result
