#!/bin/bash
set -e

PROFILE_NAME="$1"
PROFILE_ENV_PATH="$2"
OS_TEMPLATE="$3"
MODEL_NAME="$4"
QUALITY_EXTRAS="$5"
REQUIREMENTS_FILE="$6"
EMBEDDING_PROVIDER="$7"
EMBEDDING_MODEL="$8"
ORIGINAL_ARGS=("$@")
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
BASE_ENV="$REPO_ROOT/common/env/base.env"

pause_end() { echo ""; read -p "Presiona Enter para cerrar" _; }
on_error() { echo ""; echo "[ERROR] Fallo en la linea $1"; pause_end; exit 1; }
trap 'on_error $LINENO' ERR

log_step() { echo -e "\n\033[36m==> $1\033[0m"; }
log_ok()   { echo -e "  \033[32m[OK]\033[0m $1"; }
log_warn() { echo -e "  \033[33m[!!]\033[0m $1"; }

ensure_sudo() {
  sudo -v >/dev/null 2>&1
}

ensure_system_path_entry() {
  local target="$1"
  local name="$2"
  [ -d "$target" ] || return 0
  local file="/etc/paths.d/$name"
  if [ ! -f "$file" ] || ! grep -qx "$target" "$file" 2>/dev/null; then
    printf "%s\n" "$target" | sudo tee "$file" >/dev/null
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

ensure_brew_package() {
  local package="$1"
  local label="$2"
  if brew list "$package" >/dev/null 2>&1; then
    log_ok "$label ya instalado."
    if brew outdated "$package" >/dev/null 2>&1; then
      log_warn "Hay actualizacion disponible para $label. Actualizando automaticamente..."
      brew upgrade "$package"
    fi
  else
    log_warn "$label no encontrado. Instalando la version mas reciente..."
    brew install "$package"
    log_ok "$label instalado."
  fi
}

ensure_ollama_model() {
  local model_name="$1"
  if ollama list 2>/dev/null | grep -q "$model_name"; then
    log_ok "Modelo $model_name ya disponible."
  else
    log_warn "Modelo $model_name no encontrado. Descargando..."
    ollama pull "$model_name"
    log_ok "Modelo $model_name listo."
  fi
}

cd "$REPO_ROOT"
ensure_sudo
echo ""
echo -e "\033[35mRAG Chatbot — Instalacion $PROFILE_NAME (macOS)\033[0m"
echo ""

log_step "1/6 Homebrew y Python"
if ! command -v brew >/dev/null 2>&1; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
if brew list python3 >/dev/null 2>&1; then
  log_ok "Python 3 ya instalado."
  if brew outdated python3 >/dev/null 2>&1; then
    if prompt_yes_no "Python 3 tiene actualizacion disponible. Deseas actualizarlo?" "yes"; then
      brew upgrade python3
    fi
  fi
else
  if prompt_yes_no "Python 3 no esta instalado. Deseas instalarlo?" "yes"; then
    brew install python3
  else
    echo "[ERROR] Python 3 es obligatorio para continuar."
    exit 1
  fi
fi
ensure_system_path_entry "/opt/homebrew/bin" "rag-chatbot-homebrew"
ensure_system_path_entry "/usr/local/bin" "rag-chatbot-usr-local"

log_step "2/6 Dependencias Python"
sudo python3 -m pip install --upgrade pip -q --break-system-packages
sudo python3 -m pip install -r "$REQUIREMENTS_FILE" --break-system-packages

log_step "3/6 Tesseract, Poppler y fswatch"
ensure_brew_package tesseract "Tesseract OCR"
ensure_brew_package tesseract-lang "Tesseract idiomas"
ensure_brew_package poppler "Poppler"
ensure_brew_package fswatch "fswatch"

log_step "4/6 Ollama"
if command -v ollama >/dev/null 2>&1; then
  log_ok "Ollama ya instalado."
  if prompt_yes_no "Ollama ya esta instalado. Deseas actualizarlo/reinstalarlo?" "yes"; then
    brew upgrade ollama || brew install ollama
  fi
else
  if prompt_yes_no "Ollama no esta instalado. Deseas instalarlo?" "yes"; then
    brew install ollama
  else
    echo "[ERROR] Ollama es obligatorio para continuar."
    exit 1
  fi
fi

log_step "5/6 Modelo del perfil"
if ! curl -s http://localhost:11434/api/tags >/dev/null 2>&1; then
  ollama serve >/dev/null 2>&1 &
  sleep 5
fi
ensure_ollama_model "$MODEL_NAME"
if [ "$EMBEDDING_PROVIDER" = "ollama" ] && [ -n "$EMBEDDING_MODEL" ] && [ "$EMBEDDING_MODEL" != "$MODEL_NAME" ]; then
  ensure_ollama_model "$EMBEDDING_MODEL"
fi

log_step "6/6 Configuracion"
cat "$BASE_ENV" "$PROFILE_ENV_PATH" "$OS_TEMPLATE" > "$REPO_ROOT/.env"
mkdir -p data/documents chroma_db logs install-state
cat > "$REPO_ROOT/install-state/${PROFILE_NAME,,}-mac.json" <<EOF
{
  "profile": "$PROFILE_NAME",
  "os": "mac",
  "model": "$MODEL_NAME",
  "embedding_provider": "$EMBEDDING_PROVIDER",
  "embedding_model": "$EMBEDDING_MODEL",
  "quality_extras": "$QUALITY_EXTRAS",
  "pip_requirement_file": "$REQUIREMENTS_FILE",
  "brew_packages": [
    "python3",
    "tesseract",
    "tesseract-lang",
    "poppler",
    "fswatch",
    "ollama"
  ]
}
EOF

echo ""
echo "=============================="
echo "  INSTALACION COMPLETADA"
echo "=============================="
pause_end
