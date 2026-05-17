#!/bin/bash
# pre-commit-conventions-check.sh: Gate 18 — Block commits if conventions not read
#
# Cross-agent enforcement: works with Claude Code, OpenCode, Cursor, etc.
# When code files are staged, verifies the framework conventions file was read.
#
# Why: Pre-commit is the fallback for agents without PreToolUse hooks.
# If an agent writes code without reading conventions, this gate catches it
# at commit time.
#
# Override: export SKIP_CONVENTIONS_CHECK=1

set -euo pipefail

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [ -z "$PROJECT_ROOT" ]; then
    exit 0
fi

# Skip if override is set
if [ "${SKIP_CONVENTIONS_CHECK:-0}" = "1" ]; then
    exit 0
fi

# Get staged code files (excluding deleted)
STAGED_CODE=$(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null | grep -E '\.(java|kt|go|py|js|ts|tsx|astro|rs|rb|php|c|cpp|h|hpp)$' || true)

if [ -z "$STAGED_CODE" ]; then
    exit 0
fi

# Detect framework from 4-KNOWLEDGE.md
KNOWLEDGE_FILE="$PROJECT_ROOT/backbone/4-KNOWLEDGE.md"
FRAMEWORK=""

if [ -f "$KNOWLEDGE_FILE" ]; then
    FRAMEWORK=$(grep -oiE 'quarkus|springboot|laravel|kotlin|golang|python' "$KNOWLEDGE_FILE" | head -1 || true)
fi

# Normalize to lowercase for consistent lookups
FRAMEWORK=$(echo "$FRAMEWORK" | tr '[:upper:]' '[:lower:]')

if [ -z "$FRAMEWORK" ]; then
    exit 0
fi

# Check if conventions have been read
SESSION_DIR="$PROJECT_ROOT/.backbone/session"
CONVENTIONS_MARKER="$SESSION_DIR/conventions-read.json"
CONVENTIONS_READ=false

if [ -f "$CONVENTIONS_MARKER" ]; then
    if grep -q "\"$FRAMEWORK\": true" "$CONVENTIONS_MARKER" 2>/dev/null; then
        CONVENTIONS_READ=true
    fi
fi

if [ "$CONVENTIONS_READ" = true ]; then
    exit 0
fi

echo ""
echo -e "${YELLOW}❌ CONVENTIONS GATE C→W NOT SATISFIED${NC}"
echo ""
echo "  You staged code files but have not read the framework conventions file."
echo ""
echo "  Framework detected: $FRAMEWORK"
echo "  Staged code files:"
echo "$STAGED_CODE" | sed 's/^/    - /'
echo ""
echo "  BEFORE writing ANY code, you MUST read:"
echo "    backbone/reference/conventions/$FRAMEWORK.md"
echo ""
echo "  This file defines package structure, layer boundaries, and framework rules."
echo "  Writing without reading it produces incorrect architecture."
echo ""
echo "  How to fix:"
echo "    1. Read the conventions file:"
echo "       view backbone/reference/conventions/$FRAMEWORK.md"
echo ""
echo "    2. Mark as read:"
echo "       echo '{\"$FRAMEWORK\": true}' > .backbone/session/conventions-read.json"
echo "       git add .backbone/session/conventions-read.json"
echo ""
echo "    3. Retry the commit"
echo ""
echo "  Override: export SKIP_CONVENTIONS_CHECK=1"
echo ""
exit 1
