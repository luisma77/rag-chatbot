#!/bin/bash
# install.sh — Instalación completa del RAG Chatbot en macOS
# Uso: bash scripts-mac/install.sh
# O doble-click: ./run-install-mac.sh
#
# QUE INSTALA:
#   - Homebrew (si no está instalado)
#   - Python 3 y pip
#   - pip packages (requirements.txt)
#   - Ollama (servidor LLM local)
#   - Modelo qwen2.5:3b (~2.1 GB)
#   - Tesseract OCR + idiomas
#   - Poppler (pdf2image)
#   - fswatch (watcher de documentos)

set -e
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

log_step() { echo -e "\n\033[36m==> $1\033[0m"; }
log_ok()   { echo -e "  \033[32m[OK]\033[0m $1"; }
log_warn() { echo -e "  \033[33m[!!]\033[0m $1"; }
log_err()  { echo -e "  \033[31m[ERROR]\033[0m $1"; }

echo ""
echo -e "\033[35mRAG Chatbot — Instalación (macOS)\033[0m"
echo "Directorio: $REPO_ROOT"
echo ""

# Detectar arquitectura (Intel vs Apple Silicon)
ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ]; then
    BREW_PREFIX="/opt/homebrew"
else
    BREW_PREFIX="/usr/local"
fi
log_ok "Arquitectura: $ARCH (Homebrew en $BREW_PREFIX)"

# ── 1/8  Homebrew ─────────────────────────────────────────────────────────────
log_step "1/8 Verificando Homebrew"
if ! command -v brew &>/dev/null; then
    log_warn "Homebrew no encontrado. Instalando..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Añadir brew al PATH para la sesión actual
    if [ -f "$BREW_PREFIX/bin/brew" ]; then
        eval "$($BREW_PREFIX/bin/brew shellenv)"
    fi
    log_ok "Homebrew instalado."
else
    log_ok "Homebrew ya instalado: $(brew --version | head -1)"
fi

# ── 2/8  Python 3 ─────────────────────────────────────────────────────────────
log_step "2/8 Verificando Python 3"
if ! command -v python3 &>/dev/null; then
    log_warn "Python3 no encontrado. Instalando..."
    brew install python3
fi
PY_VER=$(python3 --version)
log_ok "$PY_VER"

# ── 3/8  pip packages ─────────────────────────────────────────────────────────
log_step "3/8 Instalando dependencias Python"
python3 -m pip install --upgrade pip -q
python3 -m pip install -r requirements.txt
log_ok "Dependencias instaladas."

# ── 4/8  Tesseract OCR ────────────────────────────────────────────────────────
log_step "4/8 Instalando Tesseract-OCR"
if command -v tesseract &>/dev/null; then
    log_ok "Tesseract ya instalado: $(tesseract --version 2>&1 | head -1)"
else
    brew install tesseract tesseract-lang
    log_ok "Tesseract instalado."
fi

# ── 5/8  Poppler ──────────────────────────────────────────────────────────────
log_step "5/8 Instalando Poppler (requerido por pdf2image)"
if command -v pdftoppm &>/dev/null; then
    log_ok "Poppler ya instalado."
else
    brew install poppler
    log_ok "Poppler instalado."
fi

# ── 6/8  fswatch ──────────────────────────────────────────────────────────────
log_step "6/8 Instalando fswatch (watcher de documentos)"
if command -v fswatch &>/dev/null; then
    log_ok "fswatch ya instalado."
else
    brew install fswatch
    log_ok "fswatch instalado."
fi

# ── 7/8  Ollama ───────────────────────────────────────────────────────────────
log_step "7/8 Instalando Ollama y modelo qwen2.5:3b"
if command -v ollama &>/dev/null; then
    log_ok "Ollama ya instalado."
else
    echo "  Intentando instalar Ollama con Homebrew..."
    if brew install ollama 2>/dev/null; then
        log_ok "Ollama instalado vía Homebrew."
    else
        log_warn "Homebrew no pudo instalar Ollama. Descargando desde ollama.com..."
        OLLAMA_ZIP="/tmp/Ollama-darwin.zip"
        curl -fsSL "https://ollama.com/download/Ollama-darwin.zip" -o "$OLLAMA_ZIP"
        unzip -q "$OLLAMA_ZIP" -d /tmp/ollama-install
        if [ -d "/tmp/ollama-install/Ollama.app" ]; then
            cp -r /tmp/ollama-install/Ollama.app /Applications/
            ln -sf /Applications/Ollama.app/Contents/Resources/ollama "$BREW_PREFIX/bin/ollama" 2>/dev/null || true
            log_ok "Ollama.app instalado en /Applications/."
        fi
        rm -rf "$OLLAMA_ZIP" /tmp/ollama-install
    fi
fi

# Iniciar Ollama y descargar modelo
if command -v ollama &>/dev/null; then
    if ! curl -s http://localhost:11434/api/tags >/dev/null 2>&1; then
        echo "  Iniciando servidor Ollama..."
        ollama serve >/dev/null 2>&1 &
        sleep 5
    fi
    echo "  Descargando modelo qwen2.5:3b (~2.1 GB, puede tardar varios minutos)..."
    if ollama pull qwen2.5:3b; then
        log_ok "Modelo qwen2.5:3b listo."
    else
        log_warn "Error descargando modelo. Ejecuta manualmente: ollama pull qwen2.5:3b"
    fi
else
    log_warn "Ollama no disponible en PATH. Instálalo y ejecuta: ollama pull qwen2.5:3b"
fi

# ── 8/8  Entorno ──────────────────────────────────────────────────────────────
log_step "8/8 Configurando entorno"

if [ ! -f ".env" ]; then
    cp .env.example .env
    # Ruta de Tesseract según arquitectura
    TESSERACT_PATH="$BREW_PREFIX/bin/tesseract"
    sed -i '' "s|TESSERACT_CMD=.*|TESSERACT_CMD=$TESSERACT_PATH|" .env
    # Poppler en PATH en macOS, no se necesita ruta explícita
    sed -i '' 's|POPPLER_PATH=.*|POPPLER_PATH=|' .env
    log_ok ".env creado con rutas macOS ($ARCH)."
    log_ok "  TESSERACT_CMD=$TESSERACT_PATH"
    log_ok "  POPPLER_PATH= (en PATH)"
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
echo "  ./run-chatbot-mac.sh"
echo "  o: bash scripts-mac/watch-and-serve.sh"
echo ""
echo "Documentación API (cuando esté corriendo):"
echo "  http://localhost:8000/docs"
echo ""
echo "Indexar documentos:"
echo "  Coloca archivos en data/documents/"
echo "  Se indexan automáticamente al guardarlos."
echo ""
read -p "Presiona Enter para cerrar"
