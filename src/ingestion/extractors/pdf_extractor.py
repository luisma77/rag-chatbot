from pathlib import Path

import pdfplumber
import pytesseract
from pdf2image import convert_from_path
from PIL import Image

from src.config import settings
from src.logger import get_logger

logger = get_logger(__name__)

pytesseract.pytesseract.tesseract_cmd = settings.tesseract_cmd

# Poppler path for pdf2image (None = rely on system PATH)
_POPPLER_PATH = settings.poppler_path if settings.poppler_path else None

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
        total_pages = len(pdf.pages)
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
                        logger.debug(f"Página {page_num}/{total_pages}: vacía, omitida")
                        continue
                    logger.debug(
                        f"Página {page_num}/{total_pages}: OCR completo ({len(page_text)} chars)"
                    )
                except Exception as exc:
                    logger.error(f"Error OCR página {page_num} de '{file_path}': {exc}")
                    continue

            if page_text.strip():
                pages_text.append(f"[Página {page_num}]\n{page_text.strip()}")

    result = "\n\n".join(pages_text)
    logger.debug(f"PDF '{file_path}': {total_pages} páginas → {len(result)} chars")
    return result


def _ocr_full_page(pdf_path: str, page_num: int) -> str:
    """Render a single PDF page to image and run OCR on it."""
    images = convert_from_path(
        pdf_path,
        first_page=page_num,
        last_page=page_num,
        dpi=_OCR_DPI,
        poppler_path=_POPPLER_PATH,
    )
    if not images:
        return ""
    return pytesseract.image_to_string(images[0], lang=settings.tesseract_lang)


def _ocr_embedded_images(pdf_path: str, page_num: int, images: list) -> list:
    """OCR only the regions of a page that contain embedded images.

    Uses pdf2image to render the full page, then crops each image region.
    pdfplumber coordinates: 'top'/'bottom' are from page top (already flipped).
    Scale from points (72pt/inch) to pixels at 150 dpi.
    """
    rendered = convert_from_path(
        pdf_path,
        first_page=page_num,
        last_page=page_num,
        dpi=150,
        poppler_path=_POPPLER_PATH,
    )
    if not rendered:
        return []

    page_img = rendered[0]
    page_w_px, page_h_px = page_img.size
    scale = 150 / 72  # points → pixels

    ocr_texts = []
    for img_info in images:
        try:
            x0 = int(img_info["x0"] * scale)
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
