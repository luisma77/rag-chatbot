#!/bin/bash
set -e

PROFILE_NAME="$1"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
DOCUMENTS_PATH="${2:-$REPO_ROOT/data/documents}"
API_PORT="${3:-8000}"
REINDEX_HELPER="$REPO_ROOT/scripts/reindex_helper.py"
FASTAPI_PID=""
FSWATCH_PID=""

pause_end() { echo ""; read -p "Presiona Enter para cerrar" _; }
cleanup() {
  echo ""
  echo "[INFO] Deteniendo servicios..."
  [ -n "$FSWATCH_PID" ] && kill "$FSWATCH_PID" 2>/dev/null || true
  [ -n "$FASTAPI_PID" ] && kill "$FASTAPI_PID" 2>/dev/null || true
  pause_end
}
trap cleanup EXIT INT TERM

log()        { echo "[$(date '+%H:%M:%S')] $1"; }
log_green()  { echo -e "[$(date '+%H:%M:%S')] \033[32m$1\033[0m"; }
log_cyan()   { echo -e "[$(date '+%H:%M:%S')] \033[36m$1\033[0m"; }
log_yellow() { echo -e "[$(date '+%H:%M:%S')] \033[33m$1\033[0m"; }

start_fastapi() {
  cd "$REPO_ROOT"
  python3 -m uvicorn src.main:app --host 0.0.0.0 --port "$API_PORT" &
  FASTAPI_PID=$!
}

echo ""
echo -e "\033[35mRAG Chatbot - Iniciando $PROFILE_NAME (macOS)\033[0m"
echo ""

if [ ! -f "$REPO_ROOT/.env" ]; then
  log_yellow "No existe .env. Ejecuta primero el instalador del perfil."
  exit 1
fi

mkdir -p "$DOCUMENTS_PATH"
if ! curl -s http://localhost:11434/api/tags >/dev/null 2>&1; then
  ollama serve >/dev/null 2>&1 &
  sleep 4
fi
python3 "$REINDEX_HELPER"
start_fastapi
log_green "*** Sistema RAG activo para $PROFILE_NAME ***"

if command -v fswatch >/dev/null 2>&1; then
  fswatch -r --event Created --event Updated --event Removed --event Renamed --latency 2 "$DOCUMENTS_PATH" 2>/dev/null |
  while IFS= read -r filepath; do
    fname=$(basename "$filepath")
    [[ "$fname" == ~\$* ]] && continue
    [[ "$fname" == .* ]] && continue
    log_yellow "Cambio detectado: $fname"
    [ -n "$FASTAPI_PID" ] && kill "$FASTAPI_PID" 2>/dev/null || true
    action="changed"
    [ ! -e "$filepath" ] && action="deleted"
    python3 "$REINDEX_HELPER" "$filepath" "$action"
    start_fastapi
  done &
  FSWATCH_PID=$!
  wait "$FSWATCH_PID"
else
  log_yellow "fswatch no encontrado. El sistema seguira activo sin auto-watch."
  while true; do sleep 5; done
fi
