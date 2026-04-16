#!/bin/bash
# check-requirements.sh — Verifica dependencias del RAG Chatbot en Linux
# Uso: bash scripts-linux/check-requirements.sh

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

ok()   { echo -e "  \033[32m✓\033[0m $1"; }
warn() { echo -e "  \033[33m⚠\033[0m $1"; }
err()  { echo -e "  \033[31m✗\033[0m $1"; }
hdr()  { echo -e "\n\033[36m── $1\033[0m"; }

echo ""
echo -e "\033[35mRAG Chatbot — Verificación de dependencias (Linux)\033[0m"
echo ""

ISSUES=0

hdr "Python"
if command -v python3 &>/dev/null; then
    ok "$(python3 --version)"
else
    err "Python3 no encontrado. Instala con: sudo apt install python3"
    ((ISSUES++))
fi

hdr "pip packages"
cd "$REPO_ROOT"
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

hdr "Ollama"
if command -v ollama &>/dev/null; then
    ok "Ollama instalado"
    if curl -s http://localhost:11434/api/tags >/dev/null 2>&1; then
        ok "Ollama servidor activo"
    else
        warn "Ollama instalado pero servidor no activo. Ejecuta: ollama serve"
    fi
else
    err "Ollama no encontrado. Instala con: curl -fsSL https://ollama.com/install.sh | sh"
    ((ISSUES++))
fi

hdr "Modelo LLM (qwen2.5:3b)"
if ollama list 2>/dev/null | grep -q "qwen2.5:3b"; then
    ok "qwen2.5:3b disponible"
else
    warn "Modelo qwen2.5:3b no descargado. Ejecuta: ollama pull qwen2.5:3b"
    ((ISSUES++))
fi

hdr "Tesseract OCR"
if command -v tesseract &>/dev/null; then
    ok "$(tesseract --version 2>&1 | head -1)"
else
    warn "Tesseract no encontrado. Instala con: sudo apt install tesseract-ocr tesseract-ocr-spa"
    ((ISSUES++))
fi

hdr "Poppler"
if command -v pdftoppm &>/dev/null; then
    ok "Poppler instalado"
else
    warn "Poppler no encontrado. Instala con: sudo apt install poppler-utils"
    ((ISSUES++))
fi

hdr "inotify-tools (watcher)"
if command -v inotifywait &>/dev/null; then
    ok "inotifywait disponible"
else
    warn "inotify-tools no encontrado. Instala con: sudo apt install inotify-tools"
fi

echo ""
echo "────────────────────────────────"
if [ $ISSUES -eq 0 ]; then
    echo -e "\033[32m✓ Todo correcto. Ejecuta: ./run-chatbot.sh\033[0m"
else
    echo -e "\033[33m⚠ $ISSUES problema(s) detectado(s). Ejecuta: ./run-install.sh\033[0m"
fi
echo ""