#!/bin/bash
# pre-tool-use-rd-gate.sh: Gate R→D — Block design docs without PRD
#
# Fires BEFORE Write/Edit to backbone/design/*
# Checks that a corresponding PRD exists before allowing design doc creation.

set -euo pipefail

RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"

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

# Only check backbone/design/ files
if [[ "$TARGET_FILE" != *"backbone/design/"* ]]; then
    exit 0
fi

# Extract design doc name
DESIGN_NAME=$(basename "$TARGET_FILE" .md)

# Derive PRD name (remove -design suffix if present)
PRD_NAME="${DESIGN_NAME%-design}"

# Search for matching PRD
PRD_FILE=""
for candidate in "$PROJECT_DIR/backbone/prd/"*.md; do
    [ -f "$candidate" ] || continue
    candidate_base=$(basename "$candidate" .md)
    # Match if PRD name contains the design name or vice versa
    if echo "$candidate_base" | grep -qi "$PRD_NAME" || echo "$PRD_NAME" | grep -qi "$candidate_base"; then
        PRD_FILE="$candidate"
        break
    fi
done

if [ -z "$PRD_FILE" ]; then
    echo ""
    echo -e "${YELLOW}⚠️  REVIEW GATE R→D NOT SATISFIED${NC}"
    echo ""
    echo "  You are creating a design doc without a corresponding PRD."
    echo ""
    echo "  Design doc: $TARGET_FILE"
    echo "  Expected PRD: backbone/prd/*$PRD_NAME*.md"
    echo ""
    echo "  For feature work, use the DESIGN-FEATURE command:"
    echo "    /backbone:design-feature <name>"
    echo ""
    echo "  This creates both the PRD (with EARS reqs) and the design doc"
    echo "  in one guided workflow."
    echo ""
    echo "  Or override: export CLAUDE_CODE_SKIP_RD_GATE=1"
    echo ""
    exit 1
fi

# Gate G→D extension: Check PRD has grill evidence
# Skip grill check if PRD looks like a fix/docs/refactor PRD
PRD_HEADER=$(head -20 "$PRD_FILE" 2>/dev/null || true)
if ! echo "$PRD_HEADER" | grep -qiE '(fix|bug|docs|refactor|clean|chore|test|perf|ci|build|style)'; then
    if ! grep -qE '^grilled:\s*true' "$PRD_FILE" 2>/dev/null; then
        echo ""
        echo -e "${YELLOW}⚠️  GRILL GATE G→D NOT SATISFIED${NC}"
        echo ""
    echo "  PRD exists but lacks grill evidence."
    echo ""
    echo "  PRD: $PRD_FILE"
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
