#!/usr/bin/env bash
#<!-- VERSION: 2026.04.25 -->
# PostToolUse Read Tracker
# Trigger: PostToolUse on Read tool calls
# Behavior: Records read file paths to session tracker for read-guard enforcement
# Companion: pre-tool-use-read-guard.sh checks this tracker before allowing edits

set -euo pipefail

# Silent fail — never break the agent
handle_error() {
    exit 0
}
trap handle_error ERR

# Read stdin with timeout
INPUT=""
if IFS= read -r -t 5 INPUT; then
    : # success
else
    exit 0
fi

[ -z "$INPUT" ] && exit 0

# Extract tool_name
tool_name=$(echo "$INPUT" | grep -o '"tool_name"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"\([^"]*\)"$/\1/' || true)

# Only process Read tool calls
[ "$tool_name" != "Read" ] && exit 0

# Extract file_path
file_path=$(echo "$INPUT" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)"$/\1/' || true)

[ -z "$file_path" ] && exit 0

# Skip non-existent files
[ ! -f "$file_path" ] && exit 0

# Normalize path
normalized_path=$(cd "$(dirname "$file_path")" 2>/dev/null && pwd)/$(basename "$file_path") 2>/dev/null || echo "$file_path"

# Record to session tracker
SESSION_TRACKER="/tmp/backbone-read-tracker-$(date +%Y%m%d).log"
echo "$normalized_path" >> "$SESSION_TRACKER"

exit 0
