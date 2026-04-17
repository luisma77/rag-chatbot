#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
bash "$REPO_ROOT/common/scripts/linux/watch-and-serve.sh" "SISTEMA-BAJO" "$REPO_ROOT/SISTEMA-BAJO/reindex_helper.py"
