#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
bash "$REPO_ROOT/common/scripts/mac/watch-and-serve.sh" "SISTEMA-MEDIO" "$REPO_ROOT/SISTEMA-MEDIO/reindex_helper.py"
