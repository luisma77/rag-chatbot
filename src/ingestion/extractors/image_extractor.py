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
