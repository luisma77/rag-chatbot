#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
bash "$REPO_ROOT/common/scripts/mac/install.sh" "SISTEMA-MEDIO" "$REPO_ROOT/common/env/sistema-medio.env" "$REPO_ROOT/SISTEMA-MEDIO/mac/templates/.env" "qwen2.5:3b" "false"
