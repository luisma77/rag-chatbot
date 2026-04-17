#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
bash "$REPO_ROOT/common/scripts/mac/install.sh" "SISTEMA-BAJO" "$REPO_ROOT/common/env/profiles/sistema-bajo.env" "$REPO_ROOT/common/env/os/macos.env" "qwen3:1.7b" "false" "$REPO_ROOT/common/requirements/profile-low.txt" "sentence-transformers" "sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2"
