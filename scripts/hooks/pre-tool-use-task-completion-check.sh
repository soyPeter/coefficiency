#!/bin/bash
# pre-tool-use-task-completion-check.sh: Block marking tasks [x] without
# acceptance criteria verification.
#
# Fires BEFORE Write/Edit to backbone/3-TASKS.md when adding [x].
# Checks that acceptance criteria from the referenced PRD are satisfied
# (traceability shows code + tests for all REQ-IDs).
#
# Override: export CLAUDE_CODE_SKIP_TASK_COMPLETION=1

set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"

# Skip if override is set
if [ "${CLAUDE_CODE_SKIP_TASK_COMPLETION:-0}" = "1" ]; then
    exit 0
fi

# Read stdin JSON from Claude Code
INPUT=$(cat)
[ -z "$INPUT" ] && exit 0

# Parse tool and file path
TOOL=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_name',''))" 2>/dev/null || true)
TARGET_FILE=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))" 2>/dev/null || true)

# Only check Write/Edit to 3-TASKS.md
if [[ "$TOOL" != "Write" && "$TOOL" != "Edit" ]]; then
    exit 0
fi

# Only check backbone/3-TASKS.md
if [[ "$TARGET_FILE" != *"backbone/3-TASKS.md"* ]]; then
    exit 0
fi

# Get the file content being written (for Write tool)
# or the replacement text (for Edit tool)
CONTENT=$(echo "$INPUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
tool = d.get('tool_name', '')
if tool == 'Write':
    print(d.get('tool_input', {}).get('content', ''))
elif tool == 'Edit':
    print(d.get('tool_input', {}).get('old_string', '') + '\n---TO---\n' + d.get('tool_input', {}).get('new_string', ''))
" 2>/dev/null || true)

if [ -z "$CONTENT" ]; then
    exit 0
fi

# Check if this edit adds any [x] markers
# For Write: check full content
# For Edit: check new_string portion
NEW_STRING=$(echo "$CONTENT" | sed -n '/---TO---/,$p' | tail -n +2 || echo "$CONTENT")

if ! echo "$NEW_STRING" | grep -qE '^\s*-\s*\[x\]'; then
    # No [x] being added in this edit
    exit 0
fi

# Source the shared library
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd)"
source "$LIB_DIR/task-acceptance-check.sh"

# Validate each newly-[x] task
errors=0
while IFS= read -r task_line; do
    [ -z "$task_line" ] && continue

    if ! check_task_completion "$PROJECT_DIR" "$task_line"; then
        errors=$((errors + 1))
    fi
done <<< "$(echo "$NEW_STRING" | grep -E '^\s*-\s*\[x\]')"

if [ "$errors" -gt 0 ]; then
    echo ""
    echo "  Override: export CLAUDE_CODE_SKIP_TASK_COMPLETION=1"
    echo ""
    exit 1
fi

exit 0
