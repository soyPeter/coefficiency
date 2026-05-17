#!/bin/bash
# PreToolUse/Bash hook: Guard against destructive bash commands
# Installed via: scripts/setup-hooks.sh
# Fires before every Bash tool call Claude makes.
# Exit 2 = block command (reason shown to Claude)
# Exit 0 = allow (optional warning shown to Claude)

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(d.get('tool_input', {}).get('command', ''))
" 2>/dev/null || true)

if [ -z "$COMMAND" ]; then
  exit 0
fi

# --- HIGH-RISK: BLOCK (exit 2) ---
# Claude must reconsider or explicitly ask the user before proceeding.
block_if_matches() {
  local label="$1"
  local reason="$2"
  shift 2
  for pattern in "$@"; do
    if echo "$COMMAND" | grep -qiE "$pattern"; then
      echo ""
      echo "🚫 BLOCKED: Destructive command intercepted"
      echo "   Command : $COMMAND"
      echo "   Risk    : $reason"
      echo ""
      echo "   This action is irreversible and could cause data or history loss."
      echo "   Before proceeding:"
      echo "   1. Confirm the user explicitly requested this exact action"
      echo "   2. Verify there is no safer alternative (e.g. git stash, git revert)"
      echo "   3. Use AskUserQuestion to get explicit user approval"
      echo ""
      exit 2
    fi
  done
}

block_if_matches "git-reset-hard" \
  "Discards ALL uncommitted changes permanently — cannot be undone" \
  "git reset --hard"

block_if_matches "git-clean" \
  "Permanently deletes untracked files from the working tree" \
  "git clean -f" "git clean -fd" "git clean -ffd"

block_if_matches "git-force-push" \
  "Overwrites remote history — can destroy collaborators' commits" \
  "git push --force" "git push -f " "git push -f$"

block_if_matches "rm-rf-root" \
  "Recursive deletion from or near root — catastrophic blast radius" \
  "rm -rf /" "rm -rf ~" "rm -rf \."

block_if_matches "drop-database" \
  "Destroys an entire database and all its data" \
  "DROP\s+DATABASE" "drop\s+database"

block_if_matches "drop-table" \
  "Destroys a table and all its rows permanently" \
  "DROP\s+TABLE" "drop\s+table"

block_if_matches "truncate-table" \
  "Deletes all rows from a table — no WHERE clause, no rollback" \
  "TRUNCATE\s+TABLE" "truncate\s+table"

# --- MEDIUM-RISK: WARN but allow (exit 0 with message) ---
# Informational — Claude can proceed but should be aware.
warn_if_matches() {
  local reason="$1"
  shift
  for pattern in "$@"; do
    if echo "$COMMAND" | grep -qiE "$pattern"; then
      echo ""
      echo "⚠️  RISKY COMMAND: $COMMAND"
      echo "   Risk: $reason"
      echo "   Proceeding — verify this is intentional."
      echo ""
      exit 0
    fi
  done
}

warn_if_matches "Discards uncommitted changes in specific files" \
  "git checkout -- " "git restore "

warn_if_matches "Permanently deletes a stash entry" \
  "git stash drop"

warn_if_matches "Deletes a branch (unmerged commits lost with -D)" \
  "git branch -[Dd] "

warn_if_matches "Deletes a local tag" \
  "git tag -d "

warn_if_matches "Amending a commit rewrites history (risky on shared branches)" \
  "git commit --amend"

exit 0
