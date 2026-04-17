#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
bash "$REPO_ROOT/common/scripts/linux/uninstall.sh" "SISTEMA-MEDIO" "qwen3:4b" "$REPO_ROOT/common/requirements/profile-medium.txt" "sentence-transformers" "sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2"
