# RAG Chatbot Empresarial — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a complete RAG chatbot backend for enterprise document Q&A, CPU-only on Windows 11, with strict anti-hallucination and incremental document indexing.

**Architecture:** FastAPI backend orchestrates document ingestion (multi-format extraction with 3-tier PDF strategy, OCR, chunking) → sentence-transformers multilingual embeddings → ChromaDB persistent vector store → RAG query pipeline with similarity threshold filter → Ollama qwen2.5:3b LLM with system-prompt-level anti-hallucination → ASP classic frontend integration via REST.

**Tech Stack:** Python 3.11, FastAPI, uvicorn, ChromaDB, sentence-transformers (paraphrase-multilingual-MiniLM-L12-v2), Ollama (qwen2.5:3b Q4_K_M), pdfplumber, pdf2image, pytesseract, Pillow, python-docx, python-pptx, openpyxl, BeautifulSoup4, chardet, httpx, pydantic-settings, pytest, pytest-asyncio, PowerShell FileSystemWatcher

---

## File Map

| File | Responsibility |
|---|---|
| `requirements.txt` | Python dependencies |
| `.env.example` | All env vars documented |
| `conftest.py` | pytest sys.path fix |
| `src/__init__.py` | Package marker |
| `src/config.py` | Pydantic Settings from .env |
| `src/logger.py` | Centralised logging (console + file) |
| `src/ingestion/extractors/text_extractor.py` | TXT, MD, HTML extraction |
| `src/ingestion/extractors/image_extractor.py` | PNG/JPG/TIFF via pytesseract |
| `src/ingestion/extractors/docx_extractor.py` | .docx via python-docx |
| `src/ingestion/extractors/office_extractor.py` | .pptx, .xlsx extraction |
| `src/ingestion/extractors/pdf_extractor.py` | PDF: native+OCR+hybrid fusion |
| `src/ingestion/cleaner.py` | Text normalisation |
| `src/ingestion/chunker.py` | RecursiveCharacterTextSplitter wrapper |
| `src/ingestion/pipeline.py` | Orchestrates extract→clean→chunk |
| `src/embeddings/encoder.py` | sentence-transformers wrapper |
| `src/vectordb/chroma_store.py` | ChromaDB CRUD + similarity search |
| `src/llm/ollama_client.py` | Async HTTP client for Ollama |
| `src/llm/prompt_builder.py` | RAG prompt construction |
| `src/cache/response_cache.py` | In-memory TTL cache |
| `src/api/ingest.py` | POST /ingest, POST /ingest/file |
| `src/api/chat.py` | POST /chat |
| `src/api/admin.py` | GET /health, GET /stats, POST /reindex |
| `src/main.py` | FastAPI app assembly + lifespan |
| `scripts/install.ps1` | Installs Tesseract, Ollama, Python deps |
| `scripts/watch-and-serve.ps1` | Starts services + FileSystemWatcher |
| `scripts/reindex-all.ps1` | Wipes ChromaDB and reindexes from scratch |
| `asp/chat.asp` | Chat interface + HTTP call to backend |
| `asp/ingest.asp` | Trigger ingest from ASP admin page |

---

## Task 1: Project Scaffold

**Files:**
- Create: `requirements.txt`
- Create: `.env.example`
- Create: `conftest.py`
- Create: `src/__init__.py`
- Create: `tests/__init__.py`

- [ ] **Step 1: Create requirements.txt**

```
fastapi==0.115.0
uvicorn[standard]==0.34.0
pydantic==2.9.0
pydantic-settings==2.6.0
python-dotenv==1.0.1
httpx==0.28.0
chromadb==0.5.20
sentence-transformers==3.3.1
pdfplumber==0.11.4
pdf2image==1.17.0
pytesseract==0.3.13
Pillow==11.0.0
python-docx==1.1.2
python-pptx==1.0.2
openpyxl==3.1.5
beautifulsoup4==4.12.3
chardet==5.2.0
langchain-text-splitters==0.3.2
pytest==8.3.0
pytest-asyncio==0.24.0
```

- [ ] **Step 2: Create .env.example**

```ini
# Ollama
OLLAMA_BASE_URL=http://localhost:11434
OLLAMA_MODEL=qwen2.5:3b
OLLAMA_TIMEOUT=120

# Embeddings
EMBEDDING_MODEL=paraphrase-multilingual-MiniLM-L12-v2

# ChromaDB
CHROMA_PERSIST_DIR=./chroma_db
CHROMA_COLLECTION=documents

# Documents
DOCUMENTS_DIR=./data/documents

# RAG tuning
TOP_K=5
SIMILARITY_THRESHOLD=0.65
CACHE_THRESHOLD=0.75
CACHE_TTL_SECONDS=7200

# API
API_HOST=0.0.0.0
API_PORT=8000
MAX_CONCURRENT_LLM=3

# Chunking
CHUNK_SIZE=800
CHUNK_OVERLAP=100

# Tesseract (Windows path)
TESSERACT_CMD=C:\Program Files\Tesseract-OCR\tesseract.exe
TESSERACT_LANG=spa+eng

# Logging
LOG_LEVEL=INFO
LOG_DIR=./logs
```

- [ ] **Step 3: Create conftest.py (project root)**

```python
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
```

- [ ] **Step 4: Create package markers**

Create `src/__init__.py` — empty file.
Create `src/ingestion/__init__.py` — empty file.
Create `src/ingestion/extractors/__init__.py` — empty file.
Create `src/embeddings/__init__.py` — empty file.
Create `src/vectordb/__init__.py` — empty file.
Create `src/llm/__init__.py` — empty file.
Create `src/api/__init__.py` — empty file.
Create `src/cache/__init__.py` — empty file.
Create `tests/__init__.py` — empty file.
Create `tests/ingestion/__init__.py` — empty file.
Create `tests/ingestion/extractors/__init__.py` — empty file.
Create `tests/embeddings/__init__.py` — empty file.
Create `tests/vectordb/__init__.py` — empty file.
Create `tests/llm/__init__.py` — empty file.
Create `tests/cache/__init__.py` — empty file.
Create `tests/api/__init__.py` — empty file.

- [ ] **Step 5: Install dependencies**

```bash
pip install -r requirements.txt
```

Expected: All packages install without error. ChromaDB may take 1-2 minutes.

- [ ] **Step 6: Commit**

```bash
git init
git add requirements.txt .env.example conftest.py
git add src/__init__.py tests/__init__.py
git commit -m "feat: project scaffold — dependencies and structure"
```

---

## Task 2: Config + Logger

**Files:**
- Create: `src/config.py`
- Create: `src/logger.py`
- Create: `tests/test_config.py`

- [ ] **Step 1: Write failing test for config**

Create `tests/test_config.py`:

```python
def test_default_values():
    from src.config import settings
    assert settings.ollama_model == "qwen2.5:3b"
    assert settings.top_k == 5
    assert settings.similarity_threshold == 0.65
    assert settings.max_concurrent_llm == 3
    assert settings.chunk_size == 800
    assert settings.chunk_overlap == 100

def test_api_port_default():
    from src.config import settings
    assert settings.api_port == 8000
```

- [ ] **Step 2: Run test to verify it fails**

```bash
pytest tests/test_config.py -v
```
Expected: `ModuleNotFoundError: No module named 'src.config'`

- [ ] **Step 3: Create src/config.py**

```python
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
    )

    # Ollama
    ollama_base_url: str = "http://localhost:11434"
    ollama_model: str = "qwen2.5:3b"
    ollama_timeout: int = 120

    # Embeddings
    embedding_model: str = "paraphrase-multilingual-MiniLM-L12-v2"

    # ChromaDB
    chroma_persist_dir: str = "./chroma_db"
    chroma_collection: str = "documents"

    # Documents
    documents_dir: str = "./data/documents"

    # RAG
    top_k: int = 5
    similarity_threshold: float = 0.65
    cache_threshold: float = 0.75
    cache_ttl_seconds: int = 7200

    # API
    api_host: str = "0.0.0.0"
    api_port: int = 8000
    max_concurrent_llm: int = 3

    # Chunking
    chunk_size: int = 800
    chunk_overlap: int = 100

    # Tesseract
    tesseract_cmd: str = r"C:\Program Files\Tesseract-OCR\tesseract.exe"
    tesseract_lang: str = "spa+eng"

    # Logging
    log_level: str = "INFO"
    log_dir: str = "./logs"


settings = Settings()
```

- [ ] **Step 4: Create src/logger.py**

```python
import logging
import sys
from pathlib import Path

from src.config import settings


def get_logger(name: str) -> logging.Logger:
    logger = logging.getLogger(name)
    if logger.handlers:
        return logger

    level = getattr(logging, settings.log_level.upper(), logging.INFO)
    logger.setLevel(level)

    fmt = logging.Formatter(
        "%(asctime)s [%(levelname)-8s] %(name)s: %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )

    console = logging.StreamHandler(sys.stdout)
    console.setFormatter(fmt)
    logger.addHandler(console)

    log_dir = Path(settings.log_dir)
    log_dir.mkdir(parents=True, exist_ok=True)
    file_handler = logging.FileHandler(log_dir / "chatbot.log", encoding="utf-8")
    file_handler.setFormatter(fmt)
    logger.addHandler(file_handler)

    return logger
```

- [ ] **Step 5: Run tests to verify they pass**

```bash
pytest tests/test_config.py -v
```
Expected: 2 passed.

- [ ] **Step 6: Commit**

```bash
git add src/config.py src/logger.py tests/test_config.py
git commit -m "feat: config (pydantic-settings) and centralised logger"
```

---

## Task 3: Text + Image Extractors

**Files:**
- Create: `src/ingestion/extractors/text_extractor.py`
- Create: `src/ingestion/extractors/image_extractor.py`
- Create: `tests/ingestion/extractors/test_text_extractor.py`
- Create: `tests/ingestion/extractors/test_image_extractor.py`

- [ ] **Step 1: Write failing tests**

Create `tests/ingestion/extractors/test_text_extractor.py`:

```python
import os
import tempfile
import pytest


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
    with tempfile.NamedTemporaryFile(
        mode="wb", suffix=".txt", delete=False
    ) as f:
        f.write("Texto con acentos: café, niño".encode("latin-1"))
        path = f.name
    try:
        result = extract_text(path)
        assert "caf" in result
    finally:
        os.unlink(path)
```

Create `tests/ingestion/extractors/test_image_extractor.py`:

```python
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
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
pytest tests/ingestion/extractors/test_text_extractor.py tests/ingestion/extractors/test_image_extractor.py -v
```
Expected: All fail with `ModuleNotFoundError`.

- [ ] **Step 3: Create src/ingestion/extractors/text_extractor.py**

```python
from pathlib import Path

import chardet
from bs4 import BeautifulSoup

from src.logger import get_logger

logger = get_logger(__name__)


def extract_text(file_path: str) -> str:
    path = Path(file_path)
    suffix = path.suffix.lower()

    raw = path.read_bytes()
    encoding = _detect_encoding(raw)
    text = raw.decode(encoding, errors="replace")

    if suffix == ".html":
        soup = BeautifulSoup(text, "html.parser")
        return soup.get_text(separator="\n")

    return text


def _detect_encoding(raw: bytes) -> str:
    result = chardet.detect(raw)
    return result.get("encoding") or "utf-8"
```

- [ ] **Step 4: Create src/ingestion/extractors/image_extractor.py**

```python
import pytesseract
from PIL import Image

from src.config import settings
from src.logger import get_logger

logger = get_logger(__name__)

pytesseract.pytesseract.tesseract_cmd = settings.tesseract_cmd


def extract_image(file_path: str) -> str:
    img = Image.open(file_path)
    text = pytesseract.image_to_string(img, lang=settings.tesseract_lang)
    logger.debug(f"OCR imagen '{file_path}': {len(text)} chars extraídos")
    return text
```

- [ ] **Step 5: Run tests to verify they pass**

```bash
pytest tests/ingestion/extractors/test_text_extractor.py tests/ingestion/extractors/test_image_extractor.py -v
```
Expected: All pass.

- [ ] **Step 6: Commit**

```bash
git add src/ingestion/extractors/text_extractor.py src/ingestion/extractors/image_extractor.py
git add tests/ingestion/extractors/test_text_extractor.py tests/ingestion/extractors/test_image_extractor.py
git commit -m "feat: text (txt/html/md) and image (OCR) extractors"
```

---

## Task 4: Office Extractors (DOCX, PPTX, XLSX)

**Files:**
- Create: `src/ingestion/extractors/docx_extractor.py`
- Create: `src/ingestion/extractors/office_extractor.py`
- Create: `tests/ingestion/extractors/test_office_extractors.py`

- [ ] **Step 1: Write failing tests**

Create `tests/ingestion/extractors/test_office_extractors.py`:

```python
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
    mock_wb.worksheets = [mock_ws]
    with patch("src.ingestion.extractors.office_extractor.load_workbook", return_value=mock_wb):
        result = extract_xlsx("fake.xlsx")
    assert "Celda A1" in result
    assert "Celda B1" in result
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
pytest tests/ingestion/extractors/test_office_extractors.py -v
```
Expected: All fail with `ModuleNotFoundError`.

- [ ] **Step 3: Create src/ingestion/extractors/docx_extractor.py**

```python
from docx import Document

from src.logger import get_logger

logger = get_logger(__name__)


def extract_docx(file_path: str) -> str:
    doc = Document(file_path)
    paragraphs = [p.text for p in doc.paragraphs if p.text.strip()]
    text = "\n\n".join(paragraphs)
    logger.debug(f"DOCX '{file_path}': {len(paragraphs)} párrafos, {len(text)} chars")
    return text
```

- [ ] **Step 4: Create src/ingestion/extractors/office_extractor.py**

```python
from pptx import Presentation
from openpyxl import load_workbook

from src.logger import get_logger

logger = get_logger(__name__)


def extract_pptx(file_path: str) -> str:
    prs = Presentation(file_path)
    slides_text = []
    for slide_num, slide in enumerate(prs.slides, 1):
        parts = []
        for shape in slide.shapes:
            if shape.has_text_frame:
                parts.append(shape.text_frame.text)
        if parts:
            slides_text.append(f"[Slide {slide_num}]\n" + "\n".join(parts))
    text = "\n\n".join(slides_text)
    logger.debug(f"PPTX '{file_path}': {len(prs.slides)} slides, {len(text)} chars")
    return text


def extract_xlsx(file_path: str) -> str:
    wb = load_workbook(file_path, read_only=True, data_only=True)
    all_text = []
    for sheet in wb.worksheets:
        rows_text = []
        for row in sheet:
            cells = [str(cell.value) for cell in row if cell.value is not None]
            if cells:
                rows_text.append(" | ".join(cells))
        if rows_text:
            all_text.append(f"[Hoja: {sheet.title}]\n" + "\n".join(rows_text))
    text = "\n\n".join(all_text)
    logger.debug(f"XLSX '{file_path}': {len(wb.worksheets)} hojas, {len(text)} chars")
    return text
```

- [ ] **Step 5: Run tests to verify they pass**

```bash
pytest tests/ingestion/extractors/test_office_extractors.py -v
```
Expected: All pass.

- [ ] **Step 6: Commit**

```bash
git add src/ingestion/extractors/docx_extractor.py src/ingestion/extractors/office_extractor.py
git add tests/ingestion/extractors/test_office_extractors.py
git commit -m "feat: docx, pptx, xlsx extractors"
```

---

## Task 5: PDF Extractor (3-tier: native / OCR / hybrid)

**Files:**
- Create: `src/ingestion/extractors/pdf_extractor.py`
- Create: `tests/ingestion/extractors/test_pdf_extractor.py`

- [ ] **Step 1: Write failing tests**

Create `tests/ingestion/extractors/test_pdf_extractor.py`:

```python
from unittest.mock import patch, MagicMock


def _make_mock_page(text: str, images: list = None):
    page = MagicMock()
    page.extract_text.return_value = text
    page.images = images or []
    return page


def test_native_text_page_uses_pdfplumber():
    from src.ingestion.extractors.pdf_extractor import extract_pdf
    mock_page = _make_mock_page("Este es un párrafo largo con más de cien caracteres " * 3)
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
    mock_page = _make_mock_page("")  # no native text
    mock_pdf = MagicMock()
    mock_pdf.__enter__ = MagicMock(return_value=mock_pdf)
    mock_pdf.__exit__ = MagicMock(return_value=False)
    mock_pdf.pages = [mock_page]
    with patch("src.ingestion.extractors.pdf_extractor.pdfplumber.open", return_value=mock_pdf), \
         patch("src.ingestion.extractors.pdf_extractor._ocr_full_page", return_value="Texto OCR de página escaneada") as mock_ocr:
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
         patch("src.ingestion.extractors.pdf_extractor._ocr_embedded_images", return_value=["Texto en imagen embebida"]):
        result = extract_pdf("fake.pdf")
    assert "Texto nativo" in result
    assert "Texto en imagen embebida" in result
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
pytest tests/ingestion/extractors/test_pdf_extractor.py -v
```
Expected: All fail with `ModuleNotFoundError`.

- [ ] **Step 3: Create src/ingestion/extractors/pdf_extractor.py**

```python
from pathlib import Path

import pdfplumber
import pytesseract
from pdf2image import convert_from_path
from PIL import Image

from src.config import settings
from src.logger import get_logger

logger = get_logger(__name__)

pytesseract.pytesseract.tesseract_cmd = settings.tesseract_cmd

# Minimum characters to consider a page as having native text
_MIN_TEXT_CHARS = 100
# DPI for rendering pages to image for OCR
_OCR_DPI = 200


def extract_pdf(file_path: str) -> str:
    """Extract text from PDF using 3-tier strategy per page:
    1. Native text page  → pdfplumber
    2. Scanned page      → full-page OCR
    3. Mixed page        → pdfplumber + OCR on embedded images, fused
    """
    pages_text = []

    with pdfplumber.open(file_path) as pdf:
        for page_num, page in enumerate(pdf.pages, 1):
            native_text = page.extract_text() or ""
            native_clean = native_text.strip()

            if len(native_clean) >= _MIN_TEXT_CHARS:
                # Tier 1 or Tier 3: has native text
                page_text = native_clean

                if page.images:
                    # Tier 3: mixed page — also OCR embedded images
                    image_texts = _ocr_embedded_images(file_path, page_num, page.images)
                    for img_text in image_texts:
                        if img_text.strip():
                            page_text += f"\n[Contenido imagen]: {img_text.strip()}"
            else:
                # Tier 2: scanned page — full OCR
                try:
                    page_text = _ocr_full_page(file_path, page_num)
                    if not page_text.strip():
                        logger.debug(f"Página {page_num}: vacía, omitida")
                        continue
                    logger.debug(f"Página {page_num}: OCR completo ({len(page_text)} chars)")
                except Exception as exc:
                    logger.error(f"Error OCR página {page_num} de '{file_path}': {exc}")
                    continue

            if page_text.strip():
                pages_text.append(f"[Página {page_num}]\n{page_text.strip()}")

    result = "\n\n".join(pages_text)
    logger.debug(f"PDF '{file_path}': {len(pdf.pages)} páginas → {len(result)} chars")
    return result


def _ocr_full_page(pdf_path: str, page_num: int) -> str:
    """Render a single PDF page to image and run OCR on it."""
    images = convert_from_path(
        pdf_path,
        first_page=page_num,
        last_page=page_num,
        dpi=_OCR_DPI,
    )
    if not images:
        return ""
    return pytesseract.image_to_string(images[0], lang=settings.tesseract_lang)


def _ocr_embedded_images(pdf_path: str, page_num: int, images: list) -> list[str]:
    """OCR only the regions of a page that contain embedded images.

    Uses pdf2image to render the full page, then crops each image region.
    pdfplumber coordinates: origin bottom-left, points (72pt = 1 inch).
    PIL crop: origin top-left, pixels.
    """
    rendered = convert_from_path(
        pdf_path,
        first_page=page_num,
        last_page=page_num,
        dpi=150,
    )
    if not rendered:
        return []

    page_img = rendered[0]
    page_w_px, page_h_px = page_img.size
    scale = 150 / 72  # points → pixels at 150 dpi

    ocr_texts = []
    for img_info in images:
        try:
            x0 = int(img_info["x0"] * scale)
            # pdfplumber 'top' = distance from page top (already flipped)
            y0 = int(img_info["top"] * scale)
            x1 = int(img_info["x1"] * scale)
            y1 = int(img_info["bottom"] * scale)

            # Clamp to image bounds
            x0, y0 = max(0, x0), max(0, y0)
            x1, y1 = min(page_w_px, x1), min(page_h_px, y1)

            if x1 - x0 < 10 or y1 - y0 < 10:
                continue

            cropped = page_img.crop((x0, y0, x1, y1))
            text = pytesseract.image_to_string(cropped, lang=settings.tesseract_lang)
            if text.strip():
                ocr_texts.append(text.strip())
        except Exception as exc:
            logger.warning(f"OCR imagen embebida falló: {exc}")

    return ocr_texts
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
pytest tests/ingestion/extractors/test_pdf_extractor.py -v
```
Expected: All pass.

- [ ] **Step 5: Commit**

```bash
git add src/ingestion/extractors/pdf_extractor.py tests/ingestion/extractors/test_pdf_extractor.py
git commit -m "feat: PDF extractor with 3-tier strategy (native/OCR/hybrid fusion)"
```

---

## Task 6: Text Cleaner + Chunker

**Files:**
- Create: `src/ingestion/cleaner.py`
- Create: `src/ingestion/chunker.py`
- Create: `tests/ingestion/test_cleaner.py`
- Create: `tests/ingestion/test_chunker.py`

- [ ] **Step 1: Write failing tests**

Create `tests/ingestion/test_cleaner.py`:

```python
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


def test_removes_page_markers():
    result = clean_text("[Página 1]\n\n[Página 2]\n\nContenido")
    # Page markers should be preserved (they carry metadata value)
    # but ensure content is clean
    assert "Contenido" in result


def test_empty_string_returns_empty():
    assert clean_text("") == ""
    assert clean_text("   \n   ") == ""
```

Create `tests/ingestion/test_chunker.py`:

```python
from src.ingestion.chunker import chunk_text


def test_short_text_returns_single_chunk():
    text = "Texto corto"
    chunks = chunk_text(text, chunk_size=800, overlap=100)
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
        assert len(chunk["text"]) <= 950  # size + some tolerance for splitter


def test_chunk_has_required_fields():
    chunks = chunk_text("Texto de prueba", chunk_size=800, overlap=100)
    assert "text" in chunks[0]
    assert "chunk_index" in chunks[0]


def test_empty_text_returns_empty_list():
    assert chunk_text("") == []
    assert chunk_text("   ") == []
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
pytest tests/ingestion/test_cleaner.py tests/ingestion/test_chunker.py -v
```
Expected: All fail with `ModuleNotFoundError`.

- [ ] **Step 3: Create src/ingestion/cleaner.py**

```python
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
```

- [ ] **Step 4: Create src/ingestion/chunker.py**

```python
from langchain_text_splitters import RecursiveCharacterTextSplitter

from src.logger import get_logger

logger = get_logger(__name__)


def chunk_text(
    text: str,
    chunk_size: int = 800,
    overlap: int = 100,
) -> list[dict]:
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
```

- [ ] **Step 5: Run tests to verify they pass**

```bash
pytest tests/ingestion/test_cleaner.py tests/ingestion/test_chunker.py -v
```
Expected: All pass.

- [ ] **Step 6: Commit**

```bash
git add src/ingestion/cleaner.py src/ingestion/chunker.py
git add tests/ingestion/test_cleaner.py tests/ingestion/test_chunker.py
git commit -m "feat: text cleaner and recursive chunker"
```

---

## Task 7: Ingestion Pipeline

**Files:**
- Create: `src/ingestion/pipeline.py`
- Create: `tests/ingestion/test_pipeline.py`

- [ ] **Step 1: Write failing tests**

Create `tests/ingestion/test_pipeline.py`:

```python
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
        with patch("src.ingestion.pipeline.chroma_store") as mock_store:
            mock_store.delete_by_source.return_value = None
            mock_store.add_chunks.return_value = None
            result = process_file(path, action="created")
        assert result["chunks_indexed"] > 0
        assert result["source"] == os.path.basename(path)
    finally:
        os.unlink(path)


def test_pipeline_delete_action_removes_chunks():
    from src.ingestion.pipeline import process_file
    with patch("src.ingestion.pipeline.chroma_store") as mock_store:
        mock_store.delete_by_source.return_value = None
        result = process_file("/fake/path/doc.pdf", action="deleted")
    mock_store.delete_by_source.assert_called_once_with("doc.pdf")
    assert result["action"] == "deleted"


def test_pipeline_unsupported_format_returns_skipped():
    from src.ingestion.pipeline import process_file
    result = process_file("/fake/path/file.xyz", action="created")
    assert result["status"] == "skipped"
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
pytest tests/ingestion/test_pipeline.py -v
```
Expected: All fail.

- [ ] **Step 3: Create src/ingestion/pipeline.py**

```python
import os
from pathlib import Path

from src.config import settings
from src.ingestion.cleaner import clean_text
from src.ingestion.chunker import chunk_text
from src.ingestion.extractors.text_extractor import extract_text
from src.ingestion.extractors.image_extractor import extract_image
from src.ingestion.extractors.docx_extractor import extract_docx
from src.ingestion.extractors.office_extractor import extract_pptx, extract_xlsx
from src.ingestion.extractors.pdf_extractor import extract_pdf
from src.logger import get_logger
from src.vectordb import chroma_store

logger = get_logger(__name__)

# Supported extensions → extractor function
EXTRACTORS = {
    ".pdf": extract_pdf,
    ".docx": extract_docx,
    ".pptx": extract_pptx,
    ".xlsx": extract_xlsx,
    ".txt": extract_text,
    ".md": extract_text,
    ".html": extract_text,
    ".htm": extract_text,
    ".jpg": extract_image,
    ".jpeg": extract_image,
    ".png": extract_image,
    ".tiff": extract_image,
    ".tif": extract_image,
    ".bmp": extract_image,
    ".webp": extract_image,
}


def process_file(file_path: str, action: str) -> dict:
    """Process a single file: extract, clean, chunk, and upsert into ChromaDB.

    action: 'created' | 'changed' | 'deleted' | 'renamed'
    Returns a result dict with status details.
    """
    path = Path(file_path)
    filename = path.name
    suffix = path.suffix.lower()

    if action == "deleted":
        chroma_store.delete_by_source(filename)
        logger.info(f"Eliminados chunks de '{filename}' (archivo borrado)")
        return {"action": "deleted", "source": filename, "status": "ok"}

    if suffix not in EXTRACTORS:
        logger.warning(f"Formato no soportado: '{suffix}' — archivo '{filename}' omitido")
        return {"action": action, "source": filename, "status": "skipped", "reason": f"unsupported format: {suffix}"}

    try:
        extractor = EXTRACTORS[suffix]
        raw_text = extractor(file_path)
    except Exception as exc:
        logger.error(f"Error extrayendo '{filename}': {exc}")
        return {"action": action, "source": filename, "status": "error", "error": str(exc)}

    if not raw_text.strip():
        logger.warning(f"'{filename}': sin texto extraíble, omitido")
        return {"action": action, "source": filename, "status": "skipped", "reason": "no text extracted"}

    cleaned = clean_text(raw_text)
    chunks = chunk_text(cleaned, settings.chunk_size, settings.chunk_overlap)

    if not chunks:
        return {"action": action, "source": filename, "status": "skipped", "reason": "no chunks after cleaning"}

    # Delete previous version if updating
    chroma_store.delete_by_source(filename)

    # Enrich chunks with file metadata
    for chunk in chunks:
        chunk["source_file"] = filename

    chroma_store.add_chunks(chunks)

    logger.info(f"'{filename}': {len(chunks)} chunks indexados")
    return {
        "action": action,
        "source": filename,
        "status": "ok",
        "chunks_indexed": len(chunks),
    }


def process_all(documents_dir: str = None) -> dict:
    """Process all supported files in the documents directory."""
    doc_dir = Path(documents_dir or settings.documents_dir)
    if not doc_dir.exists():
        return {"status": "error", "error": f"Directory not found: {doc_dir}"}

    results = []
    for file_path in doc_dir.rglob("*"):
        if file_path.is_file() and file_path.suffix.lower() in EXTRACTORS:
            result = process_file(str(file_path), action="created")
            results.append(result)

    ok = sum(1 for r in results if r["status"] == "ok")
    logger.info(f"Ingesta completa: {ok}/{len(results)} archivos indexados")
    return {"total": len(results), "ok": ok, "results": results}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
pytest tests/ingestion/test_pipeline.py -v
```
Expected: All pass.

- [ ] **Step 5: Commit**

```bash
git add src/ingestion/pipeline.py tests/ingestion/test_pipeline.py
git commit -m "feat: ingestion pipeline — extract→clean→chunk→upsert orchestration"
```

---

## Task 8: Embedding Encoder

**Files:**
- Create: `src/embeddings/encoder.py`
- Create: `tests/embeddings/test_encoder.py`

- [ ] **Step 1: Write failing tests**

Create `tests/embeddings/test_encoder.py`:

```python
from unittest.mock import patch, MagicMock
import numpy as np


def test_encode_returns_list_of_floats():
    from src.embeddings.encoder import encode
    mock_model = MagicMock()
    mock_model.encode.return_value = np.array([[0.1, 0.2, 0.3] * 128])
    with patch("src.embeddings.encoder._get_model", return_value=mock_model):
        result = encode(["Texto de prueba"])
    assert isinstance(result, list)
    assert isinstance(result[0], list)
    assert isinstance(result[0][0], float)


def test_encode_single_text():
    from src.embeddings.encoder import encode_one
    mock_model = MagicMock()
    mock_model.encode.return_value = np.array([[0.1] * 384])
    with patch("src.embeddings.encoder._get_model", return_value=mock_model):
        result = encode_one("Texto")
    assert isinstance(result, list)
    assert len(result) == 384
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
pytest tests/embeddings/test_encoder.py -v
```
Expected: Fail.

- [ ] **Step 3: Create src/embeddings/encoder.py**

```python
from functools import lru_cache

from sentence_transformers import SentenceTransformer

from src.config import settings
from src.logger import get_logger

logger = get_logger(__name__)


@lru_cache(maxsize=1)
def _get_model() -> SentenceTransformer:
    logger.info(f"Cargando modelo de embeddings: {settings.embedding_model}")
    model = SentenceTransformer(settings.embedding_model)
    logger.info("Modelo de embeddings cargado")
    return model


def encode(texts: list[str]) -> list[list[float]]:
    """Encode a list of texts into embedding vectors.

    Returns list of 384-dim float lists.
    """
    model = _get_model()
    embeddings = model.encode(texts, show_progress_bar=False, batch_size=32)
    return embeddings.tolist()


def encode_one(text: str) -> list[float]:
    """Encode a single text. Convenience wrapper around encode()."""
    return encode([text])[0]
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
pytest tests/embeddings/test_encoder.py -v
```
Expected: All pass.

- [ ] **Step 5: Commit**

```bash
git add src/embeddings/encoder.py tests/embeddings/test_encoder.py
git commit -m "feat: sentence-transformers embedding encoder (multilingual MiniLM)"
```

---

## Task 9: ChromaDB Store

**Files:**
- Create: `src/vectordb/chroma_store.py`
- Create: `tests/vectordb/test_chroma_store.py`

- [ ] **Step 1: Write failing tests**

Create `tests/vectordb/test_chroma_store.py`:

```python
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
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
pytest tests/vectordb/test_chroma_store.py -v
```
Expected: Fail.

- [ ] **Step 3: Create src/vectordb/chroma_store.py**

```python
import uuid
from pathlib import Path

import chromadb

from src.config import settings
from src.embeddings.encoder import encode, encode_one
from src.logger import get_logger

logger = get_logger(__name__)


class ChromaStore:
    def __init__(self):
        Path(settings.chroma_persist_dir).mkdir(parents=True, exist_ok=True)
        self._client = chromadb.PersistentClient(path=settings.chroma_persist_dir)
        self._collection = self._client.get_or_create_collection(
            name=settings.chroma_collection,
            metadata={"hnsw:space": "cosine"},
        )
        logger.info(
            f"ChromaDB listo: colección '{settings.chroma_collection}' "
            f"({self._collection.count()} vectores)"
        )

    def add_chunks(self, chunks: list[dict]) -> None:
        """Embed and upsert chunks into the collection.

        Each chunk must have: text, chunk_index, source_file.
        """
        if not chunks:
            return

        texts = [c["text"] for c in chunks]
        embeddings = encode(texts)

        ids = [str(uuid.uuid4()) for _ in chunks]
        metadatas = [
            {
                "source_file": c.get("source_file", "unknown"),
                "chunk_index": c.get("chunk_index", 0),
            }
            for c in chunks
        ]

        self._collection.upsert(
            ids=ids,
            embeddings=embeddings,
            documents=texts,
            metadatas=metadatas,
        )
        logger.debug(f"Upsert: {len(chunks)} chunks añadidos/actualizados")

    def delete_by_source(self, source_file: str) -> int:
        """Delete all chunks belonging to a specific source file."""
        result = self._collection.get(
            where={"source_file": source_file},
        )
        ids = result.get("ids", [])
        if ids:
            self._collection.delete(ids=ids)
            logger.debug(f"Eliminados {len(ids)} chunks de '{source_file}'")
        return len(ids)

    def query(self, question: str, top_k: int = None) -> list[dict]:
        """Semantic search. Returns list of dicts with text, score, source_file, chunk_index."""
        k = top_k or settings.top_k
        vector = encode_one(question)

        results = self._collection.query(
            query_embeddings=[vector],
            n_results=min(k, max(1, self._collection.count())),
            include=["documents", "metadatas", "distances"],
        )

        hits = []
        for doc, meta, dist in zip(
            results["documents"][0],
            results["metadatas"][0],
            results["distances"][0],
        ):
            # ChromaDB cosine distance: 0 = identical, 2 = opposite
            # Convert to similarity score [0, 1]: score = 1 - dist/2
            score = round(1.0 - dist / 2.0, 4)
            hits.append(
                {
                    "text": doc,
                    "score": score,
                    "source_file": meta.get("source_file", "unknown"),
                    "chunk_index": meta.get("chunk_index", 0),
                }
            )

        return hits

    def count(self) -> int:
        return self._collection.count()

    def reset(self) -> None:
        """Delete the entire collection and recreate it (full reindex trigger)."""
        self._client.delete_collection(settings.chroma_collection)
        self._collection = self._client.get_or_create_collection(
            name=settings.chroma_collection,
            metadata={"hnsw:space": "cosine"},
        )
        logger.warning("ChromaDB: colección eliminada y recreada (reindex completo)")


# Module-level singleton used by pipeline and API
chroma_store = ChromaStore()
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
pytest tests/vectordb/test_chroma_store.py -v
```
Expected: All pass.

- [ ] **Step 5: Commit**

```bash
git add src/vectordb/chroma_store.py tests/vectordb/test_chroma_store.py
git commit -m "feat: ChromaDB store with upsert, delete-by-source, cosine similarity query"
```

---

## Task 10: Ollama Client + Prompt Builder

**Files:**
- Create: `src/llm/ollama_client.py`
- Create: `src/llm/prompt_builder.py`
- Create: `tests/llm/test_prompt_builder.py`
- Create: `tests/llm/test_ollama_client.py`

- [ ] **Step 1: Write failing tests**

Create `tests/llm/test_prompt_builder.py`:

```python
from src.llm.prompt_builder import build_prompt, NO_CONTEXT_ANSWER


def test_prompt_contains_question():
    chunks = [{"text": "Información relevante", "source_file": "doc.pdf", "score": 0.8}]
    prompt = build_prompt("¿Cuál es el proceso?", chunks)
    assert "¿Cuál es el proceso?" in prompt


def test_prompt_contains_chunk_text():
    chunks = [{"text": "El proceso tiene 3 pasos", "source_file": "manual.pdf", "score": 0.9}]
    prompt = build_prompt("¿Cuántos pasos?", chunks)
    assert "El proceso tiene 3 pasos" in prompt


def test_prompt_contains_source_citation():
    chunks = [{"text": "Texto", "source_file": "procedimiento.pdf", "score": 0.85}]
    prompt = build_prompt("Pregunta", chunks)
    assert "procedimiento.pdf" in prompt


def test_prompt_has_system_rules():
    chunks = [{"text": "Texto", "source_file": "doc.pdf", "score": 0.8}]
    prompt = build_prompt("Pregunta", chunks)
    assert "REGLAS ABSOLUTAS" in prompt
    assert "NUNCA inventes" in prompt


def test_no_context_answer_constant_is_defined():
    assert len(NO_CONTEXT_ANSWER) > 20
    assert "No tengo información" in NO_CONTEXT_ANSWER
```

Create `tests/llm/test_ollama_client.py`:

```python
import pytest
from unittest.mock import AsyncMock, patch


@pytest.mark.asyncio
async def test_generate_returns_text():
    from src.llm.ollama_client import generate
    mock_response = AsyncMock()
    mock_response.json.return_value = {"response": "Respuesta generada por el modelo"}
    mock_response.raise_for_status = MagicMock()

    with patch("src.llm.ollama_client.httpx.AsyncClient") as mock_client_cls:
        mock_client = AsyncMock()
        mock_client.__aenter__ = AsyncMock(return_value=mock_client)
        mock_client.__aexit__ = AsyncMock(return_value=False)
        mock_client.post = AsyncMock(return_value=mock_response)
        mock_client_cls.return_value = mock_client

        result = await generate("Prompt de prueba")

    assert result == "Respuesta generada por el modelo"


from unittest.mock import MagicMock
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
pytest tests/llm/ -v
```
Expected: Fail.

- [ ] **Step 3: Create src/llm/prompt_builder.py**

```python
NO_CONTEXT_ANSWER = (
    "No tengo información suficiente en la documentación para responder esta pregunta. "
    "Consulta con el departamento correspondiente."
)

_SYSTEM_RULES = """Eres un asistente empresarial de consulta de documentación interna.

REGLAS ABSOLUTAS:
1. SOLO puedes responder usando la información del CONTEXTO proporcionado.
2. Si la respuesta no está en el contexto, responde EXACTAMENTE:
   "No tengo información suficiente en la documentación para responder esta pregunta. Consulta con el departamento correspondiente."
3. NUNCA inventes datos, fechas, nombres, cifras o procedimientos.
4. NUNCA uses conocimiento externo al contexto.
5. Cita siempre las fuentes al final de tu respuesta usando el formato: [Fuente: nombre_archivo]"""


def build_prompt(question: str, chunks: list[dict]) -> str:
    """Build the RAG prompt from retrieved chunks and user question."""
    context_parts = []
    for i, chunk in enumerate(chunks, 1):
        source = chunk.get("source_file", "desconocido")
        text = chunk.get("text", "")
        context_parts.append(f"[Fragmento {i}] (Fuente: {source})\n{text}")

    context_block = "\n---\n".join(context_parts)

    prompt = f"""{_SYSTEM_RULES}

CONTEXTO RECUPERADO:
---
{context_block}
---

PREGUNTA DEL USUARIO:
{question}

RESPUESTA (en español, cita las fuentes al final):"""

    return prompt
```

- [ ] **Step 4: Create src/llm/ollama_client.py**

```python
import httpx

from src.config import settings
from src.logger import get_logger

logger = get_logger(__name__)


async def generate(prompt: str) -> str:
    """Call Ollama API and return the generated text."""
    payload = {
        "model": settings.ollama_model,
        "prompt": prompt,
        "stream": False,
        "options": {
            "temperature": 0.1,   # Low temperature for factual Q&A
            "num_predict": 512,   # Max tokens in response
        },
    }

    url = f"{settings.ollama_base_url}/api/generate"

    async with httpx.AsyncClient(timeout=settings.ollama_timeout) as client:
        logger.debug(f"Llamando Ollama: {settings.ollama_model}")
        response = await client.post(url, json=payload)
        response.raise_for_status()
        data = response.json()
        text = data.get("response", "").strip()
        logger.debug(f"Ollama respondió: {len(text)} chars")
        return text


async def check_health() -> bool:
    """Check if Ollama is reachable and the model is available."""
    try:
        async with httpx.AsyncClient(timeout=5) as client:
            response = await client.get(f"{settings.ollama_base_url}/api/tags")
            if response.status_code != 200:
                return False
            tags = response.json().get("models", [])
            model_names = [t.get("name", "") for t in tags]
            return any(settings.ollama_model in name for name in model_names)
    except Exception:
        return False
```

- [ ] **Step 5: Run tests to verify they pass**

```bash
pytest tests/llm/ -v
```
Expected: All pass.

- [ ] **Step 6: Commit**

```bash
git add src/llm/ollama_client.py src/llm/prompt_builder.py
git add tests/llm/test_prompt_builder.py tests/llm/test_ollama_client.py
git commit -m "feat: Ollama async client and anti-hallucination RAG prompt builder"
```

---

## Task 11: Response Cache

**Files:**
- Create: `src/cache/response_cache.py`
- Create: `tests/cache/test_response_cache.py`

- [ ] **Step 1: Write failing tests**

Create `tests/cache/test_response_cache.py`:

```python
import time
from src.cache.response_cache import ResponseCache


def test_cache_stores_and_retrieves():
    cache = ResponseCache(ttl_seconds=60)
    cache.set("¿Cuál es el proceso?", {"answer": "El proceso es X"})
    result = cache.get("¿Cuál es el proceso?")
    assert result is not None
    assert result["answer"] == "El proceso es X"


def test_cache_miss_returns_none():
    cache = ResponseCache(ttl_seconds=60)
    result = cache.get("Pregunta que no existe")
    assert result is None


def test_cache_expires_after_ttl():
    cache = ResponseCache(ttl_seconds=1)
    cache.set("Pregunta", {"answer": "Respuesta"})
    time.sleep(1.1)
    result = cache.get("Pregunta")
    assert result is None


def test_cache_is_case_insensitive_and_stripped():
    cache = ResponseCache(ttl_seconds=60)
    cache.set("¿Cuál es el proceso?", {"answer": "X"})
    result = cache.get("  ¿Cuál es el proceso?  ")
    assert result is not None


def test_cache_size():
    cache = ResponseCache(ttl_seconds=60)
    cache.set("q1", {"answer": "a1"})
    cache.set("q2", {"answer": "a2"})
    assert cache.size() == 2
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
pytest tests/cache/test_response_cache.py -v
```
Expected: Fail.

- [ ] **Step 3: Create src/cache/response_cache.py**

```python
import hashlib
import time

from src.logger import get_logger

logger = get_logger(__name__)


class ResponseCache:
    def __init__(self, ttl_seconds: int = 7200):
        self._store: dict[str, tuple[dict, float]] = {}
        self._ttl = ttl_seconds

    def _key(self, question: str) -> str:
        normalised = question.strip().lower()
        return hashlib.sha256(normalised.encode("utf-8")).hexdigest()

    def get(self, question: str) -> dict | None:
        key = self._key(question)
        entry = self._store.get(key)
        if entry is None:
            return None
        value, expires_at = entry
        if time.time() > expires_at:
            del self._store[key]
            logger.debug("Cache: entrada expirada eliminada")
            return None
        logger.debug("Cache hit")
        return value

    def set(self, question: str, response: dict) -> None:
        key = self._key(question)
        self._store[key] = (response, time.time() + self._ttl)
        logger.debug(f"Cache: nueva entrada ({len(self._store)} total)")

    def size(self) -> int:
        # Purge expired first
        now = time.time()
        expired = [k for k, (_, exp) in self._store.items() if now > exp]
        for k in expired:
            del self._store[k]
        return len(self._store)
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
pytest tests/cache/test_response_cache.py -v
```
Expected: All pass.

- [ ] **Step 5: Commit**

```bash
git add src/cache/response_cache.py tests/cache/test_response_cache.py
git commit -m "feat: in-memory TTL response cache"
```

---

## Task 12: API Endpoints

**Files:**
- Create: `src/api/ingest.py`
- Create: `src/api/chat.py`
- Create: `src/api/admin.py`
- Create: `tests/api/test_ingest.py`
- Create: `tests/api/test_chat.py`
- Create: `tests/api/test_admin.py`

- [ ] **Step 1: Write failing tests**

Create `tests/api/test_ingest.py`:

```python
import pytest
from unittest.mock import patch
from fastapi.testclient import TestClient


@pytest.fixture
def client():
    from src.main import app
    return TestClient(app)


def test_ingest_all_returns_200(client):
    with patch("src.api.ingest.process_all", return_value={"total": 3, "ok": 3, "results": []}):
        response = client.post("/ingest")
    assert response.status_code == 200
    assert response.json()["ok"] == 3


def test_ingest_file_created_returns_200(client):
    with patch("src.api.ingest.process_file", return_value={
        "action": "created", "source": "doc.pdf", "status": "ok", "chunks_indexed": 12
    }):
        response = client.post("/ingest/file", json={"path": "C:/data/documents/doc.pdf", "action": "created"})
    assert response.status_code == 200
    assert response.json()["chunks_indexed"] == 12


def test_ingest_file_deleted_returns_200(client):
    with patch("src.api.ingest.process_file", return_value={
        "action": "deleted", "source": "doc.pdf", "status": "ok"
    }):
        response = client.post("/ingest/file", json={"path": "C:/data/doc.pdf", "action": "deleted"})
    assert response.status_code == 200
```

Create `tests/api/test_chat.py`:

```python
import pytest
from unittest.mock import patch, AsyncMock
from fastapi.testclient import TestClient


@pytest.fixture
def client():
    from src.main import app
    return TestClient(app)


def test_chat_returns_answer(client):
    chunks = [{"text": "Info relevante", "score": 0.8, "source_file": "doc.pdf", "chunk_index": 0}]
    with patch("src.api.chat.chroma_store") as mock_store, \
         patch("src.api.chat.generate", new_callable=AsyncMock, return_value="La respuesta es X"), \
         patch("src.api.chat._cache") as mock_cache:
        mock_cache.get.return_value = None
        mock_store.query.return_value = chunks
        response = client.post("/chat", json={"question": "¿Cuál es el proceso?"})
    assert response.status_code == 200
    data = response.json()
    assert "answer" in data
    assert "sources" in data
    assert "confidence" in data


def test_chat_returns_no_info_when_below_threshold(client):
    chunks = [{"text": "Info poco relevante", "score": 0.3, "source_file": "doc.pdf", "chunk_index": 0}]
    with patch("src.api.chat.chroma_store") as mock_store, \
         patch("src.api.chat._cache") as mock_cache:
        mock_cache.get.return_value = None
        mock_store.query.return_value = chunks
        response = client.post("/chat", json={"question": "Pregunta sin respuesta"})
    assert response.status_code == 200
    data = response.json()
    assert data["confidence"] == "none"
    assert "No tengo información" in data["answer"]


def test_chat_returns_cached_response(client):
    cached = {"answer": "Respuesta cacheada", "sources": [], "confidence": "high", "cached": True}
    with patch("src.api.chat._cache") as mock_cache:
        mock_cache.get.return_value = cached
        response = client.post("/chat", json={"question": "Pregunta cacheada"})
    assert response.status_code == 200
    assert response.json()["cached"] is True
```

Create `tests/api/test_admin.py`:

```python
import pytest
from unittest.mock import patch, AsyncMock
from fastapi.testclient import TestClient


@pytest.fixture
def client():
    from src.main import app
    return TestClient(app)


def test_health_returns_200(client):
    with patch("src.api.admin.check_health", new_callable=AsyncMock, return_value=True), \
         patch("src.api.admin.chroma_store") as mock_store:
        mock_store.count.return_value = 42
        response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] in ("ok", "degraded")
    assert "ollama" in data
    assert "chromadb_vectors" in data
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
pytest tests/api/ -v
```
Expected: All fail.

- [ ] **Step 3: Create src/api/ingest.py**

```python
from fastapi import APIRouter
from pydantic import BaseModel

from src.ingestion.pipeline import process_file, process_all
from src.logger import get_logger

router = APIRouter()
logger = get_logger(__name__)


class FileIngestRequest(BaseModel):
    path: str
    action: str  # created | changed | deleted | renamed


@router.post("/ingest")
def ingest_all():
    """Scan documents directory and index all supported files."""
    logger.info("Ingesta completa iniciada")
    return process_all()


@router.post("/ingest/file")
def ingest_file(req: FileIngestRequest):
    """Index or remove a single file (called by FileSystemWatcher)."""
    logger.info(f"Ingesta de archivo: action={req.action} path={req.path}")
    return process_file(req.path, action=req.action)
```

- [ ] **Step 4: Create src/api/chat.py**

```python
import asyncio
import time

from fastapi import APIRouter
from pydantic import BaseModel

from src.cache.response_cache import ResponseCache
from src.config import settings
from src.llm.ollama_client import generate
from src.llm.prompt_builder import build_prompt, NO_CONTEXT_ANSWER
from src.logger import get_logger
from src.vectordb.chroma_store import chroma_store

router = APIRouter()
logger = get_logger(__name__)

_cache = ResponseCache(ttl_seconds=settings.cache_ttl_seconds)
_semaphore = asyncio.Semaphore(settings.max_concurrent_llm)


class ChatRequest(BaseModel):
    question: str
    session_id: str | None = None


@router.post("/chat")
async def chat(req: ChatRequest):
    start = time.time()
    question = req.question.strip()

    # 1. Cache check
    cached = _cache.get(question)
    if cached:
        return {**cached, "cached": True, "response_time_ms": int((time.time() - start) * 1000)}

    # 2. Semantic search
    hits = chroma_store.query(question, top_k=settings.top_k)

    # 3. Threshold filter
    top_score = hits[0]["score"] if hits else 0.0
    if top_score < settings.similarity_threshold:
        logger.info(f"Sin contexto suficiente (score={top_score:.3f} < {settings.similarity_threshold})")
        return {
            "answer": NO_CONTEXT_ANSWER,
            "sources": [],
            "confidence": "none",
            "cached": False,
            "response_time_ms": int((time.time() - start) * 1000),
        }

    # 4. Build prompt and call LLM (rate-limited)
    prompt = build_prompt(question, hits)
    async with _semaphore:
        answer = await generate(prompt)

    # 5. Build sources list (deduplicated)
    seen = set()
    sources = []
    for hit in hits:
        sf = hit["source_file"]
        if sf not in seen:
            seen.add(sf)
            sources.append({"file": sf, "score": hit["score"]})

    avg_score = sum(h["score"] for h in hits) / len(hits)
    confidence = "high" if avg_score >= settings.cache_threshold else "low"

    response = {
        "answer": answer,
        "sources": sources,
        "confidence": confidence,
        "cached": False,
        "response_time_ms": int((time.time() - start) * 1000),
    }

    # 6. Cache if high confidence
    if avg_score >= settings.cache_threshold:
        _cache.set(question, response)

    return response
```

- [ ] **Step 5: Create src/api/admin.py**

```python
from fastapi import APIRouter

from src.ingestion.pipeline import process_all
from src.llm.ollama_client import check_health
from src.logger import get_logger
from src.vectordb.chroma_store import chroma_store

router = APIRouter()
logger = get_logger(__name__)


@router.get("/health")
async def health():
    ollama_ok = await check_health()
    vector_count = chroma_store.count()
    return {
        "status": "ok" if ollama_ok else "degraded",
        "ollama": "ok" if ollama_ok else "unreachable",
        "ollama_model": "qwen2.5:3b",
        "chromadb": "ok",
        "chromadb_vectors": vector_count,
    }


@router.get("/stats")
def stats():
    return {
        "chromadb_vectors": chroma_store.count(),
    }


@router.post("/reindex")
def reindex():
    """Wipe ChromaDB collection and reindex all documents from scratch."""
    logger.warning("Reindexado completo iniciado — borrando colección existente")
    chroma_store.reset()
    result = process_all()
    logger.info(f"Reindexado completo: {result['ok']}/{result['total']} archivos")
    return result
```

- [ ] **Step 6: Run tests to verify they pass**

```bash
pytest tests/api/ -v
```
Expected: All pass.

- [ ] **Step 7: Commit**

```bash
git add src/api/ingest.py src/api/chat.py src/api/admin.py
git add tests/api/test_ingest.py tests/api/test_chat.py tests/api/test_admin.py
git commit -m "feat: ingest, chat, and admin API endpoints"
```

---

## Task 13: FastAPI Main App

**Files:**
- Create: `src/main.py`
- Create: `tests/test_main.py`

- [ ] **Step 1: Write failing test**

Create `tests/test_main.py`:

```python
from fastapi.testclient import TestClient


def test_app_has_docs():
    from src.main import app
    client = TestClient(app)
    response = client.get("/docs")
    assert response.status_code == 200


def test_openapi_includes_chat_endpoint():
    from src.main import app
    client = TestClient(app)
    response = client.get("/openapi.json")
    assert response.status_code == 200
    paths = response.json()["paths"]
    assert "/chat" in paths
    assert "/ingest" in paths
    assert "/health" in paths
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
pytest tests/test_main.py -v
```
Expected: Fail.

- [ ] **Step 3: Create src/main.py**

```python
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from src.api import chat, ingest, admin
from src.logger import get_logger

logger = get_logger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("RAG Chatbot iniciando...")
    logger.info("Backend listo para recibir peticiones")
    yield
    logger.info("RAG Chatbot detenido")


app = FastAPI(
    title="RAG Chatbot Empresarial",
    description="API para consulta de documentación interna basada en RAG",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["GET", "POST", "DELETE"],
    allow_headers=["*"],
)

app.include_router(chat.router, tags=["Chat"])
app.include_router(ingest.router, tags=["Ingestion"])
app.include_router(admin.router, tags=["Admin"])
```

- [ ] **Step 4: Run ALL tests**

```bash
pytest tests/ -v
```
Expected: All pass.

- [ ] **Step 5: Verify the app starts**

```bash
python -m uvicorn src.main:app --host 0.0.0.0 --port 8000 --reload
```
Expected: `Application startup complete.` — then visit http://localhost:8000/docs in browser.

- [ ] **Step 6: Commit**

```bash
git add src/main.py tests/test_main.py
git commit -m "feat: FastAPI app assembly with CORS and lifespan"
```

---

## Task 14: PowerShell Scripts

**Files:**
- Create: `scripts/install.ps1`
- Create: `scripts/watch-and-serve.ps1`
- Create: `scripts/reindex-all.ps1`

- [ ] **Step 1: Create scripts/install.ps1**

```powershell
# install.ps1 — Full installation script for the RAG Chatbot on Windows 11
# Run as Administrator: .\scripts\install.ps1
#
# WHAT THIS INSTALLS (all free, open source):
#   MANDATORY:
#     - Python 3.11          (runtime)
#     - pip packages         (requirements.txt)
#     - Ollama               (LLM runtime)
#     - qwen2.5:3b model     (LLM — ~2.1 GB)
#     - Tesseract-OCR        (OCR engine, via winget)
#     - Tesseract Spanish    (language pack spa.traineddata)
#     - Tesseract English    (language pack eng.traineddata)
#   OPTIONAL:
#     - Poppler              (required by pdf2image for PDF→image conversion)
#
# PREREQUISITES: Python 3.11+, pip, winget (Windows Package Manager)

param(
    [switch]$SkipOllama,
    [switch]$SkipTesseract,
    [switch]$SkipPoppler
)

$ErrorActionPreference = "Stop"

function Write-Step($msg) {
    Write-Host "`n==> $msg" -ForegroundColor Cyan
}

function Test-CommandExists($cmd) {
    return [bool](Get-Command $cmd -ErrorAction SilentlyContinue)
}

Write-Step "1/6 Verificando Python"
if (-not (Test-CommandExists "python")) {
    Write-Error "Python no encontrado. Instala Python 3.11+ desde https://www.python.org"
    exit 1
}
$pyVersion = python --version
Write-Host "  Encontrado: $pyVersion"

Write-Step "2/6 Instalando dependencias Python"
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
Write-Host "  Dependencias instaladas."

if (-not $SkipTesseract) {
    Write-Step "3/6 Instalando Tesseract-OCR"
    if (Test-CommandExists "tesseract") {
        Write-Host "  Tesseract ya instalado."
    } else {
        winget install --id UB-Mannheim.TesseractOCR --accept-package-agreements --accept-source-agreements
        Write-Host "  Tesseract instalado."
    }

    # Download Spanish language pack
    $tessDataDir = "C:\Program Files\Tesseract-OCR\tessdata"
    $spaFile = "$tessDataDir\spa.traineddata"
    $engFile = "$tessDataDir\eng.traineddata"

    if (-not (Test-Path $spaFile)) {
        Write-Host "  Descargando paquete de idioma español..."
        Invoke-WebRequest -Uri "https://github.com/tesseract-ocr/tessdata/raw/main/spa.traineddata" -OutFile $spaFile
        Write-Host "  spa.traineddata instalado."
    } else {
        Write-Host "  spa.traineddata ya existe."
    }

    if (-not (Test-Path $engFile)) {
        Write-Host "  Descargando paquete de idioma inglés..."
        Invoke-WebRequest -Uri "https://github.com/tesseract-ocr/tessdata/raw/main/eng.traineddata" -OutFile $engFile
        Write-Host "  eng.traineddata instalado."
    }
}

if (-not $SkipPoppler) {
    Write-Step "4/6 Instalando Poppler (requerido por pdf2image)"
    $popplerPath = "C:\poppler\bin"
    if (Test-Path $popplerPath) {
        Write-Host "  Poppler ya instalado en $popplerPath"
    } else {
        Write-Host "  Descargando Poppler para Windows..."
        $popplerZip = "$env:TEMP\poppler.zip"
        Invoke-WebRequest -Uri "https://github.com/oschwartz10612/poppler-windows/releases/download/v24.02.0-0/Release-24.02.0-0.zip" -OutFile $popplerZip
        Expand-Archive -Path $popplerZip -DestinationPath "C:\poppler-extract" -Force
        $popplerDir = Get-ChildItem "C:\poppler-extract" -Directory | Select-Object -First 1
        Move-Item $popplerDir.FullName "C:\poppler" -Force
        Remove-Item $popplerZip -Force
        Remove-Item "C:\poppler-extract" -Recurse -Force -ErrorAction SilentlyContinue

        # Add to system PATH
        $currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
        if ($currentPath -notlike "*C:\poppler\bin*") {
            [Environment]::SetEnvironmentVariable("Path", "$currentPath;C:\poppler\bin", "Machine")
            $env:Path += ";C:\poppler\bin"
        }
        Write-Host "  Poppler instalado y añadido al PATH."
    }
}

if (-not $SkipOllama) {
    Write-Step "5/6 Instalando Ollama y modelo qwen2.5:3b"
    if (Test-CommandExists "ollama") {
        Write-Host "  Ollama ya instalado."
    } else {
        Write-Host "  Descargando instalador de Ollama..."
        $ollamaInstaller = "$env:TEMP\OllamaSetup.exe"
        Invoke-WebRequest -Uri "https://ollama.com/download/OllamaSetup.exe" -OutFile $ollamaInstaller
        Start-Process -FilePath $ollamaInstaller -ArgumentList "/S" -Wait
        Write-Host "  Ollama instalado."
    }

    Write-Host "  Iniciando Ollama para descarga del modelo (esto puede tardar varios minutos)..."
    Start-Process -FilePath "ollama" -ArgumentList "serve" -WindowStyle Hidden
    Start-Sleep -Seconds 3
    & ollama pull qwen2.5:3b
    Write-Host "  Modelo qwen2.5:3b descargado."
}

Write-Step "6/6 Configurando entorno"
if (-not (Test-Path ".env")) {
    Copy-Item ".env.example" ".env"
    Write-Host "  .env creado desde .env.example — revisa y ajusta los valores si es necesario."
} else {
    Write-Host "  .env ya existe, no sobreescrito."
}

# Create required directories
New-Item -ItemType Directory -Path "data\documents" -Force | Out-Null
New-Item -ItemType Directory -Path "chroma_db" -Force | Out-Null
New-Item -ItemType Directory -Path "logs" -Force | Out-Null

Write-Host "`n" + "="*60 -ForegroundColor Green
Write-Host "INSTALACION COMPLETADA" -ForegroundColor Green
Write-Host "="*60 -ForegroundColor Green
Write-Host @"
Para iniciar el chatbot:
  .\scripts\watch-and-serve.ps1

Para indexar documentos manualmente:
  Coloca archivos en data\documents\ y ejecuta:
  Invoke-RestMethod -Uri http://localhost:8000/ingest -Method POST

Documentacion API:
  http://localhost:8000/docs
"@
```

- [ ] **Step 2: Create scripts/watch-and-serve.ps1**

```powershell
# watch-and-serve.ps1 — Start RAG Chatbot and watch documents folder for changes
# Usage: .\scripts\watch-and-serve.ps1
# Usage with custom paths: .\scripts\watch-and-serve.ps1 -DocumentsPath "D:\docs" -ApiPort 8000

param(
    [string]$DocumentsPath = ".\data\documents",
    [string]$ApiPort = "8000",
    [int]$DebounceMs = 3000
)

$ErrorActionPreference = "Stop"
$script:DebounceMs = $DebounceMs
$script:lastEvent = @{}

function Write-Log($msg, $color = "White") {
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $msg" -ForegroundColor $color
}

function Invoke-IngestFile($filePath, $action) {
    $body = @{ path = $filePath; action = $action } | ConvertTo-Json
    try {
        $result = Invoke-RestMethod `
            -Uri "http://localhost:$ApiPort/ingest/file" `
            -Method POST `
            -Body $body `
            -ContentType "application/json" `
            -TimeoutSec 300
        $chunks = $result.chunks_indexed
        if ($action -eq "deleted") {
            Write-Log "ELIMINADO: $([System.IO.Path]::GetFileName($filePath))" "Yellow"
        } else {
            Write-Log "INDEXADO: $([System.IO.Path]::GetFileName($filePath)) → $chunks chunks" "Green"
        }
    } catch {
        Write-Log "ERROR al procesar '$filePath': $_" "Red"
    }
}

# ── Start services ─────────────────────────────────────────────────────────
Write-Log "Iniciando Ollama..." "Cyan"
$ollamaProc = Start-Process -FilePath "ollama" -ArgumentList "serve" -PassThru -WindowStyle Hidden
Start-Sleep -Seconds 3

# Verify Ollama health
try {
    $health = Invoke-RestMethod -Uri "http://localhost:11434/api/tags" -TimeoutSec 10
    Write-Log "Ollama activo. Modelos disponibles: $($health.models.Count)" "Green"
} catch {
    Write-Log "ADVERTENCIA: Ollama no responde. Asegúrate de que está instalado." "Yellow"
}

Write-Log "Iniciando FastAPI en puerto $ApiPort..." "Cyan"
$script:fastapiProc = Start-Process `
    -FilePath "python" `
    -ArgumentList "-m uvicorn src.main:app --host 0.0.0.0 --port $ApiPort" `
    -PassThru -WindowStyle Hidden

# Wait for FastAPI to be ready
$retries = 0
do {
    Start-Sleep -Seconds 2
    $retries++
    try {
        $null = Invoke-RestMethod -Uri "http://localhost:$ApiPort/health" -TimeoutSec 5
        Write-Log "FastAPI activo en http://0.0.0.0:$ApiPort" "Green"
        Write-Log "Documentacion API: http://localhost:$ApiPort/docs" "Cyan"
        break
    } catch {
        Write-Log "Esperando FastAPI... ($retries/15)" "Gray"
    }
} while ($retries -lt 15)

# ── FileSystemWatcher ──────────────────────────────────────────────────────
$docPath = Resolve-Path $DocumentsPath -ErrorAction SilentlyContinue
if (-not $docPath) {
    New-Item -ItemType Directory -Path $DocumentsPath -Force | Out-Null
    $docPath = Resolve-Path $DocumentsPath
}

Write-Log "Vigilando: $docPath" "Cyan"

$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $docPath.Path
$watcher.IncludeSubdirectories = $true
$watcher.EnableRaisingEvents = $true

$handler = {
    param($source, $e)
    $file = $e.FullPath
    $fileName = [System.IO.Path]::GetFileName($file)

    # Skip Office temporary files
    if ($fileName.StartsWith("~$")) { return }
    # Skip hidden files
    if ($fileName.StartsWith(".")) { return }

    $action = $e.ChangeType.ToString().ToLower()
    $now = [DateTime]::Now

    # Debounce
    if ($script:lastEvent.ContainsKey($file)) {
        $diff = ($now - $script:lastEvent[$file]).TotalMilliseconds
        if ($diff -lt $script:DebounceMs) { return }
    }
    $script:lastEvent[$file] = $now

    Invoke-IngestFile -filePath $file -action $action
}

$createdEvent  = Register-ObjectEvent $watcher "Created" -Action $handler
$changedEvent  = Register-ObjectEvent $watcher "Changed" -Action $handler
$deletedEvent  = Register-ObjectEvent $watcher "Deleted" -Action $handler

# Handle renamed separately (has OldFullPath + FullPath)
$renamedHandler = {
    param($source, $e)
    $now = [DateTime]::Now
    # Delete old
    if (-not $e.OldFullPath.Split('\')[-1].StartsWith("~$")) {
        Invoke-IngestFile -filePath $e.OldFullPath -action "deleted"
    }
    # Create new
    if (-not $e.FullPath.Split('\')[-1].StartsWith("~$")) {
        $script:lastEvent[$e.FullPath] = $now
        Invoke-IngestFile -filePath $e.FullPath -action "created"
    }
}
$renamedEvent = Register-ObjectEvent $watcher "Renamed" -Action $renamedHandler

Write-Log "Sistema listo. Ctrl+C para detener." "Green"
Write-Log "" "White"

try {
    while ($true) { Start-Sleep -Seconds 5 }
} finally {
    Write-Log "Deteniendo servicios..." "Yellow"
    $watcher.EnableRaisingEvents = $false
    $watcher.Dispose()
    Unregister-Event -SourceIdentifier $createdEvent.Name -ErrorAction SilentlyContinue
    Unregister-Event -SourceIdentifier $changedEvent.Name -ErrorAction SilentlyContinue
    Unregister-Event -SourceIdentifier $deletedEvent.Name -ErrorAction SilentlyContinue
    Unregister-Event -SourceIdentifier $renamedEvent.Name -ErrorAction SilentlyContinue
    if ($script:fastapiProc -and -not $script:fastapiProc.HasExited) {
        Stop-Process -Id $script:fastapiProc.Id -Force -ErrorAction SilentlyContinue
    }
    Write-Log "Servicios detenidos." "Yellow"
}
```

- [ ] **Step 3: Create scripts/reindex-all.ps1**

```powershell
# reindex-all.ps1 — Wipe ChromaDB and reindex all documents from scratch
# Use when: adding/removing many documents, after changing chunk settings,
#           or when the index is suspected to be corrupt.
# WARNING: This deletes ALL existing embeddings and regenerates them.

param(
    [string]$ApiPort = "8000",
    [switch]$Force
)

if (-not $Force) {
    $confirm = Read-Host "AVISO: Esto borrara todos los embeddings existentes y reindexara desde cero. Continuar? (s/N)"
    if ($confirm -ne "s" -and $confirm -ne "S") {
        Write-Host "Cancelado." -ForegroundColor Yellow
        exit 0
    }
}

Write-Host "Iniciando reindexado completo..." -ForegroundColor Cyan

try {
    $result = Invoke-RestMethod `
        -Uri "http://localhost:$ApiPort/reindex" `
        -Method POST `
        -TimeoutSec 3600  # Allow up to 1 hour for large collections

    Write-Host "Reindexado completado:" -ForegroundColor Green
    Write-Host "  Total archivos: $($result.total)"
    Write-Host "  Indexados OK:   $($result.ok)"
    Write-Host "  Errores:        $($result.total - $result.ok)"
} catch {
    Write-Host "Error durante el reindexado: $_" -ForegroundColor Red
    exit 1
}
```

- [ ] **Step 4: Commit**

```bash
git add scripts/install.ps1 scripts/watch-and-serve.ps1 scripts/reindex-all.ps1
git commit -m "feat: PowerShell scripts — install, watch-and-serve, reindex"
```

---

## Task 15: ASP Classic Integration

**Files:**
- Create: `asp/chat.asp`
- Create: `asp/ingest.asp`

- [ ] **Step 1: Create asp/chat.asp**

```asp
<%@ Language="VBScript" %>
<%
' chat.asp — RAG Chatbot interface for ASP Classic
' Calls the FastAPI backend running on the AI server.
' Configure AI_SERVER_URL to point to your AI server IP.

Const AI_SERVER_URL = "http://IP_SERVIDOR_IA:8000"

Dim question, jsonResponse, answer, sources, confidence
question = ""
answer = ""
sources = ""
confidence = ""

If Request.ServerVariables("REQUEST_METHOD") = "POST" Then
    question = Trim(Request.Form("question"))

    If question <> "" Then
        Dim http, requestBody, responseText
        Set http = Server.CreateObject("MSXML2.ServerXMLHTTP.6.0")

        ' Build JSON body (basic escaping)
        Dim escapedQuestion
        escapedQuestion = Replace(question, "\", "\\")
        escapedQuestion = Replace(escapedQuestion, """", "\""")
        requestBody = "{""question"":""" & escapedQuestion & """}"

        On Error Resume Next
        http.open "POST", AI_SERVER_URL & "/chat", False
        http.setRequestHeader "Content-Type", "application/json"
        http.setRequestHeader "Accept", "application/json"
        http.send requestBody

        If Err.Number <> 0 Then
            answer = "Error de conexion con el servidor de IA: " & Err.Description
            confidence = "error"
        ElseIf http.status = 200 Then
            responseText = http.responseText

            ' Simple JSON field extraction (no external JSON parser needed)
            answer = ExtractJsonField(responseText, "answer")
            confidence = ExtractJsonField(responseText, "confidence")

            ' Extract sources array (simplified)
            Dim sourcesStart, sourcesEnd
            sourcesStart = InStr(responseText, """sources"":")
            If sourcesStart > 0 Then
                sourcesStart = InStr(sourcesStart, responseText, "[")
                sourcesEnd = InStr(sourcesStart, responseText, "]")
                If sourcesStart > 0 And sourcesEnd > 0 Then
                    sources = Mid(responseText, sourcesStart, sourcesEnd - sourcesStart + 1)
                End If
            End If
        Else
            answer = "Error del servidor: HTTP " & http.status
            confidence = "error"
        End If

        Set http = Nothing
        On Error GoTo 0
    End If
End If

' Helper: extract a string field from a simple JSON object
Function ExtractJsonField(jsonStr, fieldName)
    Dim startPos, endPos, searchFor
    searchFor = """" & fieldName & """:"""
    startPos = InStr(jsonStr, searchFor)
    If startPos = 0 Then
        ExtractJsonField = ""
        Exit Function
    End If
    startPos = startPos + Len(searchFor)
    endPos = startPos
    Do While endPos <= Len(jsonStr)
        Dim c
        c = Mid(jsonStr, endPos, 1)
        If c = """" And Mid(jsonStr, endPos - 1, 1) <> "\" Then Exit Do
        endPos = endPos + 1
    Loop
    ExtractJsonField = Mid(jsonStr, startPos, endPos - startPos)
    ' Unescape common sequences
    ExtractJsonField = Replace(ExtractJsonField, "\n", Chr(13) & Chr(10))
    ExtractJsonField = Replace(ExtractJsonField, "\""", """")
End Function
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Chatbot Empresarial</title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 800px; margin: 40px auto; padding: 0 20px; background: #f5f5f5; }
        h1 { color: #2c3e50; border-bottom: 2px solid #3498db; padding-bottom: 10px; }
        .chat-box { background: white; border-radius: 8px; padding: 20px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); margin-bottom: 20px; }
        .question-label { font-weight: bold; color: #2c3e50; margin-bottom: 8px; display: block; }
        textarea { width: 100%; min-height: 80px; padding: 10px; border: 1px solid #ddd; border-radius: 4px; font-size: 14px; resize: vertical; box-sizing: border-box; }
        button { background: #3498db; color: white; border: none; padding: 10px 24px; border-radius: 4px; cursor: pointer; font-size: 14px; margin-top: 8px; }
        button:hover { background: #2980b9; }
        .answer-box { background: #f8f9fa; border-left: 4px solid #3498db; padding: 15px; margin-top: 20px; border-radius: 0 4px 4px 0; white-space: pre-wrap; line-height: 1.6; }
        .confidence-high { border-left-color: #27ae60; }
        .confidence-low { border-left-color: #f39c12; }
        .confidence-none { border-left-color: #e74c3c; background: #fff5f5; }
        .confidence-error { border-left-color: #e74c3c; background: #fff5f5; }
        .badge { display: inline-block; padding: 2px 8px; border-radius: 12px; font-size: 11px; font-weight: bold; text-transform: uppercase; margin-left: 8px; }
        .badge-high { background: #d5f5e3; color: #27ae60; }
        .badge-low { background: #fef9e7; color: #f39c12; }
        .badge-none { background: #fadbd8; color: #e74c3c; }
        .question-display { font-style: italic; color: #666; margin-bottom: 10px; }
        .footer { text-align: center; color: #aaa; font-size: 12px; margin-top: 40px; }
    </style>
</head>
<body>
    <h1>Chatbot Empresarial</h1>
    <div class="chat-box">
        <form method="post" action="chat.asp">
            <label class="question-label" for="question">¿En qué puedo ayudarte?</label>
            <textarea id="question" name="question" placeholder="Escribe tu pregunta sobre la documentación interna..."><%=Server.HTMLEncode(question)%></textarea>
            <button type="submit">Consultar</button>
        </form>
    </div>

    <% If answer <> "" Then %>
    <div class="chat-box">
        <% If question <> "" Then %>
        <p class="question-display">Pregunta: <strong><%=Server.HTMLEncode(question)%></strong></p>
        <% End If %>

        <strong>Respuesta
            <% If confidence = "high" Then %>
                <span class="badge badge-high">Alta confianza</span>
            <% ElseIf confidence = "low" Then %>
                <span class="badge badge-low">Baja confianza</span>
            <% ElseIf confidence = "none" Then %>
                <span class="badge badge-none">Sin contexto</span>
            <% End If %>
        </strong>

        <div class="answer-box confidence-<%=confidence%>"><%=Server.HTMLEncode(answer)%></div>

        <% If confidence = "low" Then %>
        <p style="color: #f39c12; font-size: 12px; margin-top: 8px;">
            ⚠ Confianza baja. Verifica la respuesta en los documentos originales.
        </p>
        <% End If %>
    </div>
    <% End If %>

    <div class="footer">Chatbot RAG Empresarial — Basado en documentación interna</div>
</body>
</html>
```

- [ ] **Step 2: Create asp/ingest.asp**

```asp
<%@ Language="VBScript" %>
<%
' ingest.asp — Admin page to trigger document re-indexing from ASP
' Access this page from a browser to trigger a full re-index.
' Restrict access in IIS to admin users only.

Const AI_SERVER_URL = "http://IP_SERVIDOR_IA:8000"

Dim action, result
action = Request.QueryString("action")

If action = "ingest" Or action = "reindex" Then
    Dim http, endpoint
    endpoint = "/ingest"
    If action = "reindex" Then endpoint = "/reindex"

    Set http = Server.CreateObject("MSXML2.ServerXMLHTTP.6.0")
    On Error Resume Next
    http.open "POST", AI_SERVER_URL & endpoint, False
    http.setRequestHeader "Content-Type", "application/json"
    http.send "{}"

    If Err.Number <> 0 Then
        result = "Error de conexion: " & Err.Description
    ElseIf http.status = 200 Then
        result = "OK: " & http.responseText
    Else
        result = "Error HTTP " & http.status & ": " & http.responseText
    End If
    Set http = Nothing
    On Error GoTo 0
End If
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Administracion — Indexacion</title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 600px; margin: 40px auto; padding: 0 20px; }
        h1 { color: #2c3e50; }
        .btn { display: inline-block; padding: 10px 20px; margin: 8px; border-radius: 4px; text-decoration: none; color: white; font-weight: bold; }
        .btn-blue { background: #3498db; }
        .btn-orange { background: #e67e22; }
        .btn-blue:hover { background: #2980b9; }
        .btn-orange:hover { background: #d35400; }
        pre { background: #f5f5f5; padding: 15px; border-radius: 4px; overflow-x: auto; }
        .warning { color: #e74c3c; font-weight: bold; }
    </style>
</head>
<body>
    <h1>Administracion — Indexacion de Documentos</h1>
    <p>Usa estos botones para gestionar el indice de documentos del chatbot.</p>

    <a href="ingest.asp?action=ingest" class="btn btn-blue">Indexar nuevos documentos</a>
    <a href="ingest.asp?action=reindex" class="btn btn-orange"
       onclick="return confirm('Esto borrara y regenerara todo el indice. Puede tardar varios minutos. Continuar?')">
        Reindexar todo (desde cero)
    </a>

    <p class="warning">Advertencia: El reindexado completo puede tardar varios minutos dependiendo del numero de documentos.</p>

    <% If result <> "" Then %>
    <h2>Resultado:</h2>
    <pre><%=Server.HTMLEncode(result)%></pre>
    <% End If %>
</body>
</html>
```

- [ ] **Step 3: Commit**

```bash
git add asp/chat.asp asp/ingest.asp
git commit -m "feat: ASP classic integration — chat UI and admin ingest page"
```

---

## Task 16: Final Integration Test + .env

- [ ] **Step 1: Create .env from .env.example**

```bash
cp .env.example .env
```

Verify that `TESSERACT_CMD` points to the correct path (default: `C:\Program Files\Tesseract-OCR\tesseract.exe`).

- [ ] **Step 2: Run full test suite**

```bash
pytest tests/ -v --tb=short
```
Expected: All tests pass.

- [ ] **Step 3: Start services and verify end-to-end**

In one terminal:
```bash
ollama serve
```

In another terminal:
```bash
python -m uvicorn src.main:app --host 0.0.0.0 --port 8000 --reload
```

Check health:
```bash
curl http://localhost:8000/health
```
Expected response:
```json
{"status": "ok", "ollama": "ok", "chromadb": "ok", "chromadb_vectors": 0}
```

- [ ] **Step 4: Test ingestion with a sample file**

Create a test document:
```bash
echo "La empresa fue fundada en 1995. El proceso de alta de empleados requiere formulario HR-01 y validación del responsable de área." > data/documents/test_empresa.txt
```

Trigger ingest:
```bash
curl -X POST http://localhost:8000/ingest
```

Check stats:
```bash
curl http://localhost:8000/stats
```
Expected: `chromadb_vectors` > 0.

- [ ] **Step 5: Test chat**

```bash
curl -X POST http://localhost:8000/chat \
  -H "Content-Type: application/json" \
  -d "{\"question\": \"¿Cuándo fue fundada la empresa?\"}"
```
Expected: Response contains `answer` citing 1995, `sources` with `test_empresa.txt`, `confidence: high`.

- [ ] **Step 6: Final commit**

```bash
git add .env.example
git commit -m "feat: complete RAG chatbot — all components integrated and tested"
```

---

## Self-Review Against Spec

**Spec coverage check:**

| Requirement | Task |
|---|---|
| PDF extraction (texto nativo) | Task 5 |
| PDF escaneado (OCR) | Task 5 |
| PDF mixto (fusión) | Task 5 |
| Imágenes OCR | Task 3 |
| DOCX, PPTX, XLSX | Task 4 |
| TXT, HTML | Task 3 |
| Embeddings multilingüe | Task 8 |
| ChromaDB + búsqueda semántica | Task 9 |
| Ollama + qwen2.5:3b | Task 10 |
| Prompt anti-alucinación | Task 10 |
| Threshold filter | Task 12 |
| FastAPI /chat, /ingest, /health, /reindex | Task 12 + 13 |
| asyncio.Semaphore concurrencia | Task 12 |
| Cache con TTL | Task 11 |
| PowerShell FileSystemWatcher | Task 14 |
| Ingesta incremental (no full reindex) | Task 7 + 14 |
| ASP classic integration | Task 15 |
| Logging centralizado | Task 2 |
| Script de instalación | Task 14 |
| Variables de entorno | Task 1 |

**All requirements covered. No gaps.**
