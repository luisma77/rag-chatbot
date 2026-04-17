#!/bin/bash
set -e

PROFILE_NAME="$1"
MODEL_NAME="$2"
REQUIREMENTS_FILE="$3"
EMBEDDING_PROVIDER="$4"
EMBEDDING_MODEL="$5"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"

prompt_yes_no() {
  local question="$1"
  local default_yes="${2:-yes}"
  local suffix="[S/n]"
  [ "$default_yes" = "no" ] && suffix="[s/N]"
  read -r -p "$question $suffix " answer
  if [ -z "$answer" ]; then
    [ "$default_yes" = "yes" ] && return 0 || return 1
  fi
  case "$answer" in
    [sS]|[sS][iI]|[yY]|[yY][eE][sS]) return 0 ;;
    *) return 1 ;;
  esac
}

echo ""
echo -e "\033[35mRAG Chatbot — Desinstalacion $PROFILE_NAME (macOS)\033[0m"
echo ""

cd "$REPO_ROOT"
STATE_FILE="$REPO_ROOT/install-state/${PROFILE_NAME,,}-mac.json"
sudo -v >/dev/null 2>&1
REMOVE_PYTHON=0
REMOVE_OLLAMA=0
HAS_PYTHON=0
HAS_OLLAMA=0
if command -v python3 >/dev/null 2>&1 || (command -v brew >/dev/null 2>&1 && brew list python3 >/dev/null 2>&1); then
  HAS_PYTHON=1
fi
if command -v ollama >/dev/null 2>&1 || (command -v brew >/dev/null 2>&1 && brew list ollama >/dev/null 2>&1); then
  HAS_OLLAMA=1
fi

if [ "$HAS_PYTHON" -eq 1 ]; then
  if prompt_yes_no "Deseas desinstalar Python 3 del sistema si fue usado por este proyecto?" "yes"; then REMOVE_PYTHON=1; fi
else
  echo "[INFO] Python no detectado. No se preguntara por Python."
fi

if [ "$HAS_OLLAMA" -eq 1 ]; then
  if prompt_yes_no "Deseas desinstalar Ollama del sistema y sus modelos?" "yes"; then REMOVE_OLLAMA=1; fi
else
  echo "[INFO] Ollama no detectado. No se preguntara por Ollama."
fi

if command -v python3 >/dev/null 2>&1 && [ -f "$REQUIREMENTS_FILE" ]; then
  sudo python3 -m pip uninstall -y -r "$REQUIREMENTS_FILE" --break-system-packages >/dev/null 2>&1 || true
fi

if [ "$REMOVE_OLLAMA" -eq 1 ] && command -v ollama >/dev/null 2>&1; then
  ollama rm "$MODEL_NAME" 2>/dev/null || true
  if [ "$EMBEDDING_PROVIDER" = "ollama" ] && [ -n "$EMBEDDING_MODEL" ] && [ "$EMBEDDING_MODEL" != "$MODEL_NAME" ]; then
    ollama rm "$EMBEDDING_MODEL" 2>/dev/null || true
  fi
fi

if command -v brew >/dev/null 2>&1; then
  brew uninstall --force tesseract tesseract-lang poppler fswatch >/dev/null 2>&1 || true
  if [ "$REMOVE_OLLAMA" -eq 1 ]; then
    brew uninstall --force ollama >/dev/null 2>&1 || true
  fi
  if [ "$REMOVE_PYTHON" -eq 1 ]; then
    brew uninstall --force python3 >/dev/null 2>&1 || true
  fi
fi

sudo rm -f /etc/paths.d/rag-chatbot-homebrew /etc/paths.d/rag-chatbot-usr-local 2>/dev/null || true

rm -rf chroma_db logs
rm -f .env
rm -f "$STATE_FILE"
echo "[OK] Desinstalacion completada."
echo "[INFO] No se borra data/documents para preservar los documentos del usuario."
