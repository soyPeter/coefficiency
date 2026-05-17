#!/bin/bash
# pre-commit-commit-size.sh: Gate 17 — Block overly large commits
#
# Enforces incremental commits: each commit should represent ONE task.
# If a commit touches >10 files, it likely contains multiple tasks.
#
# Why: Pre-commit gates (skill check, grill check, planning check) only fire
# at commit time. If an agent writes 50 files and commits once, those gates
# fire once — too late to catch issues. By forcing commits per task (~1-5 files),
# gates fire frequently and catch problems early.
#
# Override: export SKIP_COMMIT_SIZE_CHECK=1

set -euo pipefail

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

# Skip if override is set
if [ "${SKIP_COMMIT_SIZE_CHECK:-0}" = "1" ]; then
    exit 0
fi

# Get staged files (excluding deleted)
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null || true)
FILE_COUNT=$(echo "$STAGED_FILES" | grep -c '^' || true)

if [ -z "$STAGED_FILES" ]; then
    exit 0
fi

# Threshold: >10 files is too large
THRESHOLD=10

if [ "$FILE_COUNT" -le "$THRESHOLD" ]; then
    exit 0
fi

echo ""
echo -e "${YELLOW}❌ COMMIT SIZE GATE VIOLATION${NC}"
echo ""
echo "  This commit touches $FILE_COUNT files (max allowed: $THRESHOLD)."
echo ""
echo "  Large commits indicate multiple tasks bundled together."
echo "  This defeats pre-commit enforcement gates (skill check, grill check, etc.)"
echo "  which only fire at commit time."
echo ""
echo "  Required: Commit incrementally — ONE task per commit."
echo ""
echo "  How to fix:"
echo "    1. Unstage files that belong to different tasks"
echo "       git reset HEAD <files-for-other-task>"
echo ""
echo "    2. Commit only files for the CURRENT task"
echo "       git commit -m 'feat(scope): what this single task does'"
echo ""
echo "    3. Stage and commit the remaining files separately"
echo "       git add <remaining-files>"
echo "       git commit -m 'feat(scope): next task'"
echo ""
echo "  Staged files ($FILE_COUNT):"
echo "$STAGED_FILES" | sed 's/^/    - /'
echo ""
echo "  See: backbone/skills/general/incremental-implementation/SKILL.md"
echo "  Or override: export SKIP_COMMIT_SIZE_CHECK=1"
echo ""
exit 1
