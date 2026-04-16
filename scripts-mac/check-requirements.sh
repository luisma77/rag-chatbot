#!/bin/bash
# check-requirements.sh — Verifica dependencias del RAG Chatbot en macOS
# Uso: bash scripts-mac/check-requirements.sh

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

ok()   { echo -e "  \033[32m✓\033[0m $1"; }
warn() { echo -e "  \033[33m⚠\033[0m $1"; }
err()  { echo -e "  \033[31m✗\033[0m $1"; }
hdr()  { echo -e "\n\033[36m── $1\033[0m"; }

echo ""
echo -e "\033[35mRAG Chatbot — Verificación de dependencias (macOS)\033[0m"
echo ""

# Detectar arquitectura
ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ]; then
    BREW_PREFIX="/opt/homebrew"
    ARCH_LABEL="Apple Silicon (arm64)"
else
    BREW_PREFIX="/usr/local"
    ARCH_LABEL="Intel (x86_64)"
fi
echo -e "  Arquitectura: \033[36m$ARCH_LABEL\033[0m"
echo -e "  Homebrew prefix: \033[36m$BREW_PREFIX\033[0m"

ISSUES=0

hdr "Homebrew"
if command -v brew &>/dev/null; then
    ok "$(brew --version | head -1)"
else
    err "Homebrew no encontrado. Instala con:"
    err "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    ((ISSUES++))
fi

hdr "Python 3.10+"
if command -v python3 &>/dev/null; then
    PY_VER=$(python3 --version 2>&1)
    PY_MINOR=$(python3 -c "import sys; print(sys.version_info.minor)")
    PY_MAJOR=$(python3 -c "import sys; print(sys.version_info.major)")
    if [ "$PY_MAJOR" -ge 3 ] && [ "$PY_MINOR" -ge 10 ]; then
        ok "$PY_VER"
    else
        warn "$PY_VER — se recomienda 3.10+. Actualiza con: brew install python3"
        ((ISSUES++))
    fi
else
    err "Python3 no encontrado. Instala con: brew install python3"
    ((ISSUES++))
fi

hdr "pip packages"
cd "$REPO_ROOT"
if [ -f requirements.txt ]; then
    while IFS= read -r line; do
        [[ "$line" =~ ^#  ]] && continue
        [[ -z "$line"     ]] && continue
        pkg=$(echo "$line" | sed 's/[>=<!=\[].*//')
        if python3 -c "import pkg_resources; pkg_resources.require('$line')" 2>/dev/null; then
            ok "$pkg"
        else
            warn "$pkg — no instalado o versión incorrecta"
            ((ISSUES++))
        fi
    done < requirements.txt
else
    warn "requirements.txt no encontrado en $REPO_ROOT"
fi

hdr "Ollama"
if command -v ollama &>/dev/null; then
    ok "Ollama instalado"
    if curl -s http://localhost:11434/api/tags >/dev/null 2>&1; then
        ok "Ollama servidor activo"
    else
        warn "Ollama instalado pero servidor no activo. Ejecuta: ollama serve"
    fi
else
    err "Ollama no encontrado. Instala con: brew install ollama"
    ((ISSUES++))
fi

hdr "Modelo LLM (qwen2.5:3b)"
if command -v ollama &>/dev/null && ollama list 2>/dev/null | grep -q "qwen2.5:3b"; then
    ok "qwen2.5:3b disponible"
else
    warn "Modelo qwen2.5:3b no descargado. Ejecuta: ollama pull qwen2.5:3b"
    ((ISSUES++))
fi

hdr "Tesseract OCR"
if command -v tesseract &>/dev/null; then
    ok "$(tesseract --version 2>&1 | head -1)"
elif [ -f "$BREW_PREFIX/bin/tesseract" ]; then
    ok "Tesseract en $BREW_PREFIX/bin/tesseract (no está en PATH)"
    warn "Añade $BREW_PREFIX/bin al PATH o ejecuta: brew link tesseract"
else
    err "Tesseract no encontrado. Instala con: brew install tesseract tesseract-lang"
    ((ISSUES++))
fi

hdr "Poppler"
if command -v pdftoppm &>/dev/null; then
    ok "Poppler instalado"
elif [ -f "$BREW_PREFIX/bin/pdftoppm" ]; then
    ok "Poppler en $BREW_PREFIX/bin (no está en PATH)"
    warn "Añade $BREW_PREFIX/bin al PATH"
else
    err "Poppler no encontrado. Instala con: brew install poppler"
    ((ISSUES++))
fi

hdr "fswatch (watcher de documentos)"
if command -v fswatch &>/dev/null; then
    ok "fswatch disponible"
else
    warn "fswatch no encontrado. Instala con: brew install fswatch"
    warn "  Sin fswatch el bot funciona pero no detecta cambios automáticamente."
fi

echo ""
echo "────────────────────────────────"
if [ $ISSUES -eq 0 ]; then
    echo -e "\033[32m✓ Todo correcto. Ejecuta: ./run-chatbot-mac.sh\033[0m"
else
    echo -e "\033[33m⚠ $ISSUES problema(s) detectado(s). Ejecuta: ./run-install-mac.sh\033[0m"
fi
echo ""
