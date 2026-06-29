#!/bin/bash
# scripts/hooks/pre-change.sh — Change folder validation gates
#
# Gates:
#   X — proposal.md has **REQ-XXX** bullets
#   Y — tasks.md has **Parent: REQ-XXX** on every task
#
# Called from pre-commit hook. Only runs when files under
# backbone/artifacts/changes/ are staged. Exits 0 on pass, 1 on fail.
#
# Usage:
#   ./scripts/hooks/pre-change.sh           # checks staged files
#   SKIP_CHANGE_CHECK=1 ./scripts/hooks/pre-change.sh  # skip

set -euo pipefail

if [[ -n "${SKIP_CHANGE_CHECK:-}" ]]; then
    echo "  SKIP_CHANGE_CHECK set — skipping change gates"
    exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR" && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

ERRORS=0

# Only run if there are staged changes
STAGED_FILES=$(git diff --name-only --cached 2>/dev/null || true)
if [[ -z "$STAGED_FILES" ]]; then
    exit 0
fi

# Check if any files under backbone/artifacts/changes/ are staged
CHANGE_FILES=$(echo "$STAGED_FILES" | grep -E '^backbone/artifacts/changes/' || true)
if [[ -z "$CHANGE_FILES" ]]; then
    exit 0
fi

# Detect which change folders have staged files
CHANGE_DIRS=$(echo "$CHANGE_FILES" | grep -oE '^backbone/artifacts/changes/CHNG-[0-9]+-[^/]+' | sort -u || true)

for change_dir in $CHANGE_DIRS; do
    echo -e "${CYAN}🔍 Checking change: ${change_dir#backbone/artifacts/changes/}${NC}"

    proposal_abs="$PROJECT_ROOT/$change_dir/proposal.md"
    tasks_abs="$PROJECT_ROOT/$change_dir/tasks.md"

    # ── Gate X: proposal REQ-XXX format ────────────────────────────────
    if [[ -f "$proposal_abs" ]]; then
        if grep -qE '(\*\*|###\s)REQ-[A-Z0-9]+(-[0-9]+)+' "$proposal_abs"; then
            echo -e "  ${GREEN}✓ Gate X: proposal.md has REQ-XXX requirements${NC}"
        else
            echo -e "  ${YELLOW}⚠  Gate X: proposal.md missing **REQ-XXX** bullets${NC}"
            echo -e "  ${YELLOW}   Add EARS requirements before committing.${NC}"
            ERRORS=$((ERRORS + 1))
        fi
    fi

    # ── Gate Y: task REQ traceability ───────────────────────────────────
    if [[ -f "$tasks_abs" ]]; then
        task_count=0
        while IFS= read -r line; do
            if echo "$line" | grep -qE '^\s*##\s*\[[xW ]\]'; then
                task_count=$((task_count + 1))
            fi
        done < <(grep -n '' "$tasks_abs" 2>/dev/null || true)

        # Simpler check: does every task have a **Parent:** line?
        task_lines=$(grep -cE '^\s*##\s*\[' "$tasks_abs" 2>/dev/null || true)
        parent_lines=$(grep -cE '\*\*Parent:\*\*\s*REQ-[A-Z0-9]+-[0-9]+' "$tasks_abs" 2>/dev/null || true)

        if [[ "$task_lines" -eq "$parent_lines" && "$task_lines" -gt 0 ]]; then
            echo -e "  ${GREEN}✓ Gate Y: tasks.md has **Parent: REQ-XXX** on all $task_lines tasks${NC}"
        elif [[ "$task_lines" -eq 0 ]]; then
            echo -e "  ${YELLOW}⚠  Gate Y: No tasks found in tasks.md${NC}"
        else
            echo -e "  ${YELLOW}⚠  Gate Y: $task_lines tasks but $parent_lines **Parent:** lines${NC}"
            echo -e "  ${YELLOW}   Each task needs a **Parent: REQ-XXX** line.${NC}"
            ERRORS=$((ERRORS + 1))
        fi
    fi
done

if [[ $ERRORS -gt 0 ]]; then
    echo ""
    echo -e "${YELLOW}⚠  Change gate(s) failed with $ERRORS issue(s). Fix and re-commit.${NC}"
    exit 1
fi

exit 0
