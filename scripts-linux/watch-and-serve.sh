#!/bin/bash
# watch-and-serve.sh — Inicia el chatbot RAG y vigila la carpeta de documentos (Linux)
# Uso: bash scripts-linux/watch-and-serve.sh
# O doble-click: ./run-chatbot.sh
#
# Flujo automático:
#   1. Arranca Ollama
#   2. Instala dependencias Python
#   3. Indexa documentos nuevos/cambiados
#   4. Arranca FastAPI
#   5. Vigila data/documents/ con inotifywait → reindexado automático

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOCUMENTS_PATH="${1:-$REPO_ROOT/data/documents}"
API_PORT="${2:-8000}"
REINDEX_HELPER="$REPO_ROOT/scripts/reindex_helper.py"
FASTAPI_PID=""
BROWSER_OPENED=0

log() { echo "[$(date '+%H:%M:%S')] $1"; }
log_green()  { echo -e "[$(date '+%H:%M:%S')] \033[32m$1\033[0m"; }
log_cyan()   { echo -e "[$(date '+%H:%M:%S')] \033[36m$1\033[0m"; }
log_yellow() { echo -e "[$(date '+%H:%M:%S')] \033[33m$1\033[0m"; }

stop_fastapi() {
    if [ -n "$FASTAPI_PID" ] && kill -0 "$FASTAPI_PID" 2>/dev/null; then
        log_yellow "Parando FastAPI (PID $FASTAPI_PID)..."
        kill "$FASTAPI_PID" 2>/dev/null
        sleep 2
    fi
    lsof -ti tcp:$API_PORT 2>/dev/null | xargs kill -9 2>/dev/null || true
    FASTAPI_PID=""
    log_yellow "FastAPI parado."
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
        log_cyan  "Chat local: http://localhost:$API_PORT/static/chat.html"
        if [ $BROWSER_OPENED -eq 0 ]; then
            BROWSER_OPENED=1
            if command -v xdg-open &>/dev/null; then
                xdg-open "http://localhost:$API_PORT/static/chat.html" &>/dev/null &
            fi
        fi
    else
        log_yellow "AVISO: FastAPI no respondió. Revisa los logs."
    fi
}

invoke_reindex() {
    local filepath="$1" action="$2"
    if [ -n "$filepath" ]; then
        local fname=$(basename "$filepath")
        log_cyan "Procesando archivo: $fname ($action)"
        python3 "$REINDEX_HELPER" "$filepath" "$action"
    else
        log_cyan "Verificando documentos en: $DOCUMENTS_PATH"
        python3 "$REINDEX_HELPER"
    fi
}

cleanup() {
    echo ""
    log_yellow "Deteniendo servicios..."
    stop_fastapi
    log_yellow "Servicios detenidos."
    exit 0
}
trap cleanup INT TERM

# ── Inicio ────────────────────────────────────────────────────────────────────
echo ""
echo -e "\033[35mRAG Chatbot - Iniciando (Linux)\033[0m"
echo "Directorio: $REPO_ROOT"
echo ""

mkdir -p "$DOCUMENTS_PATH"

# Dependencias Python
log_cyan "Verificando paquetes Python..."
python3 -m pip install -r "$REPO_ROOT/requirements.txt" -q --disable-pip-version-check
log_green "Paquetes Python listos."

# Ollama
if ! curl -s http://localhost:11434/api/tags >/dev/null 2>&1; then
    log_cyan "Iniciando Ollama..."
    ollama serve >/dev/null 2>&1 &
    sleep 4
else
    log_green "Ollama ya estaba corriendo."
fi

TAGS=$(curl -s http://localhost:11434/api/tags 2>/dev/null)
if [ -n "$TAGS" ]; then
    N=$(echo "$TAGS" | grep -o '"name"' | wc -l)
    log_green "Ollama activo — $N modelos cargados"
else
    log_yellow "AVISO: Ollama no responde. Ejecuta: ollama serve"
fi

# Indexación inicial
invoke_reindex

# Arrancar FastAPI
start_fastapi

echo ""
log_green "*** Sistema RAG activo ***"
log_green "Documentos: $DOCUMENTS_PATH"
log_cyan  "Chat:       http://localhost:$API_PORT/static/chat.html"
log_cyan  "API:        http://localhost:$API_PORT/docs"
log       "Ctrl+C para detener todo."
echo ""

# Watcher con inotifywait
if command -v inotifywait &>/dev/null; then
    log_cyan "Vigilando carpeta: $DOCUMENTS_PATH"
    log "Al detectar cambios: para FastAPI, reindexar, reinicia FastAPI"

    LAST_EVENT_TIME=0
    DEBOUNCE=5

    inotifywait -m -r -e close_write,create,delete,moved_to,moved_from \
        --format "%w%f|%e" "$DOCUMENTS_PATH" 2>/dev/null |
    while IFS="|" read -r filepath event; do
        fname=$(basename "$filepath")
        [[ "$fname" == ~\$* ]] && continue
        [[ "$fname" == .* ]]   && continue

        NOW=$(date +%s)
        if (( NOW - LAST_EVENT_TIME < DEBOUNCE )); then continue; fi
        LAST_EVENT_TIME=$NOW

        action="changed"
        [[ "$event" == *CREATE*    ]] && action="created"
        [[ "$event" == *DELETE*    ]] && action="deleted"
        [[ "$event" == *MOVED_FROM*]] && action="deleted"
        [[ "$event" == *MOVED_TO*  ]] && action="created"

        log_yellow "Cambio detectado: $fname ($action)"
        stop_fastapi
        invoke_reindex "$filepath" "$action"
        start_fastapi
    done
else
    log_yellow "inotifywait no encontrado — instala con: sudo apt install inotify-tools"
    log "Modo sin watcher. El bot sigue funcionando pero no detecta cambios automáticamente."
    while true; do sleep 5; done
fi