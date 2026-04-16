# RAG Chatbot Empresarial — Design Document
**Fecha:** 2026-04-15  
**Estado:** Aprobado  
**Autor:** Diseño colaborativo vía brainstorming

---

## 1. Qué se ha construido

Un chatbot empresarial basado en RAG (Retrieval-Augmented Generation) que:

- Responde preguntas en lenguaje natural basándose **exclusivamente** en documentación interna
- Soporta PDFs, imágenes (OCR), Word, PowerPoint, Excel, TXT, HTML
- Funciona en CPU sin GPU (Windows 11, 4-8 cores, 16 GB RAM)
- Expone una API REST consumida desde un frontend ASP clásico
- Vigila automáticamente la carpeta de documentos e indexa cambios incrementalmente

---

## 2. Tecnologías elegidas y justificación

### LLM: Ollama + qwen2.5:3b-instruct (Q4_K_M)

**Elegido sobre:**
- `phi3.5-mini`: Qwen2.5 tiene mejor soporte multilingüe español y entrenamiento explícito en comprensión de documentos
- `qwen2.5-7b`: Demasiado lento en CPU modesta con 20+ usuarios concurrentes (40-60s/respuesta vs 15-25s)
- `llama-cpp-python` directo: Instalación frágil en Windows; Ollama abstrae la complejidad

**Specs del modelo:**
- RAM: ~2.1 GB (Q4_K_M)
- Velocidad CPU (4-8 cores): 9-15 tokens/segundo
- Respuesta típica (~200 tokens): 15-25 segundos

### Embeddings: sentence-transformers paraphrase-multilingual-MiniLM-L12-v2

**Elegido sobre:**
- `nomic-embed-text` (vía Ollama): Principalmente inglés; peor rendimiento en español
- `text-embedding-ada-002` (OpenAI): Requiere API externa; no aceptable para datos internos
- `multilingual-e5-large`: Mejor calidad pero 4x más pesado (~2.2 GB vs 420 MB)

**Specs:**
- Dimensiones: 384
- Idiomas: 50+ (ES, EN y más)
- RAM: ~420 MB
- Velocidad: 200-500 embeddings/segundo en CPU

### Vector DB: ChromaDB

**Elegido sobre:**
- `FAISS`: Persistencia manual y frágil; sin metadata nativa
- `Qdrant`: Requiere servidor separado (Docker o binario); overkill para <500 docs
- `Weaviate`: Heavy; orientado a producción cloud

**Justificación:** Para <500 documentos (~50.000-100.000 chunks máximo), ChromaDB es trivial de usar, persiste en disco automáticamente, soporta filtrado por metadata, y es Python-nativo sin dependencias externas.

### Backend: FastAPI (Python 3.11)

**Elegido sobre:**
- `Express (Node)`: El ecosistema ML/NLP es Python; mezclar stacks añade complejidad sin beneficio
- `Flask`: FastAPI tiene async nativo, validación automática con Pydantic, y documentación OpenAPI automática
- `Django`: Demasiado heavy para una API de propósito específico

### Document Processing

| Formato | Librería | Motivo |
|---|---|---|
| PDF texto nativo | pdfplumber | Mejor manejo de layouts complejos, tablas, columnas |
| PDF escaneado / imágenes embebidas | pytesseract + Tesseract-OCR | OCR open source maduro, soporte ES+EN |
| DOCX | python-docx | Estándar de facto |
| PPTX | python-pptx | Soporte nativo sin conversión |
| XLSX | openpyxl | Extracción de texto de celdas |
| HTML | BeautifulSoup4 | Limpieza de markup, extracción semántica |
| TXT/MD | Python nativo | Auto-detect encoding (UTF-8, Latin-1, Windows-1252) |
| Imágenes (PNG, JPG, TIFF) | pytesseract | OCR directo |

**Nota:** `.doc` (Word 97-2003) no está soportado nativamente. Los usuarios deben convertir a `.docx`.

---

## 3. Alternativas que se podrían usar

| Componente | Alternativa | Cuándo usarla |
|---|---|---|
| LLM | `qwen2.5-7b` (Q4_K_M, ~4.8 GB) | Si el servidor mejora (16+ cores, 32 GB RAM) |
| LLM | `phi3.5-mini` | Si se prioriza velocidad sobre calidad en español |
| LLM | Claude API (cloud) | Si se acepta envío de datos a la nube |
| Embeddings | `multilingual-e5-large` | Si la calidad de búsqueda es insuficiente |
| Vector DB | `Qdrant` | Si se supera 1M de vectores o se necesita filtrado avanzado |
| Vector DB | `FAISS` | Si se quiere máxima velocidad de búsqueda en memoria |
| OCR | `EasyOCR` | Mejor en documentos con layouts muy complejos o manuscritos |
| Backend | `Express + LangChain.js` | Si el equipo prefiere JavaScript |

---

## 4. Flujo de ingesta

```
/data/documents/ (nuevo/modificado/eliminado)
        │
[1] FileSystemWatcher (PowerShell) detecta cambio
        │
[2] POST /ingest/file { path, action }
        │
[3] Detector de formato → router de extractor
        │
[4] Extracción por tipo:
    PDF texto     → pdfplumber por página
    PDF escaneado → pdf2image + pytesseract por página
    PDF mixto     → pdfplumber texto + pytesseract sobre imágenes embebidas → fusión
    DOCX/PPTX/XLSX → librería específica
    Imagen         → pytesseract directo
    TXT/HTML       → lectura directa
        │
[5] TextCleaner:
    - Normalizar espacios y saltos de línea
    - Eliminar headers/footers repetidos
    - Descartar páginas vacías (<50 chars)
        │
[6] Chunker: RecursiveCharacterTextSplitter
    chunk_size=800 | overlap=100
    Metadatos: { source_file, page_num, chunk_index, ingested_at }
        │
[7] EmbeddingGenerator → vector 384d por chunk
        │
[8] ChromaDB.upsert()
    - action=created/changed: elimina chunks previos del archivo → inserta nuevos
    - action=deleted: elimina todos los chunks del archivo
    - action=renamed: elimina nombre viejo → inserta con nombre nuevo
        │
[9] Log: "archivo.pdf: 47 chunks indexados en 12.3s"
```

---

## 5. Flujo de consulta

```
POST /chat { question: "¿Cuál es el proceso de alta de empleados?" }
        │
[1] CacheCheck: ¿pregunta idéntica respondida en <2h? → devuelve cache ⚡
        │
[2] asyncio.Semaphore(3): máximo 3 LLM calls simultáneas
    (peticiones adicionales esperan en cola)
        │
[3] EmbeddingGenerator → vector 384d de la pregunta
        │
[4] ChromaDB.query(vector, top_k=5) → chunks + similarity scores
        │
[5] ThresholdFilter: score_max >= 0.65?
    NO → respuesta inmediata "No tengo información suficiente..."
    SÍ → continúa
        │
[6] PromptBuilder → construye prompt con chunks como contexto + fuentes
        │
[7] Ollama → qwen2.5:3b-instruct (streaming activado)
        │
[8] ResponseParser → extrae respuesta + fuentes citadas
        │
[9] Cache si score_promedio >= 0.75
        │
Respuesta: { answer, sources, confidence, cached, response_time_ms }
```

---

## 6. Diseño del prompt anti-alucinación

```
SYSTEM:
Eres un asistente empresarial de consulta de documentación interna.

REGLAS ABSOLUTAS:
1. SOLO puedes responder usando la información del CONTEXTO proporcionado.
2. Si la respuesta no está en el contexto, responde EXACTAMENTE:
   "No tengo información suficiente en la documentación para responder
    esta pregunta. Consulta con el departamento correspondiente."
3. NUNCA inventes datos, fechas, nombres, cifras o procedimientos.
4. NUNCA uses conocimiento externo al contexto.
5. Cita siempre las fuentes al final de tu respuesta.

CONTEXTO RECUPERADO:
---
[Fragmento 1] (Fuente: {source_file} — Página {page})
{chunk_text}
---
...

PREGUNTA DEL USUARIO:
{question}

RESPUESTA (en español, citando fuentes al final):
```

**Capas de protección contra alucinaciones:**
1. Filtro de threshold (score < 0.65 → no llama al LLM)
2. System prompt con reglas explícitas
3. Contexto con fuentes visibles (el modelo tiende a ceñirse a lo que ve)
4. Campo `confidence` en la respuesta para alerta visual en el frontend

---

## 7. Gestión de concurrencia

Con 20+ usuarios en CPU modesta, el LLM es el único cuello de botella real.

- **asyncio.Semaphore(3):** máximo 3 queries LLM simultáneas (cada una usa ~1-2 GB RAM y 2-4 cores)
- **Cola implícita:** el `await semaphore.acquire()` de FastAPI gestiona la espera
- **Cache:** preguntas repetidas se sirven en <100ms sin tocar el LLM
- **Streaming:** la respuesta se envía token por token, mejorando UX percibida

---

## 8. Integración con ASP clásico

El servidor ASP realiza llamadas HTTP al backend FastAPI vía `MSXML2.ServerXMLHTTP` o `WinHttp.WinHttpRequest`.

```asp
' chat.asp
Dim http, response, json
Set http = Server.CreateObject("MSXML2.ServerXMLHTTP.6.0")
http.open "POST", "http://IP_SERVIDOR_IA:8000/chat", False
http.setRequestHeader "Content-Type", "application/json"
http.send "{""question"":""" & Replace(question, """", "\""") & """}"
response = http.responseText
' parsear JSON y mostrar respuesta
```

---

## 9. Qué cambiaría en producción

| Aspecto | Desarrollo actual | Producción |
|---|---|---|
| LLM | qwen2.5:3b local | qwen2.5:7b o servidor con GPU |
| Cache | Dict en memoria | Redis con persistencia |
| Queue | asyncio.Semaphore | Celery + Redis o RQ |
| Auth | Sin autenticación | API Key o token JWT |
| HTTPS | HTTP | Certificado TLS en proxy inverso (nginx) |
| Logging | Ficheros locales | ELK Stack o similar |
| Monitor | Ninguno | Prometheus + Grafana |
| Backup | Manual | Snapshot automático ChromaDB |

---

## 10. Componentes opcionales vs obligatorios

| Componente | ¿Obligatorio? | Alternativa si se elimina |
|---|---|---|
| Tesseract OCR | Opcional (si no hay imágenes/PDFs escaneados) | Ignorar esos archivos |
| pdf2image | Opcional (si todos los PDFs tienen texto nativo) | Ignorar páginas sin texto |
| python-pptx / openpyxl | Opcional | No soportar esos formatos |
| Cache en memoria | Opcional | Más lento con cargas repetidas |
| FileSystemWatcher | Opcional | Reindexado manual vía POST /reindex |
| Streaming | Opcional | Respuesta completa al final (peor UX) |
| Campo `confidence` | Opcional | No mostrar indicador visual en ASP |

---

## 11. Cómo migrar a servidores reales

1. **Servidor de IA:** Mover carpeta del proyecto, reinstalar dependencias (`pip install -r requirements.txt`), reinstalar Ollama y descargar modelo (`ollama pull qwen2.5:3b`)
2. **ChromaDB:** Copiar carpeta `chroma_db/` — es autocontenida
3. **Documentos:** Copiar `data/documents/` y ejecutar `POST /reindex` para regenerar índice en nueva máquina
4. **Variables de entorno:** Actualizar `.env` con nuevas IPs y rutas
5. **ASP:** Cambiar IP del servidor de IA en los archivos `.asp`

---

## 12. Estructura de archivos generados

```
rag-chatbot/
├── src/                    # Backend Python
├── data/documents/         # Documentos a indexar
├── chroma_db/              # Vector DB persistente
├── logs/                   # Logs de la aplicación
├── scripts/                # PowerShell: watch, install, reindex
├── asp/                    # Ejemplo integración ASP clásico
├── docs/                   # Este documento y más
├── .env.example            # Variables de entorno
└── requirements.txt        # Dependencias Python
```
