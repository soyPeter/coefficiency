#!/bin/bash
# PostToolUse/Bash hook: After a git commit, check if backbone DoD docs were updated.
# Installed via: scripts/setup-hooks.sh
# Reads stdin JSON to detect successful commit events.
# Fast: < 2s, silent when all DoD docs are present.

INPUT=$(cat)

# Fast-path: only proceed if this was a git commit command
COMMAND=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('command',''))" 2>/dev/null || true)

# Check if command is a git commit (not git log, git status, etc.)
if ! echo "$COMMAND" | grep -qE "^git commit|^git -c .* commit"; then
  exit 0
fi

# Check if output looks like a successful commit (git prints [branch hash] on success)
OUTPUT=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_response',{}).get('output',''))" 2>/dev/null || true)

if ! echo "$OUTPUT" | grep -qE "^\[[^\]]+ [a-f0-9]+"; then
  # Not a successful commit output, skip
  exit 0
fi

# Get the list of files changed in HEAD commit
CHANGED_FILES=$(git show --name-only --format="" HEAD 2>/dev/null || true)

# Check which backbone docs were touched
TASKS_UPDATED=$(echo "$CHANGED_FILES" | grep -c "backbone/3-TASKS.md" || echo 0)
DECISIONS_UPDATED=$(echo "$CHANGED_FILES" | grep -c "backbone/5-DECISIONS.md" || echo 0)
MEMORY_UPDATED=$(echo "$CHANGED_FILES" | grep -c "backbone/6-MEMORY.md" || echo 0)

# If all three updated, validate content quality (then exit silently if clean)
if [ "$TASKS_UPDATED" -gt 0 ] && [ "$DECISIONS_UPDATED" -gt 0 ] && [ "$MEMORY_UPDATED" -gt 0 ]; then
  if [ "${SKIP_DOD_VALIDATE:-0}" != "1" ]; then
    bash scripts/hooks/validate-dod-content.sh
  fi
  exit 0
fi

# Build list of missing docs
MISSING=""
[ "$TASKS_UPDATED" -eq 0 ] && MISSING="$MISSING\n  - backbone/3-TASKS.md  (mark task [x], update [WIP] → [x])"
[ "$DECISIONS_UPDATED" -eq 0 ] && MISSING="$MISSING\n  - backbone/5-DECISIONS.md  (record any architectural decisions made)"
[ "$MEMORY_UPDATED" -eq 0 ] && MISSING="$MISSING\n  - backbone/6-MEMORY.md  (record insights, pitfalls, patterns discovered)"

# Check if backbone files changed but VERSION not updated
BACKBONE_FILES_CHANGED=$(echo "$CHANGED_FILES" | grep -E "^backbone/|^templates/" || true)
VERSION_CHANGED=$(echo "$CHANGED_FILES" | grep -E "^backbone/VERSION$|^templates/backbone/VERSION$" || true)

if [ -n "$BACKBONE_FILES_CHANGED" ] && [ -z "$VERSION_CHANGED" ]; then
  echo ""
  echo "⚠️  VERSION GATE — backbone files changed but VERSION not updated!"
  echo ""
  echo "  Changed backbone files:"
  echo "$BACKBONE_FILES_CHANGED" | sed 's/^/     - /'
  echo ""
  echo "  Per 8-WORKFLOW.md Definition of Done, you MUST also update:"
  echo "     - backbone/VERSION"
  echo "     - All <!-- VERSION: --> headers in skeleton .md files"
  echo ""
  echo "  Version format: YYYY.MM.DD (CalVer)"
  echo "  Example: 2026.04.14"
  echo ""
fi

echo ""
echo "📋 DOD REMINDER — Backbone docs not updated in this commit:"
echo -e "$MISSING"
echo ""
echo "  Per backbone/8-WORKFLOW.md Definition of Done, update these"
echo "  before this task is considered complete. Add to next commit."
echo ""

exit 0
