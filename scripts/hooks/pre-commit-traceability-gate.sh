#!/bin/bash
# pre-commit-traceability-gate.sh: Gate I→V — Verify traceability before commit
#
# Fires in pre-commit hook after build/test gates.
# Checks that traceability matrices are valid if requirements changed.

set -euo pipefail

YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"

# Check if any requirements or code changed in this commit
CHANGED_FILES=$(git diff --cached --name-only 2>/dev/null || true)

# If no traceability files exist, skip
if [ ! -d "$PROJECT_DIR/backbone/artifacts/traceability" ]; then
    exit 0
fi

# Check if any requirements-related files changed
REQ_CHANGED=false
if echo "$CHANGED_FILES" | grep -qE 'backbone/artifacts/prd/|backbone/design/|backbone/artifacts/changes/|backbone/artifacts/traceability/'; then
    REQ_CHANGED=true
fi

# Check if code files changed (might need traceability update)
CODE_CHANGED=false
if echo "$CHANGED_FILES" | grep -qE '^src/|^tests/'; then
    CODE_CHANGED=true
fi

# If nothing relevant changed, skip
if [ "$REQ_CHANGED" = false ] && [ "$CODE_CHANGED" = false ]; then
    exit 0
fi

# Run traceability verification
echo ""
echo "🔍 Gate I→V: Checking traceability matrix..."

if [ -f "$PROJECT_DIR/scripts/verify-traceability.sh" ]; then
    if bash "$PROJECT_DIR/scripts/verify-traceability.sh" > /tmp/trace-check.out 2>&1; then
        echo -e "${GREEN}✅ Traceability check passed${NC}"
        exit 0
    else
        cat /tmp/trace-check.out
        echo ""
        echo -e "${YELLOW}⚠️  REVIEW GATE I→V NOT SATISFIED${NC}"
        echo ""
        echo "  Traceability matrix has gaps. Before committing:"
        echo "    1. Update backbone/artifacts/traceability/<feature>.yml"
        echo "    2. Run: ./scripts/verify-traceability.sh"
        echo "    3. Ensure all requirements link to code and tests"
        echo ""
        echo "  Or override: SKIP_TRACEABILITY=1 git commit -m '...'"
        echo ""
        exit 1
    fi
else
    echo -e "${YELLOW}⚠️  verify-traceability.sh not found — skipping Gate I→V${NC}"
    exit 0
fi
