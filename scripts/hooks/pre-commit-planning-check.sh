#!/bin/bash
# pre-commit-planning-check.sh: Gate P→T (pre-commit) — Block PRDs without planning docs
#
# Cross-agent enforcement: works with Claude Code, OpenCode, Cursor, etc.
# When PRD files are staged, verifies corresponding planning docs exist.
#
# Override: export SKIP_PLANNING_CHECK=1

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
if [ "${SKIP_PLANNING_CHECK:-0}" = "1" ]; then
    exit 0
fi

# Get staged PRD files
STAGED_PRDS=$(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null | grep -E '^backbone/prd/.*\.md$' || true)

if [ -z "$STAGED_PRDS" ]; then
    exit 0
fi

MISSING_PLANS=""

while IFS= read -r prd_file; do
    [ -z "$prd_file" ] && continue
    
    prd_basename=$(basename "$prd_file" .md)
    # Strip date prefix (YYYY-MM-DD-) if present
    feature_name=$(echo "$prd_basename" | sed 's/^[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}-//')
    
    planning_dir="$PROJECT_ROOT/backbone/planning"
    planning_found=false
    
    if [ -d "$planning_dir" ]; then
        for candidate in "$planning_dir"/*.md; do
            [ -f "$candidate" ] || continue
            candidate_base=$(basename "$candidate" .md)
            candidate_feature=$(echo "$candidate_base" | sed 's/^[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}-//')
            
            if echo "$candidate_feature" | grep -qi "$feature_name" || echo "$feature_name" | grep -qi "$candidate_feature"; then
                planning_found=true
                break
            fi
        done
    fi
    
    if [ "$planning_found" = false ]; then
        MISSING_PLANS="$MISSING_PLANS\n  - $prd_file → missing: backbone/planning/*$feature_name*.md"
    fi
done <<< "$STAGED_PRDS"

if [ -z "$MISSING_PLANS" ]; then
    exit 0
fi

echo ""
echo -e "${YELLOW}❌ PLANNING GATE P→T NOT SATISFIED${NC}"
echo ""
echo "  Staged PRD files are missing corresponding planning documents."
echo ""
echo "  Missing planning docs:"
echo -e "$MISSING_PLANS"
echo ""
echo "  Before committing a PRD, you MUST:"
echo "    1. Load the planning skill: view backbone/skills/general/planning-and-task-breakdown/SKILL.md"
echo "    2. Create a planning doc in backbone/planning/<feature-name>.md"
echo "    3. Break the PRD into granular [XS/S/M/L] tasks"
echo ""
echo "  The planning doc should contain:"
echo "    - Vertical slice breakdown"
echo "    - Task list with size tags"
echo "    - Acceptance criteria"
echo ""
echo "  Override: export SKIP_PLANNING_CHECK=1"
echo ""
exit 1
