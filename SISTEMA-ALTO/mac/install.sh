#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
bash "$REPO_ROOT/common/scripts/mac/install.sh" "SISTEMA-ALTO" "$REPO_ROOT/common/env/profiles/sistema-alto.env" "$REPO_ROOT/common/env/os/macos.env" "qwen3:8b" "true" "$REPO_ROOT/common/requirements/profile-high.txt" "ollama" "qwen3-embedding:4b"
