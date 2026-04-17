# RAG Enterprise Chatbot

![Python](https://img.shields.io/badge/Python-3.10%2B-blue?logo=python)
![FastAPI](https://img.shields.io/badge/FastAPI-0.115-green?logo=fastapi)
![ChromaDB](https://img.shields.io/badge/ChromaDB-local-orange)
![Ollama](https://img.shields.io/badge/Ollama-local_LLM-black)
![License](https://img.shields.io/badge/license-MIT-yellow)

---

🌐 **Language / Idioma:** [🇬🇧 English](README.en.md) · [🇪🇸 Español](README.md)

---

Local RAG chatbot for internal documentation. It indexes PDFs, Office files, text and images, stores embeddings in ChromaDB, and answers questions with a **fully local Ollama model**. The repository is organized by **hardware profile** while keeping a **single shared backend**.

## Highlights

- Shared backend in `src/`
- Three hardware profiles: `SISTEMA-BAJO`, `SISTEMA-MEDIO`, `SISTEMA-ALTO`
- Windows, Linux and macOS support
- Shared installers in `common/scripts/`
- Layered configuration in `common/env/`
- Split requirements for runtime, dev and per-profile installs
- Faster startup flow: no pip reinstall on each run
- API now returns `sources`, `confidence`, `cached`, and `response_time_ms`

## Profile matrix

| Profile | Target hardware | Chat model | Embeddings | Goal |
|---------|------------------|------------|------------|------|
| `SISTEMA-BAJO` | 16 GB RAM, modest CPU, no GPU | `qwen3:1.7b` | `sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2` | lowest latency / lowest footprint |
| `SISTEMA-MEDIO` | 24-32 GB RAM, mid CPU, no GPU | `qwen3:4b` | `sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2` | balanced speed and quality |
| `SISTEMA-ALTO` | 32 GB+ RAM, strong GPU | `qwen3:8b` | `qwen3-embedding:4b` via Ollama | highest answer quality with strong retrieval |

Root launchers still point to `SISTEMA-MEDIO` for backward compatibility.

## Quick start

### Default profile

**Windows**

```powershell
.\run-install.bat
.\run-chatbot.bat
```

**Linux**

```bash
bash run-install.sh
bash run-chatbot.sh
```

**macOS**

```bash
bash run-install-mac.sh
bash run-chatbot-mac.sh
```

### Direct profile launchers

```text
Windows: .\SISTEMA-ALTO\windows\run-install.bat
Linux:   bash SISTEMA-ALTO/linux/run-install.sh
macOS:   bash SISTEMA-ALTO/mac/run-install.sh
```

## Repository structure

```text
rag-chatbot/
├── requirements.txt
├── requirements-dev.txt
├── run-install.* / run-chatbot.* / run-uninstall.*
├── SISTEMA-BAJO/
├── SISTEMA-MEDIO/
├── SISTEMA-ALTO/
├── common/
│   ├── env/
│   ├── manifests/
│   ├── requirements/
│   └── scripts/
├── scripts/
│   └── reindex_helper.py
├── src/
├── tests/
└── docs/
```

## Requirements

| Tool | Purpose |
|------|---------|
| Python 3.10+ | backend and ingestion pipeline |
| Ollama | local chat model and high-tier embeddings |
| Tesseract OCR | OCR for images and scanned PDFs |
| Poppler | PDF rasterization for OCR |
| Platform watcher | auto-reindex on file changes |

## Config layering

Installers build `.env` from:

1. `common/env/base.env`
2. `common/env/profiles/<profile>.env`
3. `common/env/os/<system>.env`

This keeps profile changes declarative instead of duplicating application code.

## Core API

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/chat` | POST | answer user questions |
| `/ingest` | POST | index all supported documents |
| `/ingest/file` | POST | process one file event |
| `/health` | GET | health check for Ollama, embeddings and ChromaDB |
| `/stats` | GET | vector count |
| `/reindex` | POST | wipe and rebuild the collection |

Sample `/chat` response:

```json
{
  "answer": "According to the indexed document...",
  "sources": [
    { "file": "handbook.pdf", "score": 0.91 }
  ],
  "confidence": "high",
  "cached": false,
  "response_time_ms": 1480
}
```

## Development

```bash
python -m pip install -r requirements-dev.txt
python -m pytest -q
```

## Related docs

- [Spanish main README](README.md)
- [Low profile guide](SISTEMA-BAJO/README.md)
- [Medium profile guide](SISTEMA-MEDIO/README.md)
- [High profile guide](SISTEMA-ALTO/README.md)
- [Architecture notes](docs/arquitectura-perfiles-sistema.md)
- [ASP integration example](examples/asp-integration/README.md)

## License

MIT. See [LICENSE](LICENSE).
