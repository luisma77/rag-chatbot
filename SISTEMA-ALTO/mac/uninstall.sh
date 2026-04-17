#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
bash "$REPO_ROOT/common/scripts/mac/uninstall.sh" "SISTEMA-ALTO" "qwen3:8b" "$REPO_ROOT/common/requirements/profile-high.txt" "ollama" "qwen3-embedding:4b"
