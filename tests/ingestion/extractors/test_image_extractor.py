from unittest.mock import patch, MagicMock


def test_extract_image_calls_tesseract():
    from src.ingestion.extractors.image_extractor import extract_image
    with patch("src.ingestion.extractors.image_extractor.pytesseract") as mock_tess, \
         patch("src.ingestion.extractors.image_extractor.Image") as mock_pil:
        mock_pil.open.return_value = MagicMock()
        mock_tess.image_to_string.return_value = "Texto extraído por OCR"
        result = extract_image("fake_image.png")
    assert result == "Texto extraído por OCR"
    mock_tess.image_to_string.assert_called_once()
