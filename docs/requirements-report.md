# RAG Chatbot — Informe de Requisitos

> Generado automaticamente por check-requirements.ps1  
> Fecha: 2026-04-16 19:03

---

## 1. PowerShell 7 (pwsh)

| Campo | Valor |
|-------|-------|
- ✅ Instalado: PowerShell 7.5.5
| Version | PowerShell 7.5.5 |
| Ruta | `C:\Program Files\PowerShell\7\pwsh.exe` |
| Instalar | `winget install Microsoft.PowerShell` |

## 2. Python 3.10+

- ✅ Python 3.14.3
| Version | Python 3.14.3 |
| Ruta | `C:\Python314\python.exe` |
| Instalar | `winget install Python.Python.3.12` |

## 3. Paquetes Python (pip)

Archivo: `requirements.txt`

| Paquete | Estado | Version |
|---------|--------|---------|
- ✅ fastapi 0.135.3
| fastapi | ✅ | 0.135.3 |
- ✅ uvicorn 0.44.0
| uvicorn | ✅ | 0.44.0 |
- ✅ aiofiles 25.1.0
| aiofiles | ✅ | 25.1.0 |
- ✅ pydantic 2.13.1
| pydantic | ✅ | 2.13.1 |
- ✅ pydantic-settings 2.13.1
| pydantic-settings | ✅ | 2.13.1 |
- ✅ python-dotenv 1.2.2
| python-dotenv | ✅ | 1.2.2 |
- ✅ httpx 0.28.1
| httpx | ✅ | 0.28.1 |
- ✅ chromadb 1.5.7
| chromadb | ✅ | 1.5.7 |
- ✅ sentence-transformers 5.4.1
| sentence-transformers | ✅ | 5.4.1 |
- ✅ pdfplumber 0.11.9
| pdfplumber | ✅ | 0.11.9 |
- ✅ pdf2image 1.17.0
| pdf2image | ✅ | 1.17.0 |
- ✅ pytesseract 0.3.13
| pytesseract | ✅ | 0.3.13 |
- ✅ pillow 12.2.0
| pillow | ✅ | 12.2.0 |
- ✅ python-docx 1.2.0
| python-docx | ✅ | 1.2.0 |
- ✅ python-pptx 1.0.2
| python-pptx | ✅ | 1.0.2 |
- ✅ openpyxl 3.1.5
| openpyxl | ✅ | 3.1.5 |
- ✅ beautifulsoup4 4.14.3
| beautifulsoup4 | ✅ | 4.14.3 |
- ✅ chardet 7.4.3
| chardet | ✅ | 7.4.3 |
- ✅ langchain-text-splitters 1.1.1
| langchain-text-splitters | ✅ | 1.1.1 |
- ✅ pytest 9.0.3
| pytest | ✅ | 9.0.3 |
- ✅ pytest-asyncio 1.3.0
| pytest-asyncio | ✅ | 1.3.0 |
- ✅ numpy 2.4.4
| numpy | ✅ | 2.4.4 |

## 4. Ollama (servidor LLM)

| Campo | Valor |
|-------|-------|
| Descripcion | Servidor de modelos LLM locales |
| Ruta esperada | `C:\ollama\ollama.exe` |
| Instalar | `Invoke-WebRequest -Uri https://ollama.ai/download/ollama-windows-amd64.zip -OutFile ollama.zip` |
- ✅ Instalado: Ollama is 0.20.7 Warning: client version is 0.6.8
| Version | Ollama is 0.20.7 Warning: client version is 0.6.8 |
| Ruta | `C:\ollama\ollama.exe` |
- ✅ Servicio activo en localhost:11434
| Servicio | ✅ Corriendo |

## 5. Modelo LLM (qwen2.5:3b)

| Campo | Valor |
|-------|-------|
| Modelo | qwen2.5:3b |
| Descripcion | Modelo de lenguaje ligero (~2GB, multilingue) |
| Instalar | `ollama pull qwen2.5:3b` |
| Alternativa | `ollama pull llama3.2:3b` o `ollama pull phi3:mini` |
- ✅ qwen2.5:3b disponible
| Estado | ✅ Disponible |

## 6. Poppler (PDF → imagen)

| Campo | Valor |
|-------|-------|
| Descripcion | Convierte paginas PDF a imagenes para OCR |
| Ruta esperada | `C:\poppler\Library\bin` |
| Instalar | Descarga de https://github.com/oschwartz10612/poppler-windows/releases |
| Version usada | 24.x |
- ✅ Poppler instalado en C:\poppler\Library\bin
| Estado | ✅ Instalado |

## 7. Tesseract OCR

| Campo | Valor |
|-------|-------|
| Descripcion | Motor OCR para PDFs escaneados e imagenes |
| Ruta esperada | `C:\Program Files\Tesseract-OCR` |
| Idiomas | eng + spa (incluidos en instalador) |
| Instalar | `winget install UB-Mannheim.TesseractOCR` |
- ✅ Tesseract v5.4.0.20240606 en C:\Program Files\Tesseract-OCR
| Version | v5.4.0.20240606 |
| Estado | ✅ Instalado |

## Resumen

| Estado | Cantidad |
|--------|----------|
| ✅ OK | 29 |
| 🔧 Arreglados | 0 |
| ⚠️ Avisos | 0 |
