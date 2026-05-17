#!/bin/bash
# pre-commit-skill-check.sh: Gate S→C — Block commits without skill acknowledgment
#
# Cross-agent enforcement: works with Claude Code, OpenCode, Cursor, etc.
# Checks that required skills for modified files are acknowledged.
#
# Acknowledgment methods (any one is sufficient):
#   1. .backbone/session/skills.json contains the skill
#   2. Commit message contains "Skills: skill1, skill2, ..."
#
# Override: export SKIP_SKILL_CHECK=1

set -euo pipefail

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-.}"

# Skip if override is set
if [ "${SKIP_SKILL_CHECK:-0}" = "1" ]; then
    exit 0
fi

# Load skill mapping library
source "$PROJECT_ROOT/scripts/lib/skill-mapping.sh"

# Get staged files (excluding deleted)
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null || true)

if [ -z "$STAGED_FILES" ]; then
    exit 0
fi

# Get required skills for all staged files
REQUIRED_SKILLS=$(get_required_skills_for_files "$STAGED_FILES")

if [ -z "$REQUIRED_SKILLS" ]; then
    exit 0
fi

# Get commit message (if any staged)
COMMIT_MSG=""
if [ -f ".git/COMMIT_EDITMSG" ]; then
    COMMIT_MSG=$(cat ".git/COMMIT_EDITMSG" 2>/dev/null || true)
fi

# Check each required skill
MISSING_SKILLS=""
for skill in $REQUIRED_SKILLS; do
    if ! is_skill_acknowledged "$skill" "$COMMIT_MSG"; then
        MISSING_SKILLS="$MISSING_SKILLS\n  - $skill"
    fi
done

if [ -z "$MISSING_SKILLS" ]; then
    echo -e "${GREEN}✅ Skill acknowledgment check passed${NC}"
    exit 0
fi

# Some skills are missing — block commit
echo ""
echo -e "${YELLOW}❌ SKILL GATE S→C NOT SATISFIED${NC}"
echo ""
echo "  You modified files that require skill acknowledgment."
echo ""
echo "  Missing skill acknowledgments:"
echo -e "$MISSING_SKILLS"
echo ""
echo "  Files that triggered these requirements:"
echo "$STAGED_FILES" | while IFS= read -r file; do
    [ -z "$file" ] && continue
    mapped_skill=$(get_skill_for_file "$file")
    if [ -n "$mapped_skill" ]; then
        echo "    $file → $mapped_skill"
    fi
done
echo ""
echo "  How to acknowledge (choose one):"
echo ""
echo "  Option 1 — Session file (any agent):"
echo "    mkdir -p .backbone/session"
echo "    echo '{\"java/java-core\": true, \"quarkus/java-quarkus\": true}' > .backbone/session/skills.json"
echo "    git add .backbone/session/skills.json"
echo ""
echo "  Option 2 — Commit message (any agent):"
echo "    git commit -m 'feat(auth): add OAuth login' -m 'Skills: java-core, java-quarkus'"
echo ""
echo "  Option 3 — Load the skill in your agent session:"
echo "    view backbone/skills/java/java-core/SKILL.md"
echo "    Then acknowledge by adding to .backbone/session/skills.json"
echo ""
echo "  Or override: export SKIP_SKILL_CHECK=1"
echo ""
exit 1
