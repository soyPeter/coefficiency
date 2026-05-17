#!/bin/bash
# .claude/hooks/check-dod.sh
# Triggered on Stop (when Claude finishes responding).
# Checks if any WIP tasks remain in 3-TASKS.md and injects a DoD reminder.
# Non-blocking — uses additionalContext to remind, not to halt.

TASKS_FILE="$CLAUDE_PROJECT_DIR/backbone/3-TASKS.md"

WIP_LINE=$(grep "\[WIP\]" "$TASKS_FILE" 2>/dev/null | head -1)

if [ -n "$WIP_LINE" ]; then
  jq -n --arg wip "$WIP_LINE" '{
    "additionalContext": "⚠️ DEFINITION OF DONE — task still marked [WIP]:\n\($wip)\n\nBefore finishing, verify:\n□ backbone/3-TASKS.md → mark completed subtasks [x], remove [WIP]\n□ backbone/5-DECISIONS.md → document any architectural decisions made\n□ backbone/6-MEMORY.md → document lessons learned or traps found\n□ git commit created (Conventional Commits format)"
  }'
fi

exit 0
