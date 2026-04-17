from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
    )

    # Ollama
    ollama_base_url: str = "http://localhost:11434"
    ollama_model: str = "qwen3:4b"
    ollama_timeout: int = 120
    ollama_keep_alive: str = "20m"
    ollama_num_predict: int = 384
    ollama_temperature_rag: float = 0.1
    ollama_temperature_chat: float = 0.6
    system_profile: str = "medio"
    llm_profile: str = "balanced"
    use_gpu: bool = False
    gpu_backend: str = "none"

    # Embeddings
    embedding_provider: str = "sentence-transformers"
    embedding_model: str = "sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2"
    embedding_profile: str = "balanced"
    embedding_batch_size: int = 32

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
    tesseract_cmd: str = "tesseract"
    tesseract_lang: str = "spa+eng"
    ocr_backend: str = "tesseract"

    # Poppler (for pdf2image) — set to None to use PATH
    poppler_path: str = ""

    # Logging
    log_level: str = "INFO"
    log_dir: str = "./logs"
    prompt_for_updates: bool = True
    install_quality_extras: bool = False


settings = Settings()
