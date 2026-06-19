#!/bin/bash
# pre-tool-use-conventions-check.sh: Gate C→W — Block code writes until conventions are read
#
# Fires BEFORE the FIRST Write/Edit to a code file in each session.
# Checks that the framework conventions file has been read.
#
# Why: Agents MUST read backbone/reference/conventions/<framework>.md BEFORE
# writing any code. This file defines package structure, layer boundaries,
# file naming, and framework-specific rules. Writing without reading it
# produces wrong structure (e.g., framework imports in domain layer).
#
# How it works:
#   1. Detect framework from backbone/4-KNOWLEDGE.md
#   2. Check if .backbone/session/conventions-read.json marks conventions as read
#   3. If not read → BLOCK Write/Edit with instructions
#   4. Agent reads conventions file → mark as read → proceed
#
# Cross-agent: works with Claude Code, OpenCode, Cursor, etc.
# The marker file is in .backbone/session/ (shared across agents).
#
# Override: export CLAUDE_CODE_SKIP_CONVENTIONS=1

set -euo pipefail

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"

# Skip if override is set
if [ "${CLAUDE_CODE_SKIP_CONVENTIONS:-0}" = "1" ]; then
    exit 0
fi

# ---- Light mode bypass ----
if [ -f "backbone/.MODE" ]; then
    MODE=$(tr -d '[:space:]' < "backbone/.MODE" 2>/dev/null || echo "standard")
    [ "$MODE" = "light" ] && echo "  🟢 LIGHT MODE: Advisory only — conventions check skipped." && exit 0
fi

# Read stdin JSON from Claude Code
INPUT=$(cat)
[ -z "$INPUT" ] && exit 0

# Parse tool and file path
TOOL=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_name',''))" 2>/dev/null || true)
TARGET_FILE=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))" 2>/dev/null || true)

# Only check Write and Edit tools
if [[ "$TOOL" != "Write" && "$TOOL" != "Edit" ]]; then
    exit 0
fi

# Skip if no file
if [ -z "$TARGET_FILE" ]; then
    exit 0
fi

# Only check code files (not docs, config, etc.)
# Supported extensions: java, kt, go, py, js, ts, tsx, astro, rs, rb, php, c, cpp, h, hpp
if [[ ! "$TARGET_FILE" =~ \.(java|kt|go|py|js|ts|tsx|astro|rs|rb|php|c|cpp|h|hpp)$ ]]; then
    exit 0
fi

# Skip backbone/ directory files
if [[ "$TARGET_FILE" == *backbone/* ]]; then
    exit 0
fi

# Detect framework from 4-KNOWLEDGE.md
KNOWLEDGE_FILE="$PROJECT_DIR/backbone/4-KNOWLEDGE.md"
FRAMEWORK=""
CONVENTIONS_FILE=""

if [ -f "$KNOWLEDGE_FILE" ]; then
    FRAMEWORK=$(grep -oiE 'quarkus|springboot|laravel|kotlin|golang|python' "$KNOWLEDGE_FILE" | head -1 || true)
fi

# Normalize framework to lowercase for consistent lookups
FRAMEWORK=$(echo "$FRAMEWORK" | tr '[:upper:]' '[:lower:]')

# Map framework to conventions file
if [ -n "$FRAMEWORK" ]; then
    CONVENTIONS_FILE="backbone/reference/conventions/$FRAMEWORK.md"
fi

# If no framework detected, skip (can't enforce what we don't know)
if [ -z "$CONVENTIONS_FILE" ]; then
    exit 0
fi

# Check if conventions file exists
if [ ! -f "$PROJECT_DIR/$CONVENTIONS_FILE" ]; then
    # Conventions file doesn't exist — warn but don't block
    echo ""
    echo -e "${YELLOW}⚠️  WARNING: Conventions file not found${NC}"
    echo "  Expected: $CONVENTIONS_FILE"
    echo "  Framework detected: $FRAMEWORK"
    echo "  Proceeding without conventions check."
    echo ""
    exit 0
fi

# Check if conventions have been read this session
SESSION_DIR="$PROJECT_DIR/.backbone/session"
CONVENTIONS_MARKER="$SESSION_DIR/conventions-read.json"
CONVENTIONS_READ=false

if [ -f "$CONVENTIONS_MARKER" ]; then
    if grep -q "\"$FRAMEWORK\": true" "$CONVENTIONS_MARKER" 2>/dev/null; then
        CONVENTIONS_READ=true
    fi
fi

# If conventions already read, allow
if [ "$CONVENTIONS_READ" = true ]; then
    exit 0
fi

# ── BLOCK: Conventions not read ─────────────────────────────────────────────
echo ""
echo -e "${YELLOW}❌ CONVENTIONS GATE C→W NOT SATISFIED${NC}"
echo ""
echo "  You are about to write code: $TARGET_FILE"
echo ""
echo "  BEFORE writing ANY code, you MUST read the framework conventions file."
echo "  This file defines:"
echo "    - Package structure (where files go)"
echo "    - Layer boundaries (domain/app/api/infra)"
echo "    - Framework-specific rules (annotations, DI, etc.)"
echo "    - File naming conventions"
echo ""
echo "  Required file:"
echo "    view $CONVENTIONS_FILE"
echo ""
echo "  After reading, mark as acknowledged by running:"
echo "    mkdir -p .backbone/session"
echo "    echo '{\"$FRAMEWORK\": true}' > .backbone/session/conventions-read.json"
echo ""
echo "  Or load the conventions file with your agent, then mark as read."
echo ""
echo "  Why this matters:"
echo "    - Domain layer MUST be framework-free (no Quarkus/Spring imports)"
echo "    - App layer handles use cases with DI"
echo "    - Infra layer contains all framework code"
echo "    - Wrong structure = broken architecture"
echo ""
echo "  Override: export CLAUDE_CODE_SKIP_CONVENTIONS=1"
echo ""
exit 1
