#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
bash "$REPO_ROOT/common/scripts/mac/install.sh" "SISTEMA-BAJO" "$REPO_ROOT/common/env/sistema-bajo.env" "$REPO_ROOT/SISTEMA-BAJO/mac/templates/.env" "qwen2.5:1.5b" "false"
