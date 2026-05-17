#!/bin/bash
# validate-dod-content.sh: Validates Definition of Done documentation quality
# Called by: post-commit-dod-reminder.sh when backbone docs are present in commit
# Purpose: Check that DoD docs have meaningful content, not TODO/TBD placeholders
# 
# Expected format (pointer pattern):
# ## Decision N: Title
# **Context:** [1-2 sentence summary]
# **Decision:** Full decision at [[decisions/YYYYMMDD-title.md]]
# **Why:** [1-2 sentence rationale]
#
# Or inline format (deprecated, but accepted):
# ## Decision N: Title
# **Context:** ...full context...
# **Decision:** ...full decision...
# **Why:** ...explanation...

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

CONTENT_ERRORS=0

# Validate 5-DECISIONS.md: Check for placeholders and completeness
validate_decisions() {
  local file="backbone/5-DECISIONS.md"

  if [ ! -f "$file" ]; then
    return 0
  fi

  # Check for placeholder text
  if grep -inE "(TODO|TBD|FIXME|Coming soon|Not yet documented)" "$file" 2>/dev/null | head -3 > /tmp/dod_placeholders_$$.txt; then
    if [ -s /tmp/dod_placeholders_$$.txt ]; then
      echo -e "${RED}❌ Placeholder text found in $file:${NC}"
      cat /tmp/dod_placeholders_$$.txt | while read -r line; do
        echo "   ↳ $line"
      done
      CONTENT_ERRORS=$((CONTENT_ERRORS + 1))
    fi
    rm -f /tmp/dod_placeholders_$$.txt
  fi

  # Check decision completeness: each Decision N should have **Context:**, **Decision:**, **Why:**
  # Accepts POINTER format: **Decision:** Full decision at [[decisions/YYYYMMDD-title.md]]
  # Or inline format: **Decision:** ...full decision...
  awk '
    /^## Decision [0-9]+:/ {
      if (decision_start > 0 && (!has_context || !has_decision || !has_why)) {
        print "  Line " decision_start ": Missing required sections (need Context, Decision, Why)"
        exit_code = 1
      }
      decision_start = NR
      decision_title = $0
      has_context = 0
      has_decision = 0
      has_why = 0
      next
    }
    /^\*\*Context:/ { has_context = 1; next }
    /^\*\*Decision:/ { 
      has_decision = 1
      # Check if it's a pointer to detail file
      if (match($0, /\[\[.*\]\]/)) {
        is_pointer = 1
      }
      next 
    }
    /^\*\*Why:/ { has_why = 1; next }
    END {
      if (decision_start > 0 && (!has_context || !has_decision || !has_why)) {
        print "  Line " decision_start ": Missing required sections (need Context, Decision, Why)"
        exit_code = 1
      }
      if (exit_code == 1) {
        print "" > "/tmp/dod_incomplete_decisions_$$.txt"
      }
    }
  ' "$file" 2>/dev/null > /tmp/dod_incomplete_decisions_$$.txt

  if [ -f /tmp/dod_incomplete_decisions_$$.txt ] && [ -s /tmp/dod_incomplete_decisions_$$.txt ]; then
    echo -e "${RED}❌ Incomplete decision entries in $file:${NC}"
    cat /tmp/dod_incomplete_decisions_$$.txt
    CONTENT_ERRORS=$((CONTENT_ERRORS + 1))
    rm -f /tmp/dod_incomplete_decisions_$$.txt
  fi
}

# Validate 1-PRD.md: Check for placeholders and pointer format
validate_prd() {
  local file="backbone/1-PRD.md"

  if [ ! -f "$file" ]; then
    return 0
  fi

  # Check for placeholder text
  if grep -inE "(TODO|TBD|FIXME|Coming soon|Not yet documented)" "$file" 2>/dev/null | head -3 > /tmp/dod_prd_placeholders_$$.txt; then
    if [ -s /tmp/dod_prd_placeholders_$$.txt ]; then
      echo -e "${RED}❌ Placeholder text found in $file:${NC}"
      cat /tmp/dod_prd_placeholders_$$.txt | while read -r line; do
        echo "   ↳ $line"
      done
      CONTENT_ERRORS=$((CONTENT_ERRORS + 1))
    fi
    rm -f /tmp/dod_prd_placeholders_$$.txt
  fi
}

# Validate 3-TASKS.md: Check for placeholders
validate_tasks() {
  local file="backbone/3-TASKS.md"

  if [ ! -f "$file" ]; then
    return 0
  fi

  # Check for placeholder text (TODO/TBD at start of list items)
  if grep -nE "^- (TODO|TBD|FIXME)" "$file" 2>/dev/null | head -3 > /tmp/dod_tasks_placeholders_$$.txt; then
    if [ -s /tmp/dod_tasks_placeholders_$$.txt ]; then
      echo -e "${RED}❌ Placeholder text found in $file:${NC}"
      cat /tmp/dod_tasks_placeholders_$$.txt | while read -r line; do
        echo "   ↳ $line"
      done
      CONTENT_ERRORS=$((CONTENT_ERRORS + 1))
    fi
    rm -f /tmp/dod_tasks_placeholders_$$.txt
  fi
}

# Validate that the HEAD commit actually marks a task [x] in 3-TASKS.md
# Warning only — does not increment CONTENT_ERRORS or block the commit.
validate_task_completion() {
  local file="backbone/3-TASKS.md"

  TASKS_DIFF=$(git show HEAD -- "$file" 2>/dev/null || true)
  if [ -z "$TASKS_DIFF" ]; then
    return 0  # 3-TASKS.md not changed in HEAD — nothing to check
  fi

  # Look for lines newly added that contain [x] (completed tasks)
  if ! echo "$TASKS_DIFF" | grep -qE '^\+.*\[x\]'; then
    echo ""
    echo -e "${YELLOW}⚠️  No task marked [x] in backbone/3-TASKS.md in this commit.${NC}"
    echo "   If a task was completed, mark it [x] before the DoD commit."
    echo "   If this commit only updates docs mid-task, ignore this warning."
    echo ""
  fi
}

# Run validations
validate_decisions
validate_prd
validate_tasks
validate_task_completion

# Output results
if [ $CONTENT_ERRORS -gt 0 ]; then
  echo ""
  echo -e "${YELLOW}DoD content quality check found issues. To skip: SKIP_DOD_VALIDATE=1 git commit${NC}"
  exit 1
fi

exit 0