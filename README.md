# RAG Chatbot Empresarial

![Python](https://img.shields.io/badge/Python-3.10%2B-blue?logo=python)
![FastAPI](https://img.shields.io/badge/FastAPI-0.115-green?logo=fastapi)
![ChromaDB](https://img.shields.io/badge/ChromaDB-local-orange)
![Ollama](https://img.shields.io/badge/Ollama-local_LLM-black)
![Windows](https://img.shields.io/badge/Windows-supported-0078d4?logo=windows)
![Linux](https://img.shields.io/badge/Linux-supported-fcc624?logo=linux&logoColor=black)
![macOS](https://img.shields.io/badge/macOS-supported-lightgrey?logo=apple)
![License](https://img.shields.io/badge/license-MIT-yellow)

---

🌐 **Idioma / Language:** [🇪🇸 Español](README.md) · [🇬🇧 English](README.en.md)

---

Chatbot documental local basado en **RAG** que indexa PDFs, Office, texto e imágenes y responde con un **LLM en local mediante Ollama**, sin enviar datos a servicios externos. El proyecto está organizado por **perfil de hardware** y soporta **Windows, Linux y macOS** sin duplicar backend ni lógica de negocio.

## ✨ Qué aporta esta estructura

- **Un solo backend compartido** en `src/`
- **Tres perfiles reales**: `SISTEMA-BAJO`, `SISTEMA-MEDIO`, `SISTEMA-ALTO`
- **Instaladores compartidos por SO** en `common/scripts/`
- **Configuración declarativa por capas** en `common/env/`
- **Requirements separados** por runtime, desarrollo y perfil
- **Sin carpetas raíz duplicadas** para Linux/macOS y sin reinstalar paquetes en cada arranque
- **Mejor latencia operativa**: cliente Ollama reutilizable, `keep_alive`, caché y arranque más limpio

## 🧭 Selector rápido de perfil

| Perfil | Hardware objetivo | Modelo chat | Embeddings | Prioridad |
|--------|-------------------|-------------|------------|-----------|
| `SISTEMA-BAJO` | 16 GB RAM, CPU media/modesta, sin GPU | `qwen3:1.7b` | `sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2` | mínima latencia y consumo |
| `SISTEMA-MEDIO` | 24-32 GB RAM, CPU media, sin GPU | `qwen3:4b` | `sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2` | equilibrio entre velocidad y calidad |
| `SISTEMA-ALTO` | 32 GB+ RAM, GPU potente | `qwen3:8b` | `qwen3-embedding:4b` vía Ollama | máxima calidad manteniendo baja latencia |

> Los launchers del raíz siguen existiendo por compatibilidad y apuntan a `SISTEMA-MEDIO`.

## 🏗️ Estructura actual

```text
rag-chatbot/
├── README.md
├── README.en.md
├── requirements.txt
├── requirements-dev.txt
├── run-install.bat / .sh / -mac.sh
├── run-chatbot.bat / .sh / -mac.sh
├── run-uninstall.bat / .sh / -mac.sh
├── SISTEMA-BAJO/
├── SISTEMA-MEDIO/
├── SISTEMA-ALTO/
├── common/
│   ├── env/
│   │   ├── base.env
│   │   ├── profiles/
│   │   └── os/
│   ├── manifests/
│   ├── requirements/
│   └── scripts/
├── scripts/
│   └── reindex_helper.py
├── src/
├── tests/
├── docs/
├── data/documents/
├── chroma_db/
└── logs/
```

## 🚀 Inicio rápido

### Opción 1: usar el perfil por defecto

`SISTEMA-MEDIO` es la opción segura para la mayoría de equipos.

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

### Opción 2: instalar un perfil concreto

**Windows**

```powershell
.\SISTEMA-BAJO\windows\run-install.bat
.\SISTEMA-MEDIO\windows\run-install.bat
.\SISTEMA-ALTO\windows\run-install.bat
```

**Linux**

```bash
bash SISTEMA-BAJO/linux/run-install.sh
bash SISTEMA-MEDIO/linux/run-install.sh
bash SISTEMA-ALTO/linux/run-install.sh
```

**macOS**

```bash
bash SISTEMA-BAJO/mac/run-install.sh
bash SISTEMA-MEDIO/mac/run-install.sh
bash SISTEMA-ALTO/mac/run-install.sh
```

## 📦 Requisitos del proyecto

### Herramientas del sistema

| Herramienta | Uso | Windows | Linux | macOS |
|------------|-----|---------|-------|-------|
| Python 3.10+ | backend y pipeline | `winget install Python.Python.3.12` | `sudo apt install python3 python3-pip python3-venv` | `brew install python3` |
| Ollama | chat local y, en alto, embeddings | `winget install Ollama.Ollama` | `curl -fsSL https://ollama.com/install.sh \| sh` | `brew install ollama` |
| Tesseract OCR | OCR de imágenes y PDFs escaneados | `winget install UB-Mannheim.TesseractOCR` | `sudo apt install tesseract-ocr tesseract-ocr-spa tesseract-ocr-eng` | `brew install tesseract tesseract-lang` |
| Poppler | rasterizado PDF para OCR | descarga release | `sudo apt install poppler-utils` | `brew install poppler` |
| Watcher nativo | auto-reindex | FileSystemWatcher | `inotify-tools` | `fswatch` |

### Requirements Python

| Archivo | Propósito |
|--------|-----------|
| `requirements.txt` | runtime base común |
| `requirements-dev.txt` | runtime + tests |
| `common/requirements/profile-low.txt` | instalación perfil bajo |
| `common/requirements/profile-medium.txt` | instalación perfil medio |
| `common/requirements/profile-high.txt` | instalación perfil alto |
| `common/requirements/quality-extractors.txt` | extras de ingesta avanzada (`docling`) |

## ⚙️ Capas de configuración

La instalación genera `.env` combinando estas capas:

1. `common/env/base.env`
2. `common/env/profiles/<perfil>.env`
3. `common/env/os/<sistema>.env`

Esto permite cambiar de perfil sin tocar el backend.

### Variables clave

```env
OLLAMA_MODEL=qwen3:4b
EMBEDDING_PROVIDER=sentence-transformers
EMBEDDING_MODEL=sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2
OLLAMA_KEEP_ALIVE=20m
TOP_K=5
SIMILARITY_THRESHOLD=0.58
CHUNK_SIZE=800
CHUNK_OVERLAP=100
MAX_CONCURRENT_LLM=2
```

## 🧠 Decisiones técnicas por perfil

### `SISTEMA-BAJO`

- Mantiene OCR y extracción multi-formato, pero limita coste de inferencia.
- Usa `qwen3:1.7b` para reducir tiempo de respuesta y memoria.
- Ajusta chunking y concurrencia para CPU.
- No instala extras pesados.

### `SISTEMA-MEDIO`

- Es el perfil de referencia.
- Usa `qwen3:4b` y embeddings multilingües ligeros.
- Conserva OCR, Office y pipeline RAG completo con buena latencia.
- Es el destino de los launchers raíz.

### `SISTEMA-ALTO`

- Usa `qwen3:8b` para respuesta más rica.
- Usa `qwen3-embedding:4b` vía Ollama para mejorar recuperación semántica.
- Añade `docling` en los requirements del perfil alto.
- Está pensado para equipos donde calidad y latencia deben convivir, normalmente con GPU.

## 🪟 Windows

### Instalar

```powershell
.\run-install.bat
```

### Verificar requisitos

```powershell
pwsh -ExecutionPolicy Bypass -File .\SISTEMA-MEDIO\windows\check-requirements.ps1
```

### Arrancar

```powershell
.\run-chatbot.bat
```

### Desinstalar el perfil por defecto

```powershell
.\run-uninstall.bat
```

### Utilidad adicional

Para gestionar el `PATH` del sistema:

```powershell
pwsh -ExecutionPolicy Bypass -File .\scripts-windows\setup-path.ps1 -DryRun
pwsh -ExecutionPolicy Bypass -File .\scripts-windows\setup-path.ps1
```

## 🐧 Linux

### Instalar

```bash
bash run-install.sh
```

### Verificar requisitos

```bash
bash SISTEMA-MEDIO/linux/check-requirements.sh
```

### Arrancar

```bash
bash run-chatbot.sh
```

### Desinstalar

```bash
bash run-uninstall.sh
```

## 🍎 macOS

### Instalar

```bash
bash run-install-mac.sh
```

### Verificar requisitos

```bash
bash SISTEMA-MEDIO/mac/check-requirements.sh
```

### Arrancar

```bash
bash run-chatbot-mac.sh
```

### Desinstalar

```bash
bash run-uninstall-mac.sh
```

## 📄 Formatos soportados

`.pdf` · `.docx` · `.pptx` · `.xlsx` · `.txt` · `.md` · `.html` · `.htm` · `.jpg` · `.jpeg` · `.png` · `.tiff` · `.bmp` · `.webp`

## 💬 Interfaz y API

### Interfaz web

```text
http://localhost:8000/static/chat.html
```

### Endpoints principales

| Endpoint | Método | Qué hace |
|----------|--------|-----------|
| `/chat` | POST | consulta RAG o conversacional |
| `/ingest` | POST | reindexa todos los documentos |
| `/ingest/file` | POST | procesa un archivo concreto |
| `/health` | GET | salud de Ollama + ChromaDB + embeddings |
| `/stats` | GET | número de vectores |
| `/reindex` | POST | reinicia la colección e indexa desde cero |

### Respuesta de `/chat`

```json
{
  "answer": "Según el documento indexado...",
  "sources": [
    { "file": "manual.pdf", "score": 0.91 }
  ],
  "confidence": "high",
  "cached": false,
  "response_time_ms": 1480
}
```

## 🔄 Flujo RAG

```text
data/documents/
  -> extractor por formato
  -> limpieza
  -> chunking
  -> embeddings
  -> ChromaDB
  -> recuperación semántica
  -> prompt RAG
  -> Ollama
```

## 🧪 Desarrollo y pruebas

### Instalar dependencias de desarrollo

```bash
python -m pip install -r requirements-dev.txt
```

### Ejecutar tests

```bash
python -m pytest -q
```

### Cobertura

```bash
python -m pytest --cov=src --cov-report=term-missing
```

## 📚 Documentación relacionada

- [SISTEMA-BAJO/README.md](SISTEMA-BAJO/README.md)
- [SISTEMA-MEDIO/README.md](SISTEMA-MEDIO/README.md)
- [SISTEMA-ALTO/README.md](SISTEMA-ALTO/README.md)
- [docs/arquitectura-perfiles-sistema.md](docs/arquitectura-perfiles-sistema.md)
- [examples/asp-integration/README.md](examples/asp-integration/README.md)

## ❓ Preguntas frecuentes

### ¿El proyecto envía datos fuera?

No. El backend, los embeddings, la base vectorial y el modelo de chat trabajan en local.

### ¿Puedo cambiar de perfil sin tocar código?

Sí. Cada perfil monta su `.env` y sus requirements, mientras `src/` permanece compartido.

### ¿Por qué ya no existe `scripts-linux/` o `scripts-mac/` en el raíz?

Porque duplicaban wrappers que ya existían por perfil y generaban confusión. La lógica compartida vive ahora en `common/scripts/` y el acceso de usuario se hace desde los launchers raíz o desde cada perfil.

### ¿Por qué `SISTEMA-ALTO` usa embeddings por Ollama?

Porque permite aprovechar modelos de embeddings más potentes dentro del mismo runtime local y alinea mejor calidad de recuperación y hardware disponible.

## 📄 Licencia

MIT. Consulta [LICENSE](LICENSE).
