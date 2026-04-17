#!/bin/bash
set -e

PROFILE_NAME="$1"
MODEL_NAME="$2"
REQUIREMENTS_FILE="$3"
EMBEDDING_PROVIDER="$4"
EMBEDDING_MODEL="$5"
ORIGINAL_ARGS=("$@")
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"

ensure_root() {
  if [ "$(id -u)" -ne 0 ]; then
    exec sudo -E bash "$0" "${ORIGINAL_ARGS[@]}"
  fi
}

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

remove_ollama_linux() {
  if [ -f /usr/local/bin/ollama ]; then rm -f /usr/local/bin/ollama; fi
  if [ -f /etc/systemd/system/ollama.service ]; then
    systemctl stop ollama 2>/dev/null || true
    systemctl disable ollama 2>/dev/null || true
    rm -f /etc/systemd/system/ollama.service
    systemctl daemon-reload 2>/dev/null || true
  fi
  rm -rf /usr/share/ollama 2>/dev/null || true
  rm -rf /var/lib/ollama 2>/dev/null || true
  rm -rf /usr/local/lib/ollama 2>/dev/null || true
  rm -rf /etc/ollama 2>/dev/null || true
}

echo ""
echo -e "\033[35mRAG Chatbot — Desinstalacion $PROFILE_NAME (Linux)\033[0m"
echo ""

cd "$REPO_ROOT"
ensure_root
STATE_FILE="$REPO_ROOT/install-state/${PROFILE_NAME,,}-linux.json"

REMOVE_PYTHON=0
REMOVE_OLLAMA=0
HAS_PYTHON=0
HAS_OLLAMA=0
if dpkg -s python3 >/dev/null 2>&1 || dpkg -s python3-pip >/dev/null 2>&1 || dpkg -s python3-venv >/dev/null 2>&1 || command -v python3 >/dev/null 2>&1; then
  HAS_PYTHON=1
fi
if command -v ollama >/dev/null 2>&1 || [ -f /usr/local/bin/ollama ] || [ -f /etc/systemd/system/ollama.service ]; then
  HAS_OLLAMA=1
fi

if [ "$HAS_PYTHON" -eq 1 ]; then
  if prompt_yes_no "Deseas desinstalar Python del sistema si fue usado por este proyecto?" "yes"; then REMOVE_PYTHON=1; fi
else
  echo "[INFO] Python no detectado. No se preguntara por Python."
fi

if [ "$HAS_OLLAMA" -eq 1 ]; then
  if prompt_yes_no "Deseas desinstalar Ollama del sistema y sus modelos?" "yes"; then REMOVE_OLLAMA=1; fi
else
  echo "[INFO] Ollama no detectado. No se preguntara por Ollama."
fi

if command -v python3 >/dev/null 2>&1 && [ -f "$REQUIREMENTS_FILE" ]; then
  python3 -m pip uninstall -y -r "$REQUIREMENTS_FILE" --break-system-packages >/dev/null 2>&1 || true
fi

if [ "$REMOVE_OLLAMA" -eq 1 ] && command -v ollama >/dev/null 2>&1; then
  ollama rm "$MODEL_NAME" 2>/dev/null || true
  if [ "$EMBEDDING_PROVIDER" = "ollama" ] && [ -n "$EMBEDDING_MODEL" ] && [ "$EMBEDDING_MODEL" != "$MODEL_NAME" ]; then
    ollama rm "$EMBEDDING_MODEL" 2>/dev/null || true
  fi
fi

apt-get remove -y tesseract-ocr tesseract-ocr-spa tesseract-ocr-eng poppler-utils inotify-tools >/dev/null 2>&1 || true
if [ "$REMOVE_PYTHON" -eq 1 ]; then
  apt-get remove -y python3 python3-pip python3-venv >/dev/null 2>&1 || true
fi
apt-get autoremove -y >/dev/null 2>&1 || true
if [ "$REMOVE_OLLAMA" -eq 1 ]; then
  remove_ollama_linux
fi

rm -rf chroma_db logs
rm -f .env
rm -f "$STATE_FILE"

echo "[OK] Desinstalacion completada."
echo "[INFO] No se borra data/documents para preservar los documentos del usuario."
