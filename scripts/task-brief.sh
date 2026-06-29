#!/bin/bash
# scripts/task-brief.sh — Extract a single task from a plan file as a handoff brief
#
# Reads tasks.md and extracts task N as a standalone file for subagent dispatch.
# This keeps the orchestrator from pasting task text into prompts.
#
# Usage:
#   ./scripts/task-brief.sh path/to/tasks.md N
#
# Output: prints path to temp file containing the extracted task brief.

set -euo pipefail

if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <tasks.md> <task-number>" >&2
    echo "  Extracts task N from the plan file as a standalone brief." >&2
    exit 1
fi

TASKS_FILE="$1"
TASK_NUM="$2"

if [[ ! -f "$TASKS_FILE" ]]; then
    echo "Error: tasks file not found: $TASKS_FILE" >&2
    exit 1
fi

TMPDIR="${TMPDIR:-/tmp}"
BRIEF_FILE="$TMPDIR/task-${TASK_NUM}-brief-$(date +%s).md"

# Extract the task section using awk — find "### Task N:" header, print until next "### Task" or EOF
awk -v task="Task $TASK_NUM:" '
    /^### Task / {
        if (found) exit
        if (index($0, task) > 0) { found=1; print; next }
    }
    found { print }
' "$TASKS_FILE" > "$BRIEF_FILE"

if [[ ! -s "$BRIEF_FILE" ]]; then
    # Try alternate format: "## [ ]" with task ref
    awk -v num="$TASK_NUM" '
        BEGIN { found=0 }
        /^## \[ \]/ {
            if (found) exit
            # Check if next lines reference this task number
            saved = $0
            getline next_line
            if (index(next_line, num) > 0 || index(next_line, "Task") > 0) {
                found=1
                print saved; print next_line
                while (getline > 0) {
                    if (/^## \[ \]|^### /) exit
                    print
                }
            }
        }
    ' "$TASKS_FILE" > "$BRIEF_FILE"
fi

if [[ ! -s "$BRIEF_FILE" ]]; then
    echo "Warning: Task $TASK_NUM not found in $TASKS_FILE" >&2
    echo "# Task $TASK_NUM: (not found in plan)" > "$BRIEF_FILE"
fi

# Add header with source reference
{
    echo "---"
    echo "source: $TASKS_FILE"
    echo "task: $TASK_NUM"
    echo "---"
    echo ""
    cat "$BRIEF_FILE"
} > "${BRIEF_FILE}.tmp" && mv "${BRIEF_FILE}.tmp" "$BRIEF_FILE"

echo "$BRIEF_FILE"
