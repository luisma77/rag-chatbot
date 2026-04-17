#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
bash "$REPO_ROOT/common/scripts/mac/install.sh" "SISTEMA-MEDIO" "$REPO_ROOT/common/env/profiles/sistema-medio.env" "$REPO_ROOT/common/env/os/macos.env" "qwen3:4b" "false" "$REPO_ROOT/common/requirements/profile-medium.txt" "sentence-transformers" "sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2"
