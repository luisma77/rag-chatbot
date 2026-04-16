#!/bin/bash
# install.sh — Instalación completa del RAG Chatbot en Linux/Ubuntu
# Uso: bash scripts-linux/install.sh
# O doble-click: ./run-install.sh
#
# QUE INSTALA:
#   - Python 3.10+ y pip
#   - pip packages (requirements.txt)
#   - Ollama (servidor LLM local)
#   - Modelo qwen2.5:3b (~2.1 GB)
#   - Tesseract OCR + paquetes spa y eng
#   - Poppler (pdf2image)
#   - inotify-tools (watcher de documentos)

set -e
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

log_step() { echo -e "\n\033[36m==> $1\033[0m"; }
log_ok()   { echo -e "  \033[32m[OK]\033[0m $1"; }
log_warn() { echo -e "  \033[33m[!!]\033[0m $1"; }
log_err()  { echo -e "  \033[31m[ERROR]\033[0m $1"; }

echo ""
echo -e "\033[35mRAG Chatbot — Instalación (Linux)\033[0m"
echo "Directorio: $REPO_ROOT"
echo ""

# ── 1/6  Python ──────────────────────────────────────────────────────────────
log_step "1/6 Verificando Python 3.10+"
if ! command -v python3 &>/dev/null; then
    log_warn "Python3 no encontrado. Instalando..."
    sudo apt-get update -q && sudo apt-get install -y python3 python3-pip python3-venv
fi
PY_VER=$(python3 --version)
log_ok "$PY_VER"

# ── 2/6  pip packages ────────────────────────────────────────────────────────
log_step "2/6 Instalando dependencias Python"
python3 -m pip install --upgrade pip -q
python3 -m pip install -r requirements.txt
log_ok "Dependencias instaladas."

# ── 3/6  Tesseract OCR ───────────────────────────────────────────────────────
log_step "3/6 Instalando Tesseract-OCR"
if command -v tesseract &>/dev/null; then
    log_ok "Tesseract ya instalado: $(tesseract --version 2>&1 | head -1)"
else
    sudo apt-get install -y tesseract-ocr tesseract-ocr-spa tesseract-ocr-eng
    log_ok "Tesseract instalado."
fi

# ── 4/6  Poppler ─────────────────────────────────────────────────────────────
log_step "4/6 Instalando Poppler (requerido por pdf2image)"
if command -v pdftoppm &>/dev/null; then
    log_ok "Poppler ya instalado."
else
    sudo apt-get install -y poppler-utils
    log_ok "Poppler instalado."
fi

# ── 5/6  Ollama ──────────────────────────────────────────────────────────────
log_step "5/6 Instalando Ollama y modelo qwen2.5:3b"
if command -v ollama &>/dev/null; then
    log_ok "Ollama ya instalado."
else
    echo "  Descargando e instalando Ollama..."
    curl -fsSL https://ollama.com/install.sh | sh
fi

# Start Ollama and pull model
ollama serve >/dev/null 2>&1 &
OLLAMA_PID=$!
sleep 5
echo "  Descargando modelo qwen2.5:3b (~2.1 GB, puede tardar varios minutos)..."
ollama pull qwen2.5:3b
if [ $? -eq 0 ]; then
    log_ok "Modelo qwen2.5:3b listo."
else
    log_warn "Error descargando modelo. Ejecuta manualmente: ollama pull qwen2.5:3b"
fi

# ── 6/6  Entorno ─────────────────────────────────────────────────────────────
log_step "6/6 Configurando entorno"

# inotify-tools para el watcher
if ! command -v inotifywait &>/dev/null; then
    echo "  Instalando inotify-tools (watcher de documentos)..."
    sudo apt-get install -y inotify-tools
    log_ok "inotify-tools instalado."
else
    log_ok "inotify-tools ya instalado."
fi

if [ ! -f ".env" ]; then
    cp .env.example .env
    # Adjust Linux paths in .env
    sed -i 's|TESSERACT_CMD=.*|TESSERACT_CMD=/usr/bin/tesseract|' .env
    sed -i 's|POPPLER_PATH=.*|POPPLER_PATH=|' .env
    log_ok ".env creado con rutas Linux."
else
    log_ok ".env ya existe."
fi

mkdir -p data/documents chroma_db logs
log_ok "Directorios creados: data/documents, chroma_db, logs"

echo ""
echo "=============================="
echo "  INSTALACIÓN COMPLETADA"
echo "=============================="
echo ""
echo "Siguiente paso — iniciar el chatbot:"
echo "  ./run-chatbot.sh"
echo "  o: bash scripts-linux/watch-and-serve.sh"
echo ""
echo "Documentación API (cuando esté corriendo):"
echo "  http://localhost:8000/docs"
echo ""
echo "Indexar documentos:"
echo "  Coloca archivos en data/documents/"
echo "  Se indexan automáticamente al guardarlos."
echo ""
read -p "Presiona Enter para cerrar"