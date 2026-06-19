#!/bin/bash
# pre-tool-use hook: Block Write/Edit when no [WIP] task is marked
#
# Installed via: scripts/setup-hooks.sh
# Fires BEFORE each Claude Code tool use.
#
# BLOCKS Write/Edit operations if:
# - No [WIP] task is marked in backbone/3-TASKS.md
# - User hasn't explicitly overridden
#
# Exit 0 = allow tool use
# Exit 1 = block tool use

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
TASKS_FILE="$PROJECT_DIR/backbone/3-TASKS.md"

# Skip if CLAUDE_CODE_SKIP_WIP_CHECK is set (for emergency fixes)
if [ "${CLAUDE_CODE_SKIP_WIP_CHECK:-0}" = "1" ]; then
    exit 0
fi

# ---- Light mode bypass ----
if [ -f "backbone/.MODE" ]; then
    MODE=$(tr -d '[:space:]' < "backbone/.MODE" 2>/dev/null || echo "standard")
    [ "$MODE" = "light" ] && echo "  🟢 LIGHT MODE: Advisory only — WIP check skipped." && exit 0
fi

# Check if tasks file exists
if [ ! -f "$TASKS_FILE" ]; then
    exit 0
fi

# Check for [WIP] tasks
WIP_COUNT=$(grep -c '^\s*-\s*\[WIP\]' "$TASKS_FILE" 2>/dev/null || echo "0")

if [ "$WIP_COUNT" -gt 0 ]; then
    exit 0
fi

# No WIP found — BLOCK the Write/Edit
echo ""
echo -e "${RED}❌ WIP POLICY VIOLATION${NC}"
echo ""
echo "You are about to modify files but no [WIP] task is marked."
echo ""
echo "Before writing code, you MUST:"
echo "  1. Mark a task as [WIP] in backbone/3-TASKS.md"
echo "  2. Or explain what you're working on"
echo ""
echo "To override (emergency only):"
echo "  export CLAUDE_CODE_SKIP_WIP_CHECK=1"
echo ""
echo "This is enforced by scripts/hooks/pre-tool-use-wip-check.sh"
echo ""

exit 1
