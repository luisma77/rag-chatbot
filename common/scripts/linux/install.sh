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
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
BASE_ENV="$REPO_ROOT/common/env/base.env"

pause_end() { echo ""; read -p "Presiona Enter para cerrar" _; }
on_error() { echo ""; echo "[ERROR] Fallo en la linea $1"; pause_end; exit 1; }
trap 'on_error $LINENO' ERR

log_step() { echo -e "\n\033[36m==> $1\033[0m"; }
log_ok()   { echo -e "  \033[32m[OK]\033[0m $1"; }
log_warn() { echo -e "  \033[33m[!!]\033[0m $1"; }
log_info() { echo -e "  \033[90m...\033[0m $1"; }

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
      log_warn "Hay actualizacion disponible para $label."
      if prompt_yes_no "Deseas actualizar $label?" "yes"; then
        sudo apt-get install -y --only-upgrade "$package"
        log_ok "$label actualizado."
      else
        log_info "Se conserva la version actual de $label."
      fi
    fi
  else
    log_warn "$label no encontrado. Instalando la version mas reciente del repositorio..."
    sudo apt-get install -y "$package"
    log_ok "$label instalado."
  fi
}

ensure_ollama_model() {
  local model_name="$1"
  if ollama list 2>/dev/null | grep -q "$model_name"; then
    log_ok "Modelo $model_name ya disponible."
    if prompt_yes_no "Deseas refrescar el modelo $model_name descargandolo de nuevo?" "no"; then
      ollama pull "$model_name"
    fi
  else
    log_warn "Modelo $model_name no descargado. Descargando..."
    ollama pull "$model_name"
    log_ok "Modelo $model_name listo."
  fi
}

cd "$REPO_ROOT"
echo ""
echo -e "\033[35mRAG Chatbot — Instalacion $PROFILE_NAME (Linux)\033[0m"
echo ""

log_step "1/6 Python y herramientas base"
sudo apt-get update -q
ensure_apt_package python3 "Python 3"
ensure_apt_package python3-pip "pip"
ensure_apt_package python3-venv "python3-venv"

log_step "2/6 Dependencias Python"
python3 -m pip install --upgrade pip -q
python3 -m pip install -r "$REQUIREMENTS_FILE"
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
  if prompt_yes_no "Deseas reinstalar/actualizar Ollama usando el instalador oficial?" "no"; then
    curl -fsSL https://ollama.com/install.sh | sh
  fi
else
  log_warn "Ollama no encontrado. Instalando la version mas reciente..."
  curl -fsSL https://ollama.com/install.sh | sh
  log_ok "Ollama instalado."
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
  "quality_extras": "$QUALITY_EXTRAS"
}
EOF
log_ok "Estado de instalacion guardado."

echo ""
echo "=============================="
echo "  INSTALACION COMPLETADA"
echo "=============================="
pause_end
