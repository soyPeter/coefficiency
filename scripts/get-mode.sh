#!/bin/bash
# Returns the current backbone mode from backbone/.MODE
# Usage: source scripts/get-mode.sh (sets MODE variable)
#    or: scripts/get-mode.sh (prints mode)

BACKBONE_DIR="${1:-.}"

if [ -f "$BACKBONE_DIR/backbone/.MODE" ]; then
    MODE=$(cat "$BACKBONE_DIR/backbone/.MODE")
else
    MODE="standard"
fi

MODE=$(echo "$MODE" | tr -d '[:space:]')

if [ "$MODE" != "light" ] && [ "$MODE" != "standard" ] && [ "$MODE" != "full" ]; then
    MODE="standard"
fi

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    echo "$MODE"
fi