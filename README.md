# RAG Chatbot Empresarial

![Python](https://img.shields.io/badge/Python-3.10%2B-blue?logo=python)
![FastAPI](https://img.shields.io/badge/FastAPI-0.115-green?logo=fastapi)
![ChromaDB](https://img.shields.io/badge/ChromaDB-1.0-orange)
![Ollama](https://img.shields.io/badge/Ollama-local_LLM-purple)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue?logo=powershell)
![macOS](https://img.shields.io/badge/macOS-Intel%20%2F%20Silicon-lightgrey?logo=apple)
![License](https://img.shields.io/badge/license-MIT-yellow)

---

🌐 **Idioma / Language:** [🇪🇸 Español](README.md) · [🇬🇧 English](README.en.md)

---

Chatbot local de consulta documental basado en **RAG** (Retrieval-Augmented Generation). Indexa documentos PDF, Word, Excel, PowerPoint e imágenes y responde preguntas en lenguaje natural usando un modelo LLM que corre 100 % en local, sin enviar datos a ningún servicio externo.

---

## 🧭 Perfiles del proyecto

- `SISTEMA-BAJO` — 16 GB RAM, CPU media/modesta, sin GPU
- `SISTEMA-MEDIO` — 32 GB RAM, CPU media, sin GPU
- `SISTEMA-ALTO` — 32 GB o más, GPU potente y CPU de gama alta

Los launchers del raíz (`run-install.*`, `run-chatbot.*`) mantienen compatibilidad y redirigen por defecto a `SISTEMA-MEDIO`.

---

## ✨ Características

- **100 % local** — sin APIs externas, sin envío de datos
- **Multilingüe** — embeddings `paraphrase-multilingual-MiniLM-L12-v2` (español, inglés y más)
- **Multi-formato** — PDF (texto + OCR), DOCX, PPTX, XLSX, TXT, MD, imágenes
- **Auto-indexación** — detecta documentos nuevos/modificados y reindexea solo lo que cambia
- **Watcher automático** — para el servidor, reindexea y lo reinicia sin intervención manual
- **Interfaz gráfica** — chat web oscuro en `http://localhost:8000/static/chat.html`
- **API REST** — endpoints documentados en `http://localhost:8000/docs`
- **Respuestas conversacionales** — responde saludos y preguntas generales, no solo documentales
- **Caché de respuestas** — respuestas repetidas en milisegundos

---

## 🖥️ Prerequisitos — Links de descarga

| Herramienta | Versión mínima | Descarga directa | Instalación rápida |
|-------------|---------------|------------------|--------------------|
| **Git** | 2.x | [git-scm.com/downloads](https://git-scm.com/downloads) | `winget install Git.Git` |
| **Python** | 3.10 – 3.14 | [python.org/downloads](https://www.python.org/downloads/) | `winget install Python.Python.3.12` |
| **PowerShell 7** | 7.x (opcional*) | [github.com/PowerShell/PowerShell/releases](https://github.com/PowerShell/PowerShell/releases/latest) | `winget install Microsoft.PowerShell` |
| **Ollama** | 0.6+ | [ollama.com/download](https://ollama.com/download) | ver sección instalación |
| **Modelo LLM** | qwen2.5:3b | — | `ollama pull qwen2.5:3b` |
| **Poppler** | 24.x | [github.com/oschwartz10612/poppler-windows/releases](https://github.com/oschwartz10612/poppler-windows/releases/latest) (Windows) · `brew install poppler` (Mac) | ver sección instalación |
| **Tesseract OCR** | 5.x | [github.com/UB-Mannheim/tesseract/wiki](https://github.com/UB-Mannheim/tesseract/wiki) (Windows) · `brew install tesseract` (Mac) | `winget install UB-Mannheim.TesseractOCR` |
| **Homebrew** | cualquiera (solo Mac) | [brew.sh](https://brew.sh) | `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"` |

> *PowerShell 7 es **opcional en Windows** — los scripts también funcionan con PowerShell 5.1 (incluido en Windows). Si tienes PS7, se usará automáticamente.

---

## 📁 Estructura del proyecto

```
rag-chatbot/
│
├── 🪟  run-chatbot.bat           ← Wrapper raíz → SISTEMA-MEDIO
├── 🪟  run-install.bat           ← Wrapper raíz → SISTEMA-MEDIO
├── 🐧  run-chatbot.sh            ← Wrapper raíz → SISTEMA-MEDIO
├── 🐧  run-install.sh            ← Wrapper raíz → SISTEMA-MEDIO
├── 🍎  run-install-mac.sh        ← Wrapper raíz → SISTEMA-MEDIO
├── 🍎  run-chatbot-mac.sh        ← Wrapper raíz → SISTEMA-MEDIO
│
├── SISTEMA-BAJO/                 ← Perfil 16 GB RAM, sin GPU
├── SISTEMA-MEDIO/                ← Perfil por defecto y compatibilidad
├── SISTEMA-ALTO/                 ← Perfil 32 GB+ con GPU potente
│
├── common/                       ← env, manifests, requirements y scripts comunes
├── scripts-windows/              ← Wrappers legacy → SISTEMA-MEDIO
├── scripts-linux/                ← Wrappers legacy → SISTEMA-MEDIO
├── scripts-mac/                  ← Wrappers legacy → SISTEMA-MEDIO
│
├── scripts/                      ← Compartido — ambas plataformas
│   └── reindex_helper.py         ← Reindexado limpio (Python puro)
│
├── src/                          ← Backend compartido para todos los perfiles
├── docs/                         ← Diseño, arquitectura y migración
├── data/documents/               ← Pon aquí tus PDFs, DOCXs, etc.
├── chroma_db/                    ← Base vectorial (auto-generada)
├── logs/                         ← Logs del sistema (auto-generados)
└── install-state/                ← Estado de instalación por perfil/SO
```

---

## 🚀 Instalación desde cero

### Paso 0 — Instalar Git (si no lo tienes)

Necesitas Git para clonar el repositorio.

> **¿Ya tienes Git?** Compruébalo con `git --version` en tu terminal. Si responde con una versión, salta al Paso 1.

| Sistema | Instalación |
|---------|-------------|
| **Windows** | Descarga el instalador: **[git-scm.com/download/win](https://git-scm.com/download/win)** — o por terminal: `winget install Git.Git` |
| **Linux (Ubuntu/Debian)** | `sudo apt install git` |
| **Linux (Fedora/RHEL)** | `sudo dnf install git` |

### Paso 1 — Clonar el repositorio

```bash
git clone https://github.com/luisma77/rag-chatbot.git
cd rag-chatbot
```

---

## 🪟 Instalación en Windows

> Los scripts funcionan con **PowerShell 5.1** (incluido en Windows) y también con **PowerShell 7**. Los lanzadores `.bat` detectan automáticamente qué versión tienes.

### Paso 2W — Instalar todo automáticamente

**Doble clic en `run-install.bat`** — solicita permisos de administrador automáticamente, o desde terminal ya elevado:

```powershell
pwsh -ExecutionPolicy Bypass -File scripts-windows\install.ps1
```

> ⚠️ **Requiere administrador** — el instalador lo solicita solo al hacer doble clic. Si se ejecuta sin admin, se relanza automáticamente con elevación.

Instala automáticamente **para todo el sistema** (todos los usuarios):
- Python 3.12 (descarga directa si no está — funciona con y sin `winget`)
- PowerShell 7 (si no está instalado)
- pip packages de `requirements.txt`
- Ollama + modelo `qwen2.5:3b` (~2 GB)
- Poppler en `C:\poppler\Library\bin`
- Tesseract OCR + paquetes ESP + ENG
- **Todas las rutas añadidas al PATH del sistema** (no solo del usuario)

> 💾 **Descargas directas** (si no tienes winget):
> - Python: [python.org/downloads](https://www.python.org/downloads/)
> - PowerShell 7 (opcional): [github.com/PowerShell/PowerShell/releases](https://github.com/PowerShell/PowerShell/releases/latest)
> - Ollama: [ollama.com/download](https://ollama.com/download)
> - Poppler: [github.com/oschwartz10612/poppler-windows/releases](https://github.com/oschwartz10612/poppler-windows/releases/latest)
> - Tesseract: [github.com/UB-Mannheim/tesseract/wiki](https://github.com/UB-Mannheim/tesseract/wiki)

### Paso 3W — Verificar dependencias (opcional)

```powershell
pwsh -ExecutionPolicy Bypass -File scripts-windows\check-requirements.ps1
```

### Paso 4W — Añadir documentos y arrancar

```
data/documents/   ← copia aquí tus PDFs, DOCXs, etc.
```

**Doble clic en `run-chatbot.bat`**, o:

```powershell
pwsh -ExecutionPolicy Bypass -File scripts-windows\watch-and-serve.ps1
```

El script arranca Ollama, indexa los documentos, inicia FastAPI y abre el navegador automáticamente. Queda vigilando `data/documents/` — cualquier cambio dispara reindexación automática.

---

## 🐧 Instalación en Linux (Ubuntu / Debian)

### Paso 2L — Instalar todo automáticamente

```bash
bash run-install.sh
```

Instala automáticamente (vía `apt` y `curl`):
- Python 3 + pip
- Python packages (`requirements.txt`)
- Ollama + modelo `qwen2.5:3b` (~2 GB)
- Tesseract OCR + paquetes spa + eng
- Poppler (`poppler-utils`)
- inotify-tools (watcher de documentos)

> En otras distros (Fedora, Arch...) instala las dependencias del sistema manualmente con su gestor de paquetes (`dnf`, `pacman`, etc.) y ejecuta `bash scripts-linux/install.sh`.

### Paso 3L — Verificar dependencias (opcional)

```bash
bash scripts-linux/check-requirements.sh
```

### Paso 4L — Añadir documentos y arrancar

```
data/documents/   ← copia aquí tus PDFs, DOCXs, etc.
```

```bash
bash run-chatbot.sh
```

El script arranca Ollama, indexa los documentos, inicia FastAPI y abre el navegador. Vigila `data/documents/` con `inotifywait` — los cambios disparan reindexación automática.

---

## 🍎 Instalación en macOS

### Paso 2M — Instalar todo automáticamente

```bash
bash run-install-mac.sh
```

Instala automáticamente vía Homebrew:
- Homebrew (si no está instalado)
- Python 3 + pip
- Python packages (`requirements.txt`)
- Ollama + modelo `qwen2.5:3b` (~2 GB)
- Tesseract OCR + paquetes de idioma
- Poppler (pdf2image)
- fswatch (watcher de documentos)

> 💾 **Homebrew** es el gestor de paquetes de macOS. Si no lo tienes: [brew.sh](https://brew.sh)
> Compatible con **Intel Mac** y **Apple Silicon (M1/M2/M3/M4)**.

### Paso 3M — Verificar dependencias (opcional)

```bash
bash scripts-mac/check-requirements.sh
```

### Paso 4M — Añadir documentos y arrancar

```
data/documents/   ← copia aquí tus PDFs, DOCXs, etc.
```

```bash
bash run-chatbot-mac.sh
```

El script arranca Ollama, indexa los documentos, inicia FastAPI y abre Safari/Chrome automáticamente. Vigila `data/documents/` con `fswatch`.

---

## 📄 Formatos de documento soportados

`.pdf` · `.docx` · `.pptx` · `.xlsx` · `.txt` · `.md` · `.html` · `.jpg` · `.png` · `.tiff`

---

## 💬 Usar el chat

Abre el navegador en:

```
http://localhost:8000/static/chat.html
```

O usa la API directamente:

```bash
curl -X POST http://localhost:8000/chat \
  -H "Content-Type: application/json" \
  -d '{"question": "¿Cuál es la condiciones de teletrabajo?"}'
```

---

## 🔧 Scripts disponibles

### Lanzadores principales

| Script | Sistema | Descripción |
|--------|---------|-------------|
| `run-chatbot.bat` | 🪟 Windows | Arranca el chatbot — doble clic |
| `run-install.bat` | 🪟 Windows | Instala todas las dependencias — doble clic |
| `run-chatbot.sh` | 🐧 Linux | Arranca el chatbot — `bash run-chatbot.sh` |
| `run-install.sh` | 🐧 Linux | Instala todas las dependencias — `bash run-install.sh` |
| `run-chatbot-mac.sh` | 🍎 macOS | Arranca el chatbot — `bash run-chatbot-mac.sh` |
| `run-install-mac.sh` | 🍎 macOS | Instala todas las dependencias — `bash run-install-mac.sh` |

### Scripts Windows (`scripts-windows/`)

```powershell
# Instalar todo
pwsh -ExecutionPolicy Bypass -File scripts-windows\install.ps1

# Watcher + servidor (arranque manual)
pwsh -ExecutionPolicy Bypass -File scripts-windows\watch-and-serve.ps1

# Verificar dependencias (e instalar lo que falte)
pwsh -ExecutionPolicy Bypass -File scripts-windows\check-requirements.ps1

# Gestionar variables PATH (Ollama, Poppler, Tesseract)
pwsh -ExecutionPolicy Bypass -File scripts-windows\setup-path.ps1 -DryRun   # simular
pwsh -ExecutionPolicy Bypass -File scripts-windows\setup-path.ps1            # aplicar
```

### Scripts Linux (`scripts-linux/`)

```bash
# Instalar todo
bash scripts-linux/install.sh

# Watcher + servidor (arranque manual)
bash scripts-linux/watch-and-serve.sh

# Verificar dependencias
bash scripts-linux/check-requirements.sh
```

### Scripts macOS (`scripts-mac/`)

```bash
# Instalar todo
bash scripts-mac/install.sh

# Watcher + servidor
bash scripts-mac/watch-and-serve.sh

# Verificar dependencias
bash scripts-mac/check-requirements.sh
```

### Script compartido (`scripts/`)

```bash
# Reindexar todos los documentos (salida limpia, ambas plataformas)
python scripts/reindex_helper.py

# Reindexar un archivo concreto
python scripts/reindex_helper.py "data/documents/mi_doc.pdf" created
```

---

## ⚙️ Configuración (`.env`)

```env
# ── Modelo LLM ─────────────────────────────────────────────────
OLLAMA_MODEL=qwen2.5:3b
OLLAMA_BASE_URL=http://localhost:11434
OLLAMA_TIMEOUT=120

# ── Embeddings ──────────────────────────────────────────────────
EMBEDDING_MODEL=paraphrase-multilingual-MiniLM-L12-v2

# ── Base vectorial ──────────────────────────────────────────────
CHROMA_PERSIST_DIR=./chroma_db
CHROMA_COLLECTION=documents

# ── Documentos ──────────────────────────────────────────────────
DOCUMENTS_DIR=./data/documents

# ── Búsqueda semántica ──────────────────────────────────────────
TOP_K=5
SIMILARITY_THRESHOLD=0.55

# ── Rutas del sistema (Windows) ─────────────────────────────────
POPPLER_PATH=C:\poppler\Library\bin
TESSERACT_CMD=C:\Program Files\Tesseract-OCR\tesseract.exe

# ── API ─────────────────────────────────────────────────────────
API_PORT=8000

# ── Seguridad (opcional) ────────────────────────────────────────
# Dejar vacío para no requerir autenticación (uso local / red privada)
API_KEY=

# Orígenes CORS permitidos — separados por comas
# Usa * para permitir todo (no recomendado en producción)
ALLOWED_ORIGINS=*
```

> 💡 **`API_KEY` vacío = sin autenticación.** Ideal para uso en local o red interna.
> Si defines una clave, todos los clientes deben enviar el header `X-API-Key: <clave>`.
> Ver sección [🔐 Autenticación por API Key](#-autenticación-por-api-key) para más detalles.

---

## 🔄 Flujo de indexación

```
data/documents/
    ↓
Extractor (PDF/DOCX/imagen...)
    ↓
Limpieza + Chunking (512 tokens, overlap 50)
    ↓
Embeddings (paraphrase-multilingual-MiniLM-L12-v2, 384 dim)
    ↓
ChromaDB (cosine similarity, persistente en ./chroma_db/)
```

**Detección de cambios** — cada chunk almacena el `mtime` (fecha de modificación) del archivo. Al arrancar, `process_all()` compara el `mtime` guardado con el actual y salta los archivos sin cambios. Solo se reindexan archivos nuevos o modificados.

---

## 🧪 Tests

```bash
# Ejecutar todos los tests
python -m pytest tests/ -v

# Con cobertura
python -m pytest tests/ --cov=src --cov-report=term-missing
```

52 tests, 0 fallos. Cobertura de API, pipeline, embeddings, vectordb y config.

---

## 🛠️ Instalación manual de herramientas del sistema

### 🪟 Windows — manual

<details>
<summary>Ollama (portable, sin instalador)</summary>

```powershell
Invoke-WebRequest https://ollama.ai/download/ollama-windows-amd64.zip -OutFile ollama.zip
Expand-Archive ollama.zip C:\ollama -Force
Remove-Item ollama.zip
[System.Environment]::SetEnvironmentVariable("Path",
    [System.Environment]::GetEnvironmentVariable("Path","User") + ";C:\ollama", "User")
ollama serve   # en otra terminal
ollama pull qwen2.5:3b
```
</details>

<details>
<summary>Poppler (PDF → imagen)</summary>

```powershell
$url = "https://github.com/oschwartz10612/poppler-windows/releases/download/v24.08.0-0/Release-24.08.0-0.zip"
Invoke-WebRequest $url -OutFile poppler.zip
Expand-Archive poppler.zip C:\poppler_tmp -Force
Move-Item C:\poppler_tmp\Release-* C:\poppler
Remove-Item poppler.zip, C:\poppler_tmp -Recurse
[System.Environment]::SetEnvironmentVariable("Path",
    [System.Environment]::GetEnvironmentVariable("Path","User") + ";C:\poppler\Library\bin", "User")
```
</details>

<details>
<summary>Tesseract OCR</summary>

```powershell
winget install UB-Mannheim.TesseractOCR --accept-source-agreements
# Añadir al PATH si no se hace automáticamente:
[System.Environment]::SetEnvironmentVariable("Path",
    [System.Environment]::GetEnvironmentVariable("Path","User") + ";C:\Program Files\Tesseract-OCR", "User")
```
</details>

<details>
<summary>PowerShell 7</summary>

```powershell
winget install Microsoft.PowerShell --accept-source-agreements
# Tras instalar, usa 'pwsh' en lugar de 'powershell'
```
</details>

### 🐧 Linux — manual

<details>
<summary>Ollama</summary>

```bash
curl -fsSL https://ollama.com/install.sh | sh
ollama serve &   # en segundo plano
ollama pull qwen2.5:3b
```
</details>

<details>
<summary>Tesseract OCR (Ubuntu/Debian)</summary>

```bash
sudo apt install tesseract-ocr tesseract-ocr-spa tesseract-ocr-eng
```
</details>

<details>
<summary>Poppler (Ubuntu/Debian)</summary>

```bash
sudo apt install poppler-utils
```
</details>

<details>
<summary>inotify-tools (watcher de documentos)</summary>

```bash
sudo apt install inotify-tools
```
</details>

<details>
<summary>Python 3.10+ (si no está instalado)</summary>

```bash
sudo apt install python3 python3-pip python3-venv
```
</details>

### 🍎 macOS — manual

<details>
<summary>Homebrew (gestor de paquetes)</summary>

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```
Descarga web: [brew.sh](https://brew.sh)
</details>

<details>
<summary>Ollama</summary>

```bash
brew install ollama
ollama serve &
ollama pull qwen2.5:3b
```
O descarga el instalador gráfico: [ollama.com/download](https://ollama.com/download)
</details>

<details>
<summary>Tesseract OCR</summary>

```bash
brew install tesseract tesseract-lang
```
</details>

<details>
<summary>Poppler</summary>

```bash
brew install poppler
```
</details>

<details>
<summary>Python 3</summary>

```bash
brew install python3
```
O descarga: [python.org/downloads](https://www.python.org/downloads/)
</details>

---

## 🗂️ Añadir conocimiento al bot

**Vía documentos** (recomendado): copia cualquier archivo a `data/documents/`. El watcher lo detectará y reindexará automáticamente.

**Vía sistema de conocimiento base**: edita la constante `SYSTEM_PERSONA` en `src/llm/prompt_builder.py` para añadir hechos que el bot siempre debe conocer (nombre de la empresa, códigos internos, etc.) sin depender de documentos.

```python
# src/llm/prompt_builder.py
SYSTEM_PERSONA = """Eres el asistente virtual de Mi Empresa S.L.
...
CONOCIMIENTO BASE:
- TELETRABAJO: La empresa sólo ofrece 1 día de teletrabajo entre martes, miércoles o jueves.
- ...
"""
```

---

## 📚 API Reference

Documentación interactiva completa en `http://localhost:8000/docs`

| Endpoint | Método | Descripción |
|----------|--------|-------------|
| `/chat` | POST | Pregunta al chatbot (con historial de sesión) |
| `/ingest` | POST | Reindexar todos los documentos |
| `/ingest/file` | POST | Indexar un archivo concreto |
| `/health` | GET | Estado del sistema (Ollama + ChromaDB) |
| `/stats` | GET | Número de vectores en ChromaDB |
| `/reindex` | POST | Borrar colección y reindexar desde cero |
| `/static/chat.html` | GET | Interfaz web del chat |

---

## 🔐 Autenticación por API Key

Por defecto el chatbot **no requiere autenticación** — ideal para uso local o red interna de confianza.

Si quieres proteger el endpoint (por ejemplo al exponerlo entre dos servidores), activa la clave en `.env`:

```env
API_KEY=mi_clave_secreta_muy_larga
ALLOWED_ORIGINS=https://intranet.tuempresa.com
```

A partir de ese momento **todas las llamadas** deben incluir el header:

```http
X-API-Key: mi_clave_secreta_muy_larga
```

### Ejemplo con curl

```bash
curl -X POST http://TU_SERVIDOR:8000/chat \
  -H "Content-Type: application/json" \
  -H "X-API-Key: mi_clave_secreta_muy_larga" \
  -d '{"question": "¿Cuál es la política de vacaciones?", "session_id": "test"}'
```

### Ejemplo con PowerShell

```powershell
$headers = @{
    "Content-Type" = "application/json"
    "X-API-Key"    = "mi_clave_secreta_muy_larga"
}
$body = '{"question":"hola","session_id":"test"}'
Invoke-RestMethod -Uri "http://TU_SERVIDOR:8000/chat" -Method POST -Headers $headers -Body $body
```

| Estado | Comportamiento |
|--------|----------------|
| `API_KEY` vacío | Sin autenticación — cualquier cliente puede llamar |
| `API_KEY` definida | Se exige el header `X-API-Key` — error `401` si falta o es incorrecta |

---

## 🔗 Integrar el chatbot en otra aplicación

El chatbot expone una **API REST estándar**. Cualquier lenguaje o plataforma que pueda hacer una petición HTTP POST puede integrarse.

```
Tu aplicación web  ──POST /chat──▶  RAG Chatbot  ──▶  Ollama + ChromaDB
```

### Petición

```json
POST /chat
Content-Type: application/json

{
  "question": "¿Cuál es el proceso de baja médica?",
  "session_id": "usuario-123"
}
```

> `session_id` es opcional pero **recomendado** — permite al bot recordar el contexto de la conversación (últimos 8 turnos por sesión).

### Respuesta

```json
{
  "answer": "Según el manual de empleados, el proceso de baja médica...",
  "sources": [
    { "file": "manual_empleados.pdf", "score": 0.91 }
  ],
  "confidence": "high",
  "cached": false,
  "response_time_ms": 4230
}
```

| Campo | Descripción |
|-------|-------------|
| `answer` | Texto de respuesta del asistente |
| `sources` | Documentos usados (solo cuando `confidence = "high"`) |
| `confidence` | `"high"` / `"low"` / `"none"` |
| `cached` | `true` si la respuesta viene de caché |
| `response_time_ms` | Tiempo de respuesta en milisegundos |

---

## 🏢 Integración en dos servidores (Intranet empresarial)

Esta arquitectura permite incrustar el chatbot en una **intranet o aplicación web existente** sin exponer el motor de IA a internet.

```
┌──────────────────────────────────────────────────────────────┐
│  NAVEGADOR DEL USUARIO (empleado)                            │
└─────────────────────────┬────────────────────────────────────┘
                          │ HTTPS · Puerto 443
┌─────────────────────────▼────────────────────────────────────┐
│  SERVIDOR B — Tu intranet / aplicación web existente         │
│                                                              │
│  • Solo se modifica UN archivo (el proxy)                    │
│  • El resto de tu aplicación NO cambia                       │
│  • El proxy llama al chatbot por la red interna              │
└─────────────────────────┬────────────────────────────────────┘
                          │ HTTP · Puerto 8000 (red interna)
┌─────────────────────────▼────────────────────────────────────┐
│  SERVIDOR A — RAG Chatbot                                    │
│  Python + FastAPI + ChromaDB + Ollama                        │
│  ⚠️  NUNCA expuesto a internet — solo acepta al Servidor B   │
└──────────────────────────────────────────────────────────────┘
```

### ¿Qué cambia en tu aplicación?

**Nada.** Solo añades/sustituyes un archivo proxy en Servidor B. Tu frontend existente (JS, HTML) sigue igual.

### Ejemplos disponibles

| Plataforma | Estado | Directorio |
|------------|--------|------------|
| **ASP Classic (VBScript)** | ✅ Listo | [`examples/asp-integration/`](examples/asp-integration/) |
| PHP | 🔜 Próximamente | — |
| HTML + JS puro | 🔜 Próximamente | — |
| ASP.NET (C#) | 🔜 Próximamente | — |
| Node.js / Express | 🔜 Próximamente | — |

---

### 📄 Ejemplo: ASP Classic (IIS)

> **Caso de uso**: intranet corporativa en IIS con páginas `.asp`. El chatbot corre en otra máquina de la red interna.

**Tutorial completo → [`examples/asp-integration/README.md`](examples/asp-integration/README.md)**

#### Resumen en 3 pasos

**① Servidor A** — Instala y arranca el chatbot:

```powershell
git clone https://github.com/luisma77/rag-chatbot.git
cd rag-chatbot
.\run-install.bat          # instala todo
.\run-chatbot.bat          # arranca y queda escuchando en :8000
```

Abre el puerto 8000 solo para la IP de Servidor B:

```powershell
# Ejecutar como Administrador en Servidor A
New-NetFirewallRule `
    -DisplayName "RAG Chatbot - Servidor B" `
    -Direction Inbound -Protocol TCP -LocalPort 8000 `
    -RemoteAddress "172.18.X.X" -Action Allow   # IP de tu Servidor B
```

**② Servidor B** — Copia el proxy ASP:

```
examples/asp-integration/chat_api.ASP
    └─▶ copiar a tu ruta ASP en IIS
         ej: C:\Inetpub\wwwroot\intranet\ia\chat_api.ASP
```

Edita las dos constantes del archivo:

```vbscript
' ── Solo edita estas dos líneas ───────────────────────────────
Const CHATBOT_URL = "http://172.18.X.X:8000/chat"  ' IP de Servidor A
Const API_KEY     = ""                              ' o tu clave si la activaste
```

**③ Verifica** — desde Servidor B:

```powershell
$body = '{"question":"hola","session_id":"test"}'
Invoke-RestMethod -Uri "http://172.18.X.X:8000/chat" -Method POST `
    -Body $body -Headers @{"Content-Type"="application/json"}
# Debe responder: { "answer": "...", ... }
```

#### Puertos de referencia

| Puerto | Servidor | Uso |
|--------|----------|-----|
| `443` | B (IIS) | HTTPS público → usuarios |
| `8000` | A (FastAPI) | API del chatbot → solo desde Servidor B |
| `11434` | A (Ollama) | LLM → solo uso interno en Servidor A ⚠️ no abrir |

---

## ❓ Preguntas frecuentes

**¿Mis documentos salen de mi PC?**
No. Todo corre localmente. Ni los documentos ni las consultas salen del equipo.

**¿Qué pasa si modifico un documento?**
El watcher detecta el cambio, para el servidor, reindexea solo ese archivo y reinicia el servidor. El resto de documentos no se tocan.

**¿Puedo usar otro modelo LLM?**
Sí. Cambia `OLLAMA_MODEL` en `.env` y ejecuta `ollama pull <modelo>`. Modelos recomendados: `llama3.2:3b`, `phi3:mini`, `mistral:7b`.

**¿Funciona sin Tesseract/Poppler?**
Sí, pero los PDFs escaneados (sin capa de texto) no se podrán indexar. Los PDFs con texto sí funcionan con `pdfplumber` sin Poppler.

**¿Puedo integrarlo en mi intranet o aplicación web existente?**
Sí. El chatbot expone una API REST estándar (`POST /chat`). Solo necesitas añadir un pequeño archivo proxy en tu servidor web que haga la llamada HTTP. Ver sección [🔗 Integrar el chatbot](#-integrar-el-chatbot-en-otra-aplicación) y los ejemplos en [`examples/`](examples/).

**¿Necesito API Key para integrarlo?**
No es obligatorio. En red interna de confianza puedes dejarlo sin clave (`API_KEY=` vacío en `.env`). Si quieres seguridad extra, activa la clave y configúrala también en el archivo proxy del otro servidor.

**¿El bot recuerda la conversación?**
Sí. Cada usuario/sesión tiene su propio historial de los últimos 8 turnos. Pasa siempre el mismo `session_id` en tus peticiones para mantener el contexto.

---

## 📄 Licencia

Este proyecto está bajo la licencia **MIT** — libre para uso personal, comercial y modificación, siempre que se mantenga el aviso de copyright.

Ver el archivo [LICENSE](LICENSE) para el texto completo.

MIT © 2026 — Contribuciones bienvenidas via Pull Request.

