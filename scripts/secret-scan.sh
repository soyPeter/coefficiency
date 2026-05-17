#!/bin/bash
set -euo pipefail
# Wrapper for secret-scan.py
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
python3 "$SCRIPT_DIR/secret-scan.py" "$@"
