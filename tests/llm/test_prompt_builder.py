from src.llm.prompt_builder import build_prompt, build_conversational_prompt, SYSTEM_PERSONA


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
    assert "REGLAS PARA RESPUESTA DOCUMENTAL" in prompt
    assert "NUNCA inventes" in prompt


def test_system_persona_is_defined():
    assert len(SYSTEM_PERSONA) > 50
    assert "asistente" in SYSTEM_PERSONA


def test_conversational_prompt_contains_question():
    prompt = build_conversational_prompt("Hola, ¿qué eres?")
    assert "Hola, ¿qué eres?" in prompt
    assert "SYSTEM_PERSONA" not in prompt  # should embed the value, not the name

