def test_default_values():
    from src.config import settings
    assert settings.ollama_model == "qwen2.5:3b"
    assert settings.top_k == 5
    assert settings.similarity_threshold == 0.55
    assert settings.max_concurrent_llm == 3
    assert settings.chunk_size == 800
    assert settings.chunk_overlap == 100


def test_api_port_default():
    from src.config import settings
    assert settings.api_port == 8000
