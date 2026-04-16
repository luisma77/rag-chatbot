#!/bin/bash
# Iniciar el chatbot RAG en macOS
# Uso: bash run-chatbot-mac.sh  (o doble-click)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "$SCRIPT_DIR/scripts-mac/watch-and-serve.sh"
