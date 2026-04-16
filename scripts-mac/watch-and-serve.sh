#!/bin/bash
# watch-and-serve.sh — Inicia el chatbot RAG y vigila la carpeta de documentos (macOS)
# Uso: bash scripts-mac/watch-and-serve.sh
# O doble-click: ./run-chatbot-mac.sh
#
# Flujo automático:
#   1. Detecta Python 3
#   2. Instala dependencias Python
#   3. Arranca Ollama
#   4. Indexa documentos nuevos/cambiados
#   5. Arranca FastAPI
#   6. Abre el navegador
#   7. Vigila data/documents/ con fswatch → reindexado automático

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOCUMENTS_PATH="${1:-$REPO_ROOT/data/documents}"
API_PORT="${2:-8000}"
REINDEX_HELPER="$REPO_ROOT/scripts/reindex_helper.py"
FASTAPI_PID=""
FSWATCH_PID=""
BROWSER_OPENED=0

log()        { echo "[$(date '+%H:%M:%S')] $1"; }
log_green()  { echo -e "[$(date '+%H:%M:%S')] \033[32m$1\033[0m"; }
log_cyan()   { echo -e "[$(date '+%H:%M:%S')] \033[36m$1\033[0m"; }
log_yellow() { echo -e "[$(date '+%H:%M:%S')] \033[33m$1\033[0m"; }

# ── Detectar Python 3 ─────────────────────────────────────────────────────────
ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ]; then
    BREW_PREFIX="/opt/homebrew"
else
    BREW_PREFIX="/usr/local"
fi

PYTHON3=""
for candidate in python3 "$BREW_PREFIX/bin/python3" /usr/local/bin/python3; do
    if command -v "$candidate" &>/dev/null 2>&1; then
        PYTHON3="$candidate"
        break
    fi
done

if [ -z "$PYTHON3" ]; then
    echo -e "\033[31m[ERROR]\033[0m Python3 no encontrado. Ejecuta primero: bash scripts-mac/install.sh"
    exit 1
fi

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
    $PYTHON3 -m uvicorn src.main:app --host 0.0.0.0 --port "$API_PORT" &
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
            open "http://localhost:$API_PORT/static/chat.html" &>/dev/null &
        fi
    else
        log_yellow "AVISO: FastAPI no respondió. Revisa los logs."
    fi
}

invoke_reindex() {
    local filepath="$1" action="$2"
    if [ -n "$filepath" ]; then
        local fname
        fname=$(basename "$filepath")
        log_cyan "Procesando archivo: $fname ($action)"
        $PYTHON3 "$REINDEX_HELPER" "$filepath" "$action"
    else
        log_cyan "Verificando documentos en: $DOCUMENTS_PATH"
        $PYTHON3 "$REINDEX_HELPER"
    fi
}

cleanup() {
    echo ""
    log_yellow "Deteniendo servicios..."
    if [ -n "$FSWATCH_PID" ] && kill -0 "$FSWATCH_PID" 2>/dev/null; then
        kill "$FSWATCH_PID" 2>/dev/null
    fi
    stop_fastapi
    log_yellow "Servicios detenidos."
    exit 0
}
trap cleanup INT TERM

# ── Inicio ────────────────────────────────────────────────────────────────────
echo ""
echo -e "\033[35mRAG Chatbot - Iniciando (macOS)\033[0m"
echo "Directorio: $REPO_ROOT"
echo "Python:     $PYTHON3"
echo ""

mkdir -p "$DOCUMENTS_PATH"

# Dependencias Python (silencioso)
log_cyan "Verificando paquetes Python..."
$PYTHON3 -m pip install -r "$REPO_ROOT/requirements.txt" -q --disable-pip-version-check
log_green "Paquetes Python listos."

# Ollama
if ! curl -s http://localhost:11434/api/tags >/dev/null 2>&1; then
    log_cyan "Iniciando Ollama..."
    if command -v ollama &>/dev/null; then
        ollama serve >/dev/null 2>&1 &
        sleep 4
    else
        log_yellow "AVISO: Ollama no encontrado. Instálalo con: bash scripts-mac/install.sh"
    fi
else
    log_green "Ollama ya estaba corriendo."
fi

TAGS=$(curl -s http://localhost:11434/api/tags 2>/dev/null)
if [ -n "$TAGS" ]; then
    N=$(echo "$TAGS" | grep -o '"name"' | wc -l | tr -d ' ')
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

# Watcher con fswatch (macOS)
if command -v fswatch &>/dev/null; then
    log_cyan "Vigilando carpeta: $DOCUMENTS_PATH"
    log "Al detectar cambios: para FastAPI, reindexar, reinicia FastAPI"

    LAST_EVENT_TIME=0
    DEBOUNCE=5

    # fswatch emite una línea por ruta modificada
    fswatch -r --event Created --event Updated --event Removed --event Renamed \
        --latency 2 "$DOCUMENTS_PATH" 2>/dev/null |
    while IFS= read -r filepath; do
        fname=$(basename "$filepath")
        # Ignorar archivos temporales y ocultos
        [[ "$fname" == ~\$* ]] && continue
        [[ "$fname" == .* ]]   && continue

        NOW=$(date +%s)
        if (( NOW - LAST_EVENT_TIME < DEBOUNCE )); then continue; fi
        LAST_EVENT_TIME=$NOW

        # fswatch no devuelve tipo de evento en modo simple; usar "changed"
        action="changed"
        [ ! -e "$filepath" ] && action="deleted"

        log_yellow "Cambio detectado: $fname ($action)"
        stop_fastapi
        invoke_reindex "$filepath" "$action"
        start_fastapi
    done &
    FSWATCH_PID=$!

    # Esperar indefinidamente mientras el watcher corre
    wait $FSWATCH_PID
else
    log_yellow "fswatch no encontrado — instala con: brew install fswatch"
    log "Modo sin watcher. El bot sigue funcionando pero no detecta cambios automáticamente."
    while true; do sleep 5; done
fi
