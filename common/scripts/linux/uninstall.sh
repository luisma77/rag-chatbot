#!/bin/bash
set -e

PROFILE_NAME="$1"
MODEL_NAME="$2"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
pause_end() { echo ""; read -p "Presiona Enter para cerrar" _; }
trap pause_end EXIT

prompt_yes_no() {
  read -r -p "$1 [s/N] " answer
  case "$answer" in
    [sS]|[sS][iI]|[yY]|[yY][eE][sS]) return 0 ;;
    *) return 1 ;;
  esac
}

echo ""
echo -e "\033[35mRAG Chatbot — Desinstalacion $PROFILE_NAME (Linux)\033[0m"
echo ""

cd "$REPO_ROOT"
if prompt_yes_no "Deseas eliminar el modelo $MODEL_NAME de Ollama?"; then
  ollama rm "$MODEL_NAME" 2>/dev/null || true
fi
if prompt_yes_no "Deseas borrar chroma_db y logs?"; then
  rm -rf chroma_db logs
fi
if prompt_yes_no "Deseas borrar el archivo .env?"; then
  rm -f .env
fi
rm -f "install-state/${PROFILE_NAME,,}-linux.json"
echo "[OK] Limpieza completada. No se borra data/documents ni herramientas globales."
