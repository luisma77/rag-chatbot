# RAG Enterprise Chatbot

![Python](https://img.shields.io/badge/Python-3.10%2B-blue?logo=python)
![FastAPI](https://img.shields.io/badge/FastAPI-0.115-green?logo=fastapi)
![ChromaDB](https://img.shields.io/badge/ChromaDB-1.0-orange)
![Ollama](https://img.shields.io/badge/Ollama-local_LLM-purple)
![PowerShell 5.1+](https://img.shields.io/badge/PowerShell-5.1%2B-blue?logo=powershell)
![PowerShell 7](https://img.shields.io/badge/PowerShell-7.x-blue?logo=powershell)
![macOS](https://img.shields.io/badge/macOS-Intel%20%2F%20Silicon-lightgrey?logo=apple)
![License](https://img.shields.io/badge/license-MIT-yellow)

---

🌐 **Language / Idioma:** [🇬🇧 English](README.en.md) · [🇪🇸 Español](README.md)

---

A local document-query chatbot based on **RAG** (Retrieval-Augmented Generation). It indexes PDF, Word, Excel, PowerPoint, and image files and answers questions in natural language using an LLM model that runs 100% locally — no data is sent to any external service.

---

## 🧭 Project Profiles

- `SISTEMA-BAJO` — 16 GB RAM, modest/mid CPU, no GPU
- `SISTEMA-MEDIO` — 32 GB RAM, mid CPU, no GPU
- `SISTEMA-ALTO` — 32 GB+ RAM, strong GPU and high-end CPU

Root launchers (`run-install.*`, `run-chatbot.*`) keep compatibility and redirect to `SISTEMA-MEDIO` by default.

---

## ✨ Features

- **100% local** — no external APIs, no data leaving your machine
- **Multilingual** — `paraphrase-multilingual-MiniLM-L12-v2` embeddings (Spanish, English, and more)
- **Multi-format** — PDF (text + OCR), DOCX, PPTX, XLSX, TXT, MD, images
- **Auto-indexing** — detects new/modified documents and re-indexes only what changed
- **Automatic watcher** — stops the server, re-indexes, and restarts it without manual intervention
- **Graphical interface** — dark web chat at `http://localhost:8000/static/chat.html`
- **REST API** — documented endpoints at `http://localhost:8000/docs`
- **Conversational responses** — answers greetings and general questions, not just document queries
- **Response cache** — repeated queries answered in milliseconds

---

## 🖥️ Prerequisites — Download Links

| Tool | Min version | Direct download | Quick install |
|------|------------|-----------------|---------------|
| **Git** | 2.x | [git-scm.com/downloads](https://git-scm.com/downloads) | `winget install Git.Git` |
| **Python** | 3.10–3.14 | [python.org/downloads](https://www.python.org/downloads/) | `winget install Python.Python.3.12` |
| **PowerShell 7** | 7.x (optional*) | [github.com/PowerShell/PowerShell/releases](https://github.com/PowerShell/PowerShell/releases/latest) | `winget install Microsoft.PowerShell` |
| **Ollama** | 0.6+ | [ollama.com/download](https://ollama.com/download) | see install section |
| **LLM Model** | qwen2.5:3b | — | `ollama pull qwen2.5:3b` |
| **Poppler** | 24.x | [github.com/oschwartz10612/poppler-windows/releases](https://github.com/oschwartz10612/poppler-windows/releases/latest) (Win) · `brew install poppler` (Mac) | see install section |
| **Tesseract OCR** | 5.x | [github.com/UB-Mannheim/tesseract/wiki](https://github.com/UB-Mannheim/tesseract/wiki) (Win) · `brew install tesseract` (Mac) | `winget install UB-Mannheim.TesseractOCR` |
| **Homebrew** | any (Mac only) | [brew.sh](https://brew.sh) | `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"` |

> \* PowerShell 7 (`pwsh`) is recommended for the `.ps1` scripts. However, the `.bat` launchers also work with the built-in Windows PowerShell 5.1 (`powershell`) — they will automatically call `pwsh` if available, or fall back to `powershell`.

---

## 📁 Project Structure

```
rag-chatbot/
│
├── 🪟  run-chatbot.bat           ← Root wrapper → SISTEMA-MEDIO
├── 🪟  run-install.bat           ← Root wrapper → SISTEMA-MEDIO
├── 🐧  run-chatbot.sh            ← Root wrapper → SISTEMA-MEDIO
├── 🐧  run-install.sh            ← Root wrapper → SISTEMA-MEDIO
│
├── SISTEMA-BAJO/                 ← 16 GB RAM profile, no GPU
├── SISTEMA-MEDIO/                ← Default compatibility profile
├── SISTEMA-ALTO/                 ← 32 GB+ profile with strong GPU
│
├── common/                       ← env, manifests, requirements and shared scripts
├── scripts-windows/              ← Legacy wrappers → SISTEMA-MEDIO
├── scripts-linux/                ← Legacy wrappers → SISTEMA-MEDIO
├── scripts-mac/                  ← Legacy wrappers → SISTEMA-MEDIO
├── scripts/                      ← Shared
│   └── reindex_helper.py         ← Clean re-indexer (pure Python)
│
├── src/                          ← Shared backend for all profiles
├── docs/                         ← Design, architecture and migration
├── data/documents/               ← Put your PDFs, DOCXs, etc. here
├── chroma_db/                    ← Vector database (auto-generated)
├── logs/                         ← System logs (auto-generated)
└── install-state/                ← Per-profile installation state
```

---

## 🚀 Installation from Scratch

### Step 0 — Install Git (if you don't have it)

You need Git to clone the repository.

> **Already have Git?** Check with `git --version` in your terminal. If it returns a version number, skip to Step 1.

| System | Installation |
|--------|-------------|
| **Windows** | Download the installer: **[git-scm.com/download/win](https://git-scm.com/download/win)** — or from terminal: `winget install Git.Git` |
| **macOS** | `brew install git` — or install Xcode Command Line Tools: `xcode-select --install` |
| **Linux (Ubuntu/Debian)** | `sudo apt install git` |
| **Linux (Fedora/RHEL)** | `sudo dnf install git` |

### Step 1 — Clone the Repository

```bash
git clone https://github.com/luisma77/rag-chatbot.git
cd rag-chatbot
```

---

## 🪟 Installation on Windows

> The `.bat` launchers work with both **PowerShell 5.1** (built-in on all Windows machines) and **PowerShell 7** (`pwsh`). If you want to run `.ps1` scripts directly, install PowerShell 7:
> `winget install Microsoft.PowerShell`

### Step 2W — Install Everything Automatically

**Double-click `run-install.bat`** — it requests administrator privileges automatically, or from an already-elevated terminal:

```powershell
pwsh -ExecutionPolicy Bypass -File scripts-windows\install.ps1
```

> **Requires administrator** — the installer requests elevation automatically on double-click. If run without admin rights, it relaunches itself with elevation.

Automatically installs **system-wide** (all users):
- Python 3.12 (direct download if not present — works with and without `winget`)
- PowerShell 7 (if not already installed)
- pip packages from `requirements.txt`
- Ollama + `qwen2.5:3b` model (~2 GB)
- Poppler at `C:\poppler\Library\bin`
- Tesseract OCR + ESP + ENG language packs
- **All paths added to the system PATH** (not just user PATH)

### Step 3W — Verify Dependencies (optional)

```powershell
pwsh -ExecutionPolicy Bypass -File scripts-windows\check-requirements.ps1
```

### Step 4W — Add Documents and Start

```
data/documents/   ← copy your PDFs, DOCXs, etc. here
```

**Double-click `run-chatbot.bat`**, or:

```powershell
pwsh -ExecutionPolicy Bypass -File scripts-windows\watch-and-serve.ps1
```

The script starts Ollama, indexes the documents, launches FastAPI and opens the browser automatically. It then watches `data/documents/` — any change triggers automatic re-indexing.

---

## 🍎 Installation on macOS

macOS is supported on both Intel and Apple Silicon (M1/M2/M3/M4).

### Step 2M — Install Homebrew (if not already installed)

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

After installing on Apple Silicon, add Homebrew to your PATH:

```bash
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```

### Step 3M — Install System Dependencies

```bash
# Install Python, Poppler, Tesseract OCR and inotify-equivalent (fswatch)
brew install python@3.12 poppler tesseract tesseract-lang fswatch

# Install Ollama
brew install ollama
# — or download from: https://ollama.com/download/mac
```

### Step 4M — Install Python Packages

```bash
cd rag-chatbot
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

### Step 5M — Pull the LLM Model and Start

```bash
# Start Ollama (in background or a separate terminal)
ollama serve &

# Pull the model (~2 GB)
ollama pull qwen2.5:3b

# Copy your documents
# cp /path/to/your/docs/* data/documents/

# Start the chatbot
bash run-chatbot.sh
```

> **Tip for Apple Silicon:** All dependencies install natively as arm64 binaries via Homebrew. No Rosetta required.

> **Tesseract languages:** The `tesseract-lang` Homebrew package includes many languages. If you need only specific ones, you can install them individually (e.g. `brew install tesseract-lang` includes Spanish and English by default).

---

## 🐧 Installation on Linux (Ubuntu / Debian)

### Step 2L — Install Everything Automatically

```bash
bash run-install.sh
```

Automatically installs (via `apt` and `curl`):
- Python 3 + pip
- Python packages (`requirements.txt`)
- Ollama + `qwen2.5:3b` model (~2 GB)
- Tesseract OCR + spa + eng language packs
- Poppler (`poppler-utils`)
- inotify-tools (document watcher)

> On other distros (Fedora, Arch, etc.) install system dependencies manually with your package manager (`dnf`, `pacman`, etc.) and then run `bash scripts-linux/install.sh`.

### Step 3L — Verify Dependencies (optional)

```bash
bash scripts-linux/check-requirements.sh
```

### Step 4L — Add Documents and Start

```
data/documents/   ← copy your PDFs, DOCXs, etc. here
```

```bash
bash run-chatbot.sh
```

The script starts Ollama, indexes the documents, launches FastAPI and opens the browser. It watches `data/documents/` with `inotifywait` — changes trigger automatic re-indexing.

---

## 📄 Supported Document Formats

`.pdf` · `.docx` · `.pptx` · `.xlsx` · `.txt` · `.md` · `.html` · `.jpg` · `.png` · `.tiff`

---

## 💬 Using the Chat

Open your browser at:

```
http://localhost:8000/static/chat.html
```

Or use the API directly:

```bash
curl -X POST http://localhost:8000/chat \
  -H "Content-Type: application/json" \
  -d '{"question": "What is the vacation policy?"}'
```

---

## 🔧 Available Scripts

### Main Launchers

| Script | System | Description |
|--------|--------|-------------|
| `run-chatbot.bat` | 🪟 Windows | Start the chatbot — double click |
| `run-install.bat` | 🪟 Windows | Install all dependencies — double click |
| `run-chatbot.sh` | 🐧 Linux / 🍎 macOS | Start the chatbot — `bash run-chatbot.sh` |
| `run-install.sh` | 🐧 Linux | Install all dependencies — `bash run-install.sh` |

### Windows Scripts (`scripts-windows/`)

```powershell
# Install everything
pwsh -ExecutionPolicy Bypass -File scripts-windows\install.ps1

# Watcher + server (manual start)
pwsh -ExecutionPolicy Bypass -File scripts-windows\watch-and-serve.ps1

# Verify dependencies (and install missing ones)
pwsh -ExecutionPolicy Bypass -File scripts-windows\check-requirements.ps1

# Manage PATH variables (Ollama, Poppler, Tesseract)
pwsh -ExecutionPolicy Bypass -File scripts-windows\setup-path.ps1 -DryRun   # simulate
pwsh -ExecutionPolicy Bypass -File scripts-windows\setup-path.ps1            # apply
```

> **Note:** Both PowerShell 5.1 (`powershell`) and PowerShell 7 (`pwsh`) work. The `.bat` launchers automatically detect which is available.

### Linux / macOS Scripts (`scripts-linux/`)

```bash
# Install everything
bash scripts-linux/install.sh

# Watcher + server (manual start)
bash scripts-linux/watch-and-serve.sh

# Verify dependencies
bash scripts-linux/check-requirements.sh
```

### Shared Script (`scripts/`)

```bash
# Re-index all documents (clean output, both platforms)
python scripts/reindex_helper.py

# Re-index a specific file
python scripts/reindex_helper.py "data/documents/my_doc.pdf" created
```

---

## ⚙️ Configuration (`.env`)

Copy `.env.example` to `.env` and adjust as needed:

```env
# ── LLM Model ──────────────────────────────────────────────────
OLLAMA_MODEL=qwen2.5:3b
OLLAMA_BASE_URL=http://localhost:11434
OLLAMA_TIMEOUT=120

# ── Embeddings ──────────────────────────────────────────────────
EMBEDDING_MODEL=paraphrase-multilingual-MiniLM-L12-v2

# ── Vector database ─────────────────────────────────────────────
CHROMA_PERSIST_DIR=./chroma_db
CHROMA_COLLECTION=documents

# ── Documents ───────────────────────────────────────────────────
DOCUMENTS_DIR=./data/documents

# ── Semantic search ─────────────────────────────────────────────
TOP_K=5
SIMILARITY_THRESHOLD=0.55

# ── System paths (Windows) ──────────────────────────────────────
POPPLER_PATH=C:\poppler\Library\bin
TESSERACT_CMD=C:\Program Files\Tesseract-OCR\tesseract.exe

# ── System paths (macOS — example) ──────────────────────────────
# POPPLER_PATH=/opt/homebrew/bin
# TESSERACT_CMD=/opt/homebrew/bin/tesseract

# ── API ─────────────────────────────────────────────────────────
API_PORT=8000

# ── Security (optional) ─────────────────────────────────────────
# Leave empty to require no authentication (local / private network use)
API_KEY=

# Allowed CORS origins — comma-separated
# Use * to allow everything (not recommended in production)
ALLOWED_ORIGINS=*
```

> **`API_KEY` empty = no authentication.** Ideal for local use or internal networks.
> If you define a key, all clients must send the header `X-API-Key: <key>`.
> See section [Authentication by API Key](#-api-key-authentication) for details.

---

## 🔄 Indexing Pipeline

```
data/documents/
    ↓
Extractor (PDF / DOCX / image ...)
    ↓
Cleaning + Chunking (512 tokens, overlap 50)
    ↓
Embeddings (paraphrase-multilingual-MiniLM-L12-v2, 384 dim)
    ↓
ChromaDB (cosine similarity, persisted in ./chroma_db/)
```

**Change detection** — each chunk stores the `mtime` (modification date) of its source file. At startup, `process_all()` compares the stored `mtime` with the current one and skips unchanged files. Only new or modified files are re-indexed.

---

## 🧪 Tests

```bash
# Run all tests
python -m pytest tests/ -v

# With coverage
python -m pytest tests/ --cov=src --cov-report=term-missing
```

52 tests, 0 failures. Coverage of API, pipeline, embeddings, vectordb and config.

---

## 🛠️ Manual Tool Installation

### 🪟 Windows — manual

<details>
<summary>Ollama (portable, no installer)</summary>

```powershell
Invoke-WebRequest https://ollama.ai/download/ollama-windows-amd64.zip -OutFile ollama.zip
Expand-Archive ollama.zip C:\ollama -Force
Remove-Item ollama.zip
[System.Environment]::SetEnvironmentVariable("Path",
    [System.Environment]::GetEnvironmentVariable("Path","User") + ";C:\ollama", "User")
ollama serve   # in another terminal
ollama pull qwen2.5:3b
```
</details>

<details>
<summary>Poppler (PDF → image conversion)</summary>

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
# Add to PATH if not done automatically:
[System.Environment]::SetEnvironmentVariable("Path",
    [System.Environment]::GetEnvironmentVariable("Path","User") + ";C:\Program Files\Tesseract-OCR", "User")
```
</details>

<details>
<summary>PowerShell 7</summary>

```powershell
winget install Microsoft.PowerShell --accept-source-agreements
# After installing, use 'pwsh' instead of 'powershell'
```
</details>

### 🍎 macOS — manual

<details>
<summary>Homebrew (package manager)</summary>

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Apple Silicon only — add to PATH:
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```
</details>

<details>
<summary>Ollama</summary>

```bash
# Via Homebrew
brew install ollama

# Or download the .dmg from:
# https://ollama.com/download/mac

# Start and pull the model
ollama serve &
ollama pull qwen2.5:3b
```
</details>

<details>
<summary>Poppler (PDF → image conversion)</summary>

```bash
brew install poppler
# Binary location: /opt/homebrew/bin/pdftoppm (Apple Silicon)
#                  /usr/local/bin/pdftoppm (Intel)
```
</details>

<details>
<summary>Tesseract OCR</summary>

```bash
brew install tesseract tesseract-lang
# tesseract-lang includes Spanish, English and many other languages
```
</details>

<details>
<summary>Python 3.10+ (if not installed)</summary>

```bash
brew install python@3.12
# Add to PATH if needed:
echo 'export PATH="/opt/homebrew/opt/python@3.12/bin:$PATH"' >> ~/.zprofile
```
</details>

<details>
<summary>fswatch (document watcher on macOS)</summary>

```bash
brew install fswatch
# Used by run-chatbot.sh to detect document changes
```
</details>

### 🐧 Linux — manual

<details>
<summary>Ollama</summary>

```bash
curl -fsSL https://ollama.com/install.sh | sh
ollama serve &   # in background
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
<summary>inotify-tools (document watcher)</summary>

```bash
sudo apt install inotify-tools
```
</details>

<details>
<summary>Python 3.10+ (if not installed)</summary>

```bash
sudo apt install python3 python3-pip python3-venv
```
</details>

---

## 🗂️ Adding Knowledge to the Bot

**Via documents** (recommended): copy any file to `data/documents/`. The watcher will detect it and re-index automatically.

**Via base knowledge system**: edit the `SYSTEM_PERSONA` constant in `src/llm/prompt_builder.py` to add facts the bot should always know (company name, internal codes, etc.) without relying on documents.

```python
# src/llm/prompt_builder.py
SYSTEM_PERSONA = """You are the virtual assistant of My Company Ltd.
...
BASE KNOWLEDGE:
- REMOTE WORK: The company only offers one day of working remotely between Tuesday, Wednesday, or Thursday.
- ...
"""
```

---

## 📚 API Reference

Full interactive documentation at `http://localhost:8000/docs`

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/chat` | POST | Ask the chatbot (with session history) |
| `/ingest` | POST | Re-index all documents |
| `/ingest/file` | POST | Index a specific file |
| `/health` | GET | System status (Ollama + ChromaDB) |
| `/stats` | GET | Number of vectors in ChromaDB |
| `/reindex` | POST | Drop collection and re-index from scratch |
| `/static/chat.html` | GET | Chat web interface |

---

## 🔐 API Key Authentication

By default the chatbot **requires no authentication** — ideal for local use or trusted internal networks.

If you want to protect the endpoint (for example when exposing it between two servers), activate the key in `.env`:

```env
API_KEY=my_very_long_secret_key
ALLOWED_ORIGINS=https://intranet.yourcompany.com
```

From that point on, **all calls** must include the header:

```http
X-API-Key: my_very_long_secret_key
```

### Example with curl

```bash
curl -X POST http://YOUR_SERVER:8000/chat \
  -H "Content-Type: application/json" \
  -H "X-API-Key: my_very_long_secret_key" \
  -d '{"question": "What is the vacation policy?", "session_id": "test"}'
```

### Example with PowerShell

```powershell
$headers = @{
    "Content-Type" = "application/json"
    "X-API-Key"    = "my_very_long_secret_key"
}
$body = '{"question":"hello","session_id":"test"}'
Invoke-RestMethod -Uri "http://YOUR_SERVER:8000/chat" -Method POST -Headers $headers -Body $body
```

| Status | Behavior |
|--------|----------|
| `API_KEY` empty | No authentication — any client can call |
| `API_KEY` defined | `X-API-Key` header required — `401` error if missing or wrong |

---

## 🔗 Integrating the Chatbot into Another Application

The chatbot exposes a **standard REST API**. Any language or platform that can make an HTTP POST request can integrate with it.

```
Your web application  ──POST /chat──▶  RAG Chatbot  ──▶  Ollama + ChromaDB
```

### Request

```json
POST /chat
Content-Type: application/json

{
  "question": "What is the sick leave process?",
  "session_id": "user-123"
}
```

> `session_id` is optional but **recommended** — it allows the bot to remember conversation context (last 8 turns per session).

### Response

```json
{
  "answer": "According to the employee handbook, the sick leave process...",
  "sources": [
    { "file": "employee_handbook.pdf", "score": 0.91 }
  ],
  "confidence": "high",
  "cached": false,
  "response_time_ms": 4230
}
```

| Field | Description |
|-------|-------------|
| `answer` | The assistant's response text |
| `sources` | Documents used (only when `confidence = "high"`) |
| `confidence` | `"high"` / `"low"` / `"none"` |
| `cached` | `true` if the response came from cache |
| `response_time_ms` | Response time in milliseconds |

---

## 🏢 Two-Server Integration (Corporate Intranet)

This architecture lets you embed the chatbot in an **existing intranet or web application** without exposing the AI engine to the internet.

```
┌──────────────────────────────────────────────────────────────┐
│  USER BROWSER (employee)                                     │
└─────────────────────────┬────────────────────────────────────┘
                          │ HTTPS · Port 443
┌─────────────────────────▼────────────────────────────────────┐
│  SERVER B — Your intranet / existing web application         │
│                                                              │
│  • Only ONE file is modified (the proxy)                     │
│  • The rest of your application does NOT change              │
│  • The proxy calls the chatbot over the internal network     │
└─────────────────────────┬────────────────────────────────────┘
                          │ HTTP · Port 8000 (internal network)
┌─────────────────────────▼────────────────────────────────────┐
│  SERVER A — RAG Chatbot                                      │
│  Python + FastAPI + ChromaDB + Ollama                        │
│  ⚠️  NEVER exposed to internet — only accepts Server B       │
└──────────────────────────────────────────────────────────────┘
```

### What Changes in Your Application?

**Nothing.** You only add/replace one proxy file on Server B. Your existing frontend (JS, HTML) stays the same.

### Available Examples

| Platform | Status | Directory |
|----------|--------|-----------|
| **ASP Classic (VBScript)** | Ready | [`examples/asp-integration/`](examples/asp-integration/) |
| PHP | Coming soon | — |
| HTML + plain JS | Coming soon | — |
| ASP.NET (C#) | Coming soon | — |
| Node.js / Express | Coming soon | — |

---

### ASP Classic (IIS) Example

> **Use case**: corporate intranet on IIS with `.asp` pages. The chatbot runs on another machine on the internal network.

**Full tutorial → [`examples/asp-integration/README.md`](examples/asp-integration/README.md)**

#### Summary in 3 Steps

**Server A** — Install and start the chatbot:

```powershell
git clone https://github.com/luisma77/rag-chatbot.git
cd rag-chatbot
.\run-install.bat          # install everything
.\run-chatbot.bat          # start and listen on :8000
```

Open port 8000 only for Server B's IP:

```powershell
# Run as Administrator on Server A
New-NetFirewallRule `
    -DisplayName "RAG Chatbot - Server B" `
    -Direction Inbound -Protocol TCP -LocalPort 8000 `
    -RemoteAddress "172.18.X.X" -Action Allow   # Your Server B's IP
```

**Server B** — Copy the ASP proxy:

```
examples/asp-integration/chat_api.ASP
    └─▶ copy to your ASP path on IIS
         e.g.: C:\Inetpub\wwwroot\intranet\ai\chat_api.ASP
```

Edit the two constants in the file:

```vbscript
' ── Only edit these two lines ─────────────────────────────────
Const CHATBOT_URL = "http://172.18.X.X:8000/chat"  ' Server A's IP
Const API_KEY     = ""                              ' or your key if activated
```

**Verify** — from Server B:

```powershell
$body = '{"question":"hello","session_id":"test"}'
Invoke-RestMethod -Uri "http://172.18.X.X:8000/chat" -Method POST `
    -Body $body -Headers @{"Content-Type"="application/json"}
# Should respond: { "answer": "...", ... }
```

#### Port Reference

| Port | Server | Use |
|------|--------|-----|
| `443` | B (IIS) | Public HTTPS → users |
| `8000` | A (FastAPI) | Chatbot API → from Server B only |
| `11434` | A (Ollama) | LLM → internal use on Server A only ⚠️ do not open |

---

## ❓ Frequently Asked Questions

**Does my data leave my machine?**
No. Everything runs locally. Neither documents nor queries leave the machine.

**What happens if I modify a document?**
The watcher detects the change, stops the server, re-indexes only that file and restarts the server. Other documents are not touched.

**Can I use a different LLM model?**
Yes. Change `OLLAMA_MODEL` in `.env` and run `ollama pull <model>`. Recommended models: `llama3.2:3b`, `phi3:mini`, `mistral:7b`.

**Does it work without Tesseract/Poppler?**
Yes, but scanned PDFs (without a text layer) cannot be indexed. PDFs with embedded text work fine with `pdfplumber` even without Poppler.

**Can I integrate it into my intranet or existing web application?**
Yes. The chatbot exposes a standard REST API (`POST /chat`). You only need to add a small proxy file on your web server that makes the HTTP call. See the [Integrating the Chatbot](#-integrating-the-chatbot-into-another-application) section and the examples in [`examples/`](examples/).

**Do I need an API Key to integrate it?**
Not required. On a trusted internal network you can leave it keyless (`API_KEY=` empty in `.env`). For extra security, activate the key and configure it in the proxy file on the other server.

**Does the bot remember the conversation?**
Yes. Each user/session has its own history of the last 8 turns. Always pass the same `session_id` in your requests to maintain context.

**Does it work on macOS?**
Yes, fully supported on both Intel and Apple Silicon Macs. Install dependencies via Homebrew and use `bash run-chatbot.sh` to start. See the [macOS Installation](#-installation-on-macos) section for full instructions.

**Does it work on Windows PowerShell 5.1 (the built-in one)?**
Yes. The `.bat` launchers work with both PowerShell 5.1 (built-in) and PowerShell 7. If you want to run `.ps1` scripts directly from a terminal, PowerShell 7 is recommended.

---

## 📄 License

This project is licensed under the **MIT License** — free for personal, commercial use, and modification, as long as the copyright notice is retained.

See the [LICENSE](LICENSE) file for the full text.

MIT © 2026 — Contributions welcome via Pull Request.
