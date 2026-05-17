#!/bin/bash
set -euo pipefail
# Wrapper for base64-scan.py
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
python3 "$SCRIPT_DIR/base64-scan.py" "$@"
