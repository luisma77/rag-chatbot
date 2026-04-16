from unittest.mock import patch, MagicMock


def test_extract_docx_joins_paragraphs():
    from src.ingestion.extractors.docx_extractor import extract_docx
    mock_doc = MagicMock()
    mock_doc.paragraphs = [
        MagicMock(text="Primer párrafo"),
        MagicMock(text=""),
        MagicMock(text="Segundo párrafo"),
    ]
    with patch("src.ingestion.extractors.docx_extractor.Document", return_value=mock_doc):
        result = extract_docx("fake.docx")
    assert "Primer párrafo" in result
    assert "Segundo párrafo" in result


def test_extract_pptx_joins_slides():
    from src.ingestion.extractors.office_extractor import extract_pptx
    mock_prs = MagicMock()
    slide1 = MagicMock()
    shape1 = MagicMock()
    shape1.has_text_frame = True
    shape1.text_frame.text = "Texto de slide 1"
    slide1.shapes = [shape1]
    mock_prs.slides = [slide1]
    with patch("src.ingestion.extractors.office_extractor.Presentation", return_value=mock_prs):
        result = extract_pptx("fake.pptx")
    assert "Texto de slide 1" in result


def test_extract_xlsx_joins_cells():
    from src.ingestion.extractors.office_extractor import extract_xlsx
    mock_wb = MagicMock()
    mock_ws = MagicMock()
    mock_row = [MagicMock(value="Celda A1"), MagicMock(value="Celda B1")]
    mock_ws.__iter__ = MagicMock(return_value=iter([mock_row]))
    mock_ws.title = "Hoja1"
    mock_wb.worksheets = [mock_ws]
    with patch("src.ingestion.extractors.office_extractor.load_workbook", return_value=mock_wb):
        result = extract_xlsx("fake.xlsx")
    assert "Celda A1" in result
    assert "Celda B1" in result
