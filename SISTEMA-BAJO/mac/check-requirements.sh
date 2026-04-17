#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
bash "$REPO_ROOT/common/scripts/mac/check-requirements.sh" "SISTEMA-BAJO" "qwen3:1.7b" "sentence-transformers" "sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2"
