#!/bin/bash
# Stop hook: Detect open [WIP] tasks in backbone/3-TASKS.md
# Installed via: scripts/setup-hooks.sh
# Fires after every Claude Code turn. Silent when no WIP found.
# Exit 0 always — warning only, never block.

TASKS_FILE="backbone/3-TASKS.md"

if [ ! -f "$TASKS_FILE" ]; then
  exit 0
fi

WIP_LINES=$(grep -n "\[WIP\]" "$TASKS_FILE" 2>/dev/null || true)

if [ -z "$WIP_LINES" ]; then
  # No WIP — still check commit frequency nudge before exiting
  MODIFIED=$(git status --short 2>/dev/null | grep -vE '^\?\?' | wc -l | tr -d ' ')
  if [ "${MODIFIED:-0}" -ge 5 ]; then
    echo ""
    echo "💾 COMMIT NUDGE: ${MODIFIED} file(s) have uncommitted changes."
    echo "  Consider committing your progress before ending this session."
    echo ""
  fi
  exit 0
fi

WIP_COUNT=$(echo "$WIP_LINES" | wc -l | tr -d ' ')

echo ""
echo "⚠️  WIP TASKS OPEN ($WIP_COUNT detected in backbone/3-TASKS.md):"
echo "$WIP_LINES" | while IFS= read -r line; do
  LINE_NUM=$(echo "$line" | cut -d: -f1)
  TASK_TEXT=$(echo "$line" | cut -d: -f2- | sed 's/^[[:space:]]*//')
  echo "  Line $LINE_NUM: $TASK_TEXT"
done
echo ""
echo "  Before ending this session: either complete the task (mark [x])"
echo "  or revert to [ ] if work was not started."
echo ""

# ── Commit frequency nudge ─────────────────────────────────────────────────────
# Separate concern: if many files are uncommitted, nudge to commit before closing.
MODIFIED=$(git status --short 2>/dev/null | grep -vE '^\?\?' | wc -l | tr -d ' ')
if [ "${MODIFIED:-0}" -ge 5 ]; then
  echo "💾 COMMIT NUDGE: ${MODIFIED} file(s) have uncommitted changes."
  echo "  Consider committing your progress before ending this session."
  echo ""
fi

exit 0
