#!/usr/bin/env bash
#<!-- VERSION: 2026.05.29 -->
# PostToolUse Planning Boundary Check
# Trigger: PostToolUse on Write/Edit to backbone/*.md files
# Behavior: Advisory reminder to sync STATE.md when planning files change
# Complements: post-tool-use-planning-sync.sh (which auto-syncs)
# Rationale: Catches edge cases where auto-sync might miss updates

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

# Only process Write and Edit
[ "$tool_name" != "Write" ] && [ "$tool_name" != "Edit" ] && exit 0

# Extract file_path
file_path=$(echo "$INPUT" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)"$/\1/' || true)

[ -z "$file_path" ] && exit 0

# Only check backbone/*.md files
if ! echo "$file_path" | grep -qE '^backbone/.*\.md$'; then
    exit 0
fi

# Skip STATE.md itself (no need to remind about syncing STATE when editing STATE)
if echo "$file_path" | grep -q 'STATE\.md$'; then
    exit 0
fi

# Skip 6-MEMORY.md (memory file doesn't need STATE sync)
if echo "$file_path" | grep -q '6-MEMORY\.md$'; then
    exit 0
fi

filename=$(basename "$file_path")

# Advisory output (does not block)
cat <<EOF
{"decision":"allow","reminder":"PLANNING BOUNDARY: '$filename' was modified. Ensure backbone/artifacts/changes/STATE.md reflects this change. The auto-sync hook should handle this, but verify the update is accurate."}
EOF

exit 0
