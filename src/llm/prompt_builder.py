# ── System persona (facts the bot always knows) ───────────────────────────────
# Edit this block to add/update company knowledge that isn't in any document.
SYSTEM_PERSONA = """Eres un asistente virtual de consulta documental interna.

SOBRE TI:
- Función: responder preguntas sobre la documentación interna de la organización
- Idioma: responde SIEMPRE en el idioma en que te hablen
- Tono: profesional, amable y conciso

CONOCIMIENTO BASE:
- Tienes acceso a los documentos internos que se han indexado en el sistema
- Los documentos pueden incluir: manuales de empleados, políticas internas, guías de teletrabajo, procedimientos de RRHH, normativas y cualquier otro documento corporativo
- Si te preguntan quién eres: eres el asistente de consulta documental interno de la organización

COMPORTAMIENTO:
- Saludos y preguntas generales (¿quién eres?, ¿para qué sirves?, etc.): responde de forma natural y amable usando tu conocimiento base
- Preguntas sobre documentación: usa el CONTEXTO
- NUNCA inventes datos, fechas, cifras o procedimientos que no estén en el contexto o en tu conocimiento base
- Si no tienes información concreta, indícalo y sugiere contactar con el departamento correspondiente"""

_RAG_RULES = """REGLAS PARA RESPUESTA DOCUMENTAL:
1. Usa SOLO la información del CONTEXTO proporcionado
2. NUNCA inventes datos, fechas, nombres, cifras o procedimientos
3. Si el contexto no contiene la respuesta, dilo claramente"""


def _history_block(history: list[dict]) -> str:
    """Format conversation history as a readable block for the LLM."""
    if not history:
        return ""
    lines = []
    for msg in history:
        label = "Usuario" if msg["role"] == "user" else "Asistente"
        lines.append(f"{label}: {msg['content']}")
    return "\nHISTORIAL DE CONVERSACIÓN:\n" + "\n".join(lines) + "\n"


def build_prompt(question: str, chunks: list, history: list[dict] | None = None) -> str:
    """Build the RAG prompt: persona + history + retrieved chunks + question."""
    context_parts = []
    for i, chunk in enumerate(chunks, 1):
        source = chunk.get("source_file", "desconocido")
        text = chunk.get("text", "")
        context_parts.append(f"[Fragmento {i}] (Fuente: {source})\n{text}")

    context_block = "\n---\n".join(context_parts)
    hist = _history_block(history or [])

    return f"""{SYSTEM_PERSONA}

{_RAG_RULES}
{hist}
CONTEXTO RECUPERADO:
---
{context_block}
---

PREGUNTA ACTUAL:
{question}

RESPUESTA (en el mismo idioma de la pregunta):"""


def build_conversational_prompt(question: str, history: list[dict] | None = None) -> str:
    """Prompt used when no relevant document context was found."""
    hist = _history_block(history or [])
    return f"""{SYSTEM_PERSONA}

No se encontró contexto documental relevante para esta pregunta.
Responde de forma natural usando tu conocimiento base y el historial de conversación.
Si la pregunta requiere información específica de documentos que no tienes, dilo amablemente.
{hist}
PREGUNTA ACTUAL:
{question}

RESPUESTA (en el mismo idioma de la pregunta):"""
