#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
bash "$REPO_ROOT/common/scripts/linux/uninstall.sh" "SISTEMA-BAJO" "qwen3:1.7b" "$REPO_ROOT/common/requirements/profile-low.txt" "sentence-transformers" "sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2"
