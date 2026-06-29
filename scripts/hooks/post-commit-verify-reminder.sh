#!/bin/bash
# post-commit-verify-reminder.sh: Remind to run /backbone:verify after feat/fix commits
#
# Fires after each git commit when the commit message contains feat: or fix: types.
# Checks if /backbone:verify would be useful (code was committed, not docs-only).
# Advisory only — does not block.
#
# Installed via: scripts/setup-hooks.sh (PostCommit hook)

set -euo pipefail

YELLOW='\033[1;33m'
NC='\033[0m'

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Get the commit message
COMMIT_MSG=$(git log -1 --pretty=%B 2>/dev/null || true)
[ -z "$COMMIT_MSG" ] && exit 0

# Only remind for feat/fix commits (docs-only or chore don't need verify)
FIRST_LINE=$(echo "$COMMIT_MSG" | head -1)
if ! echo "$FIRST_LINE" | grep -qE '^(feat|fix)(\([a-z0-9_-]+\))?:'; then
    exit 0
fi

# Check if code files were committed (not just docs)
CHANGED_FILES=$(git diff --name-only HEAD~1..HEAD 2>/dev/null || true)
CODE_FILES=$(echo "$CHANGED_FILES" | grep -E '\.(java|kt|go|py|js|ts|tsx|sh|rs|rb|php|c|cpp)$' || true)

if [ -z "$CODE_FILES" ]; then
    exit 0
fi

# Count changed files
FILE_COUNT=$(echo "$CHANGED_FILES" | wc -l | tr -d ' ')

echo ""
echo -e "${YELLOW}🔍 REMINDER: Run /backbone:verify after this commit${NC}"
echo -e "${YELLOW}   ${FILE_COUNT} file(s) changed in feat/fix commit.${NC}"
echo -e "${YELLOW}   Full verification ensures tests, build, security, and traceability pass.${NC}"
echo -e "${YELLOW}   If any task is complete, also mark [x] in backbone/3-TASKS.md.${NC}"
echo ""

exit 0
