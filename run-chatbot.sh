#!/bin/bash
# Arrancar el chatbot RAG en Linux
# Uso: ./run-chatbot.sh  (o: bash run-chatbot.sh)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "$SCRIPT_DIR/scripts-linux/watch-and-serve.sh"