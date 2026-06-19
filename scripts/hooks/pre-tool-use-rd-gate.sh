#!/bin/bash
# pre-tool-use-rd-gate.sh: Gate R→D — Block design docs without PRD
#
# Fires BEFORE Write/Edit to backbone/design/* or backbone/artifacts/changes/.../design.md
# Checks that a corresponding PRD/proposal.md exists before allowing design doc creation.

set -euo pipefail

RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"

# ---- Light mode bypass ----
if [ -f "backbone/.MODE" ]; then
    MODE=$(tr -d '[:space:]' < "backbone/.MODE" 2>/dev/null || echo "standard")
    [ "$MODE" = "light" ] && echo "  🟢 LIGHT MODE: Advisory only — RD gate skipped." && exit 0
fi

# Read stdin JSON from Claude Code
INPUT=$(cat)
[ -z "$INPUT" ] && exit 0

# Parse tool and file path
TOOL=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_name',''))" 2>/dev/null || true)
TARGET_FILE=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))" 2>/dev/null || true)

# Skip if CLAUDE_CODE_SKIP_RD_GATE is set
if [ "${CLAUDE_CODE_SKIP_RD_GATE:-0}" = "1" ]; then
    exit 0
fi

# Skip grill check if CLAUDE_CODE_SKIP_GRILL is set
if [ "${CLAUDE_CODE_SKIP_GRILL:-0}" = "1" ]; then
    exit 0
fi

# Only check Write/Edit to design docs
if [[ "$TOOL" != "Write" && "$TOOL" != "Edit" ]]; then
    exit 0
fi

# Only check backbone/design/ or backbone/artifacts/changes/.../design.md files
if [[ "$TARGET_FILE" != *"backbone/design/"* ]] && [[ "$TARGET_FILE" != *"backbone/artifacts/changes/"*"/design.md" ]]; then
    exit 0
fi

# Find matching proposal/PRD
PRD_FILE=""

# If in changes/ folder, look for proposal.md in same folder
CHANGE_DIR=""
if [[ "$TARGET_FILE" =~ backbone/artifacts/changes/(CHNG-[^/]+) ]]; then
    CHANGE_DIR="${PROJECT_DIR}/backbone/artifacts/changes/${BASH_REMATCH[1]}"
    if [ -f "$CHANGE_DIR/proposal.md" ]; then
        PRD_FILE="$CHANGE_DIR/proposal.md"
    fi
fi

# Old path: extract design doc name and search prd/ dir
if [ -z "$PRD_FILE" ]; then
    echo ""
    echo -e "${YELLOW}⚠️  REVIEW GATE R→D NOT SATISFIED${NC}"
    echo ""
    echo "  You are creating a design doc without a corresponding proposal."
    echo ""
    echo "  Design doc: $TARGET_FILE"
    echo ""
    if [ -n "$CHANGE_DIR" ]; then
        echo "  Expected: $CHANGE_DIR/proposal.md"
    fi
    echo ""
    echo "  For feature work, use the DESIGN-FEATURE command:"
    echo "    /backbone:design-feature <name>"
    echo ""
    echo "  This creates both the proposal (with EARS reqs) and the design doc"
    echo "  in one guided workflow."
    echo ""
    echo "  Or override: export CLAUDE_CODE_SKIP_RD_GATE=1"
    echo ""
    exit 1
fi

# Gate G→D extension: Check proposal/PRD has grill evidence
# Skip grill check if it looks like a fix/docs/refactor
PRD_HEADER=$(head -20 "$PRD_FILE" 2>/dev/null || true)
if ! echo "$PRD_HEADER" | grep -qiE '(fix|bug|docs|refactor|clean|chore|test|perf|ci|build|style)'; then
    if ! grep -qE '^grilled:\s*true' "$PRD_FILE" 2>/dev/null; then
        echo ""
        echo -e "${YELLOW}⚠️  GRILL GATE G→D NOT SATISFIED${NC}"
        echo ""
    echo "  Proposal/PRD exists but lacks grill evidence."
    echo ""
    echo "  File: $PRD_FILE"
    echo ""
    echo "  For feature work, use the DESIGN-FEATURE command:"
    echo "    /backbone:design-feature <name>"
    echo ""
    echo "  It ensures all gates (G→P, R→D, D→I) are satisfied."
    echo ""
    echo "  Or override: export CLAUDE_CODE_SKIP_GRILL=1"
        echo ""
        exit 1
    fi
fi

exit 0
