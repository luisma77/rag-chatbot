#!/bin/bash
set -e

PROFILE_NAME="$1"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
DOCUMENTS_PATH="${2:-$REPO_ROOT/data/documents}"
API_PORT="${3:-8000}"
REINDEX_HELPER="$REPO_ROOT/scripts/reindex_helper.py"
FASTAPI_PID=""

pause_end() { echo ""; read -p "Presiona Enter para cerrar" _; }
cleanup() {
  echo ""
  echo "[INFO] Deteniendo servicios..."
  if [ -n "$FASTAPI_PID" ] && kill -0 "$FASTAPI_PID" 2>/dev/null; then
    kill "$FASTAPI_PID" 2>/dev/null || true
  fi
  pause_end
}
trap cleanup EXIT INT TERM

log() { echo "[$(date '+%H:%M:%S')] $1"; }
log_green()  { echo -e "[$(date '+%H:%M:%S')] \033[32m$1\033[0m"; }
log_cyan()   { echo -e "[$(date '+%H:%M:%S')] \033[36m$1\033[0m"; }
log_yellow() { echo -e "[$(date '+%H:%M:%S')] \033[33m$1\033[0m"; }

stop_fastapi() {
  if [ -n "$FASTAPI_PID" ] && kill -0 "$FASTAPI_PID" 2>/dev/null; then
    log_yellow "Parando FastAPI (PID $FASTAPI_PID)..."
    kill "$FASTAPI_PID" 2>/dev/null || true
    sleep 2
  fi
  FASTAPI_PID=""
}

start_fastapi() {
  log_cyan "Iniciando FastAPI en puerto $API_PORT..."
  cd "$REPO_ROOT"
  python3 -m uvicorn src.main:app --host 0.0.0.0 --port "$API_PORT" &
  FASTAPI_PID=$!
  local ready=0
  for i in $(seq 1 30); do
    sleep 2
    if curl -s "http://localhost:$API_PORT/health" >/dev/null 2>&1; then
      ready=1
      break
    fi
    log "Esperando FastAPI... $i/30"
  done
  if [ $ready -eq 1 ]; then
    log_green "FastAPI activo en http://localhost:$API_PORT"
    log_cyan "Chat local: http://localhost:$API_PORT/static/chat.html"
  else
    log_yellow "AVISO: FastAPI no respondio. Revisa la salida del servidor."
  fi
}

invoke_reindex() {
  local filepath="$1" action="$2"
  if [ -n "$filepath" ]; then
    python3 "$REINDEX_HELPER" "$filepath" "$action"
  else
    python3 "$REINDEX_HELPER"
  fi
}

echo ""
echo -e "\033[35mRAG Chatbot - Iniciando $PROFILE_NAME (Linux)\033[0m"
echo ""

if [ ! -f "$REPO_ROOT/.env" ]; then
  log_yellow "No existe .env. Ejecuta primero el instalador del perfil."
  exit 1
fi

mkdir -p "$DOCUMENTS_PATH"
python3 -m pip install -r "$REPO_ROOT/requirements.txt" -q --disable-pip-version-check

if ! curl -s http://localhost:11434/api/tags >/dev/null 2>&1; then
  log_cyan "Iniciando Ollama..."
  ollama serve >/dev/null 2>&1 &
  sleep 4
fi

invoke_reindex
start_fastapi
log_green "*** Sistema RAG activo para $PROFILE_NAME ***"

if command -v inotifywait >/dev/null 2>&1; then
  log_cyan "Vigilando carpeta: $DOCUMENTS_PATH"
  inotifywait -m -r -e close_write,create,delete,moved_to,moved_from --format "%w%f|%e" "$DOCUMENTS_PATH" 2>/dev/null |
  while IFS="|" read -r filepath event; do
    fname=$(basename "$filepath")
    [[ "$fname" == ~\$* ]] && continue
    [[ "$fname" == .* ]] && continue
    action="changed"
    [[ "$event" == *CREATE* ]] && action="created"
    [[ "$event" == *DELETE* ]] && action="deleted"
    [[ "$event" == *MOVED_FROM* ]] && action="deleted"
    [[ "$event" == *MOVED_TO* ]] && action="created"
    log_yellow "Cambio detectado: $fname ($action)"
    stop_fastapi
    invoke_reindex "$filepath" "$action"
    start_fastapi
  done
else
  log_yellow "inotifywait no encontrado. El sistema seguira activo sin auto-watch."
  while true; do sleep 5; done
fi
