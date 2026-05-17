#!/bin/bash
# post-doc-check.sh: Bidirectional documentation validation
# Type: PostToolUse hook
# Purpose: Detect writes to detail directories and verify corresponding index files were updated
#
# Checks:
# - backbone/decisions/*.md created → 5-DECISIONS.md updated?
# - 5-DECISIONS.md updated → corresponding detail file exists?
# - backbone/prd/*.md created → 1-PRD.md updated?
# - 1-PRD.md updated → corresponding detail file exists?
# - backbone/tasks/*.md created → 3-TASKS.md updated?
# - 3-TASKS.md updated → corresponding detail file exists?

YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

# Get the files that were modified in this session
# Claude Code provides these via environment or we check git status
GET_MODIFIED_FILES() {
    git status --porcelain 2>/dev/null | grep -E "^(A|M)" | awk '{print $2}' | grep -E "^backbone/" || true
}

# Check if index file was modified
INDEX_MODIFIED() {
    local index_file="$1"
    git diff --cached --name-only 2>/dev/null | grep -q "$index_file" && return 0
    git diff --name-only 2>/dev/null | grep -q "$index_file" && return 0
    return 1
}

# Extract decision number from detail file
GET_DECISION_NUM() {
    local file="$1"
    basename "$file" | grep -oE "^[0-9]+" || true
}

echo -e "${YELLOW}🔍 Running documentation bidirectional checks...${NC}"

WARNINGS=0

# ===== CHECK 1: Decisions =====
# 1a. Check if detail files created/added but index not updated
if [ -d "backbone/decisions" ]; then
    DECISION_DETAILS=$(git diff --name-only 2>/dev/null | grep "backbone/decisions/" || true)
    if [ -n "$DECISION_DETAILS" ]; then
        if ! INDEX_MODIFIED "backbone/5-DECISIONS.md"; then
            echo -e "${YELLOW}⚠️  Decision detail file(s) created but 5-DECISIONS.md not updated:${NC}"
            echo "$DECISION_DETAILS" | while read -r file; do
                echo "   ↳ $file"
            done
            echo "   → Add pointer to 5-DECISIONS.md: ## Decision N: Title"
            echo "   → Format: **Decision:** Full decision at [[decisions/YYYYMMDD-title.md]]"
            WARNINGS=$((WARNINGS + 1))
        fi
    fi
fi

# 1b. Check if index updated but no detail file
if INDEX_MODIFIED "backbone/5-DECISIONS.md"; then
    # Extract decision numbers from modified 5-DECISIONS.md
    DECISION_NUMS=$(git diff HEAD -- "backbone/5-DECISIONS.md" 2>/dev/null | grep -oE "## Decision [0-9]+:" | grep -oE "[0-9]+" || true)
    
    if [ -n "$DECISION_NUMS" ]; then
        for dec_num in $DECISION_NUMS; do
            # Check if corresponding detail file exists
            DETAIL_FILE=$(ls "backbone/decisions/${dec_num}"-*.md 2>/dev/null | head -1 || true)
            if [ -z "$DETAIL_FILE" ]; then
                echo -e "${YELLOW}⚠️  5-DECISIONS.md references Decision $dec_num but no detail file in backbone/decisions/${dec_num}-*.md${NC}"
                WARNINGS=$((WARNINGS + 1))
            fi
        done
    fi
fi

# ===== CHECK 2: PRD =====
if [ -d "backbone/prd" ]; then
    PRD_DETAILS=$(git diff --name-only 2>/dev/null | grep "backbone/prd/" || true)
    if [ -n "$PRD_DETAILS" ]; then
        if ! INDEX_MODIFIED "backbone/1-PRD.md"; then
            echo -e "${YELLOW}⚠️  PRD detail file(s) created but 1-PRD.md not updated:${NC}"
            echo "$PRD_DETAILS" | while read -r file; do
                echo "   ↳ $file"
            done
            WARNINGS=$((WARNINGS + 1))
        fi
    fi
fi

# ===== CHECK 3: Tasks =====
if [ -d "backbone/tasks" ]; then
    TASKS_DETAILS=$(git diff --name-only 2>/dev/null | grep "backbone/tasks/" || true)
    if [ -n "$TASKS_DETAILS" ]; then
        if ! INDEX_MODIFIED "backbone/3-TASKS.md"; then
            echo -e "${YELLOW}⚠️  Task detail file(s) created but 3-TASKS.md not updated:${NC}"
            echo "$TASKS_DETAILS" | while read -r file; do
                echo "   ↳ $file"
            done
            WARNINGS=$((WARNINGS + 1))
        fi
    fi
fi

# Output summary
if [ $WARNINGS -gt 0 ]; then
    echo ""
    echo -e "${YELLOW}Documentation sync warnings: $WARNINGS${NC}"
    echo "Tip: Use pointer format in index files:"
    echo "  ## Decision N: Title"
    echo "  **Decision:** Full decision at [[decisions/YYYYMMDD-title.md]]"
    echo ""
fi

exit 0