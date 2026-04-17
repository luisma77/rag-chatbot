#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
bash "$REPO_ROOT/common/scripts/linux/check-requirements.sh" "SISTEMA-BAJO" "qwen2.5:1.5b"
