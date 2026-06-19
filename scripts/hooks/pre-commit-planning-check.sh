#!/bin/bash
# pre-commit-planning-check.sh: Gate P→T (pre-commit) — Block proposals without tasks
#
# Cross-agent enforcement: works with Claude Code, OpenCode, Cursor, etc.
# When PRD/proposal files are staged, verifies corresponding tasks exist.
# For backbone/artifacts/changes/ folders: checks tasks.md is collocated.
# For old backbone/artifacts/prd/ paths: checks backbone/artifacts/planning/ for matching doc.
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

if [ "${SKIP_PLANNING_CHECK:-0}" = "1" ]; then
    exit 0
fi

# Get staged PRD or proposal files
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null | grep -E '^backbone/artifacts/changes/.*/proposal\.md$' | grep -v '^backbone/artifacts/changes/archive/' || true)
if [ -z "$STAGED_FILES" ]; then
    STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null | grep -E '^backbone/artifacts/prd/.*\.md$' || true)
fi

if [ -z "$STAGED_FILES" ]; then
    exit 0
fi

MISSING_PLANS=""

while IFS= read -r staged_file; do
    [ -z "$staged_file" ] && continue

    # If in changes/ folder, check for collocated tasks.md
    if [[ "$staged_file" =~ ^backbone/artifacts/changes/(CHNG-[^/]+) ]]; then
        chng_dir="$PROJECT_ROOT/backbone/artifacts/changes/${BASH_REMATCH[1]}"
        if [ ! -f "$chng_dir/tasks.md" ]; then
            MISSING_PLANS="$MISSING_PLANS\n  - $staged_file → missing: $chng_dir/tasks.md"
        fi
        continue
    fi

    # Old path: check backbone/artifacts/planning/ for matching doc
    prd_basename=$(basename "$staged_file" .md)
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
        MISSING_PLANS="$MISSING_PLANS\n  - $staged_file → missing: backbone/artifacts/planning/*$feature_name*.md"
    fi
done <<< "$STAGED_FILES"

if [ -z "$MISSING_PLANS" ]; then
    exit 0
fi

echo ""
echo -e "${YELLOW}❌ PLANNING GATE P→T NOT SATISFIED${NC}"
echo ""
echo "  Staged proposal files are missing corresponding tasks."
echo ""
echo -e "$MISSING_PLANS"
echo ""
echo "  Before committing a proposal, you MUST:"
echo "    1. Load the planning skill: view backbone/skills/general/planning-and-task-breakdown/SKILL.md"
echo "    2. Edit tasks.md in the changes/ folder (or create a planning doc)"
echo "    3. Break into granular [XS/S/M/L] tasks"
echo ""
echo "  Override: export SKIP_PLANNING_CHECK=1"
echo ""
exit 1
