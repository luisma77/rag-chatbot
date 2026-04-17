#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
bash "$REPO_ROOT/common/scripts/mac/install.sh" "SISTEMA-ALTO" "$REPO_ROOT/common/env/sistema-alto.env" "$REPO_ROOT/SISTEMA-ALTO/mac/templates/.env" "qwen2.5:7b" "true"
