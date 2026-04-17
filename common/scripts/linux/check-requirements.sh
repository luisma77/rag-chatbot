#!/bin/bash
set -e

PROFILE_NAME="$1"
MODEL_NAME="$2"
pause_end() { echo ""; read -p "Presiona Enter para cerrar" _; }
trap pause_end EXIT

echo ""
echo -e "\033[35mRAG Chatbot — Verificacion $PROFILE_NAME (Linux)\033[0m"
echo ""

for item in python3 ollama tesseract pdftoppm inotifywait; do
  if command -v "$item" >/dev/null 2>&1; then
    echo "[OK] $item disponible"
  else
    echo "[!!] $item no encontrado"
  fi
done

if [ -f "$REPO_ROOT/.env" ]; then
  echo "[OK] .env presente"
else
  echo "[!!] .env no encontrado"
fi

if command -v ollama >/dev/null 2>&1 && ollama list 2>/dev/null | grep -q "$MODEL_NAME"; then
  echo "[OK] Modelo $MODEL_NAME disponible"
else
  echo "[!!] Modelo $MODEL_NAME no disponible"
fi
