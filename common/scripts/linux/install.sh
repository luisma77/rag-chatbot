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
log_info() { echo -e "  \033[90m...\033[0m $1"; }

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

merge_env() {
  cat "$BASE_ENV" "$PROFILE_ENV_PATH" "$OS_TEMPLATE" > "$REPO_ROOT/.env"
  log_ok ".env actualizado para $PROFILE_NAME"
}

ensure_apt_package() {
  local package="$1"
  local label="$2"
  if dpkg -s "$package" >/dev/null 2>&1; then
    log_ok "$label ya instalado."
    if apt list --upgradable 2>/dev/null | grep -q "^$package/"; then
      log_warn "Hay actualizacion disponible para $label. Actualizando automaticamente..."
      apt-get install -y --only-upgrade "$package"
      log_ok "$label actualizado."
    fi
  else
    log_warn "$label no encontrado. Instalando la version mas reciente del repositorio..."
    apt-get install -y "$package"
    log_ok "$label instalado."
  fi
}

python_toolchain_action_needed() {
  if ! dpkg -s python3 >/dev/null 2>&1; then return 0; fi
  if ! dpkg -s python3-pip >/dev/null 2>&1; then return 0; fi
  if ! dpkg -s python3-venv >/dev/null 2>&1; then return 0; fi
  if apt list --upgradable 2>/dev/null | grep -q "^python3/"; then return 0; fi
  if apt list --upgradable 2>/dev/null | grep -q "^python3-pip/"; then return 0; fi
  if apt list --upgradable 2>/dev/null | grep -q "^python3-venv/"; then return 0; fi
  return 1
}

ensure_python_toolchain() {
  if command -v python3 >/dev/null 2>&1 && command -v pip3 >/dev/null 2>&1; then
    log_ok "Python 3 y pip ya estan disponibles."
  fi

  if python_toolchain_action_needed; then
    if dpkg -s python3 >/dev/null 2>&1 && dpkg -s python3-pip >/dev/null 2>&1 && dpkg -s python3-venv >/dev/null 2>&1; then
      if prompt_yes_no "Python del sistema tiene actualizaciones pendientes. Deseas actualizar el toolchain Python?" "yes"; then
        apt-get install -y --only-upgrade python3 python3-pip python3-venv
        log_ok "Toolchain Python actualizado."
      else
        log_warn "Se mantiene el toolchain Python actual."
      fi
    else
      if prompt_yes_no "Python del sistema no esta completo. Deseas instalar Python 3, pip y venv?" "yes"; then
        apt-get install -y python3 python3-pip python3-venv
        log_ok "Toolchain Python instalado."
      else
        echo "[ERROR] Python 3 es obligatorio para continuar."
        exit 1
      fi
    fi
  else
    log_ok "Toolchain Python al dia."
  fi
}

ensure_ollama_model() {
  local model_name="$1"
  if ollama list 2>/dev/null | grep -q "$model_name"; then
    log_ok "Modelo $model_name ya disponible."
  else
    log_warn "Modelo $model_name no descargado. Descargando..."
    ollama pull "$model_name"
    log_ok "Modelo $model_name listo."
  fi
}

cd "$REPO_ROOT"
ensure_root
echo ""
echo -e "\033[35mRAG Chatbot — Instalacion $PROFILE_NAME (Linux)\033[0m"
echo ""

log_step "1/6 Python y herramientas base"
apt-get update -q
ensure_python_toolchain

log_step "2/6 Dependencias Python"
python3 -m pip install --upgrade pip -q --break-system-packages
python3 -m pip install -r "$REQUIREMENTS_FILE" --break-system-packages
log_ok "Dependencias Python listas."

log_step "3/6 Tesseract y Poppler"
ensure_apt_package tesseract-ocr "Tesseract OCR"
ensure_apt_package tesseract-ocr-spa "Tesseract idioma spa"
ensure_apt_package tesseract-ocr-eng "Tesseract idioma eng"
ensure_apt_package poppler-utils "Poppler"
ensure_apt_package inotify-tools "inotify-tools"

log_step "4/6 Ollama"
if command -v ollama >/dev/null 2>&1; then
  log_ok "Ollama ya instalado."
  if prompt_yes_no "Ollama ya esta instalado. Deseas actualizarlo/reinstalarlo?" "yes"; then
    curl -fsSL https://ollama.com/install.sh | sh
  fi
else
  if prompt_yes_no "Ollama no esta instalado. Deseas instalarlo?" "yes"; then
    log_warn "Ollama no encontrado. Instalando la version mas reciente..."
    curl -fsSL https://ollama.com/install.sh | sh
    log_ok "Ollama instalado."
  else
    echo "[ERROR] Ollama es obligatorio para continuar."
    exit 1
  fi
fi

log_step "5/6 Modelo del perfil"
if ! curl -s http://localhost:11434/api/tags >/dev/null 2>&1; then
  log_info "Iniciando Ollama..."
  ollama serve >/dev/null 2>&1 &
  sleep 5
fi
ensure_ollama_model "$MODEL_NAME"
if [ "$EMBEDDING_PROVIDER" = "ollama" ] && [ -n "$EMBEDDING_MODEL" ] && [ "$EMBEDDING_MODEL" != "$MODEL_NAME" ]; then
  ensure_ollama_model "$EMBEDDING_MODEL"
fi

log_step "6/6 Configuracion"
merge_env
mkdir -p data/documents chroma_db logs install-state
cat > "$REPO_ROOT/install-state/${PROFILE_NAME,,}-linux.json" <<EOF
{
  "profile": "$PROFILE_NAME",
  "os": "linux",
  "model": "$MODEL_NAME",
  "embedding_provider": "$EMBEDDING_PROVIDER",
  "embedding_model": "$EMBEDDING_MODEL",
  "quality_extras": "$QUALITY_EXTRAS",
  "pip_requirement_file": "$REQUIREMENTS_FILE",
  "apt_packages": [
    "python3",
    "python3-pip",
    "python3-venv",
    "tesseract-ocr",
    "tesseract-ocr-spa",
    "tesseract-ocr-eng",
    "poppler-utils",
    "inotify-tools"
  ]
}
EOF
log_ok "Estado de instalacion guardado."

echo ""
echo "=============================="
echo "  INSTALACION COMPLETADA"
echo "=============================="
pause_end
