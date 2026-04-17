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
    system_profile: str = "medium"
    llm_profile: str = "balanced"
    use_gpu: bool = False
    gpu_backend: str = "none"

    # Embeddings
    embedding_model: str = "paraphrase-multilingual-MiniLM-L12-v2"
    embedding_profile: str = "balanced"

    # ChromaDB
    chroma_persist_dir: str = "./chroma_db"
    chroma_collection: str = "documents"

    # Documents
    documents_dir: str = "./data/documents"

    # RAG
    top_k: int = 5
    similarity_threshold: float = 0.55
    cache_threshold: float = 0.75
    cache_ttl_seconds: int = 7200

    # API
    api_host: str = "0.0.0.0"
    api_port: int = 8000
    max_concurrent_llm: int = 3

    # Security — leave api_key empty to disable authentication (local/dev only)
    api_key: str = ""
    # Comma-separated allowed origins, e.g. "https://tudominio.com,https://www.tudominio.com"
    # Use "*" to allow all (not recommended in production)
    allowed_origins: str = "*"

    # Chunking
    chunk_size: int = 800
    chunk_overlap: int = 100
    ingestion_preset: str = "balanced"
    pdf_pipeline: str = "balanced"

    # Tesseract
    tesseract_cmd: str = r"C:\Program Files\Tesseract-OCR\tesseract.exe"
    tesseract_lang: str = "spa+eng"
    ocr_backend: str = "tesseract"

    # Poppler (for pdf2image) — set to None to use PATH
    poppler_path: str = r"C:\poppler\Library\bin"

    # Logging
    log_level: str = "INFO"
    log_dir: str = "./logs"
    prompt_for_updates: bool = True
    install_quality_extras: bool = False


settings = Settings()
