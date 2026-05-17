#!/bin/bash
# .claude/hooks/check-conventions.sh
# Proxy script that calls the project-local validator if one exists.
# Falls back to no-op for projects that have no convention validator.

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.path // .tool_input.file_path // ""')
CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // .tool_input.new_string // ""')

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
VALIDATOR="$PROJECT_DIR/backbone/reference/validate.sh"

# Only run if the project has provided a validator
if [ -x "$VALIDATOR" ]; then
    "$VALIDATOR" --file "$FILE_PATH" --content "$CONTENT"
fi

exit 0
