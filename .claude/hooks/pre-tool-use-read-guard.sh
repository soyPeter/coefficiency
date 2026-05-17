#!/usr/bin/env bash
#<!-- VERSION: 2026.04.25 -->
# PreToolUse Read-Before-Edit Guard
# Trigger: PreToolUse on Write/Edit targeting existing files
# Behavior: Blocks edit if file exists but was not read in current session
# Exemption: Claude Code natively enforces read-before-edit
# Rationale: Non-Claude runtimes (OpenCode, Copilot) don't enforce this,
#            causing infinite retry loops when models attempt edits without reading

set -euo pipefail

# Silent fail — never break the agent
handle_error() {
    exit 0
}
trap handle_error ERR

# Read stdin with timeout
INPUT=""
if IFS= read -r -t 10 INPUT; then
    : # success
else
    exit 0
fi

[ -z "$INPUT" ] && exit 0

# Parse JSON (lightweight extraction)
tool_name=""
file_path=""

# Extract tool_name
tool_name=$(echo "$INPUT" | grep -o '"tool_name"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"\([^"]*\)"$/\1/' || true)

# Only process Write and Edit
[ "$tool_name" != "Write" ] && [ "$tool_name" != "Edit" ] && exit 0

# Extract file_path
file_path=$(echo "$INPUT" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)"$/\1/' || true)

[ -z "$file_path" ] && exit 0

# Skip if file doesn't exist (new files don't need prior Read)
[ ! -f "$file_path" ] && exit 0

# Skip exclusions (binary files, generated files, logs)
skip_patterns='\.git/|node_modules/|dist/|build/|\.class$|\.jar$|\.zip$|\.png$|\.jpg$|\.gif$|\.pdf$|\.log$|\.tmp$|\.cache$'
if echo "$file_path" | grep -qiE "$skip_patterns"; then
    exit 0
fi

# Claude Code exemption: natively enforces read-before-edit
# Detection signals (in priority order):
# 1. session_id in hook stdin payload (Claude Code schema)
# 2. CLAUDE_CODE_ENTRYPOINT / CLAUDE_CODE_SSE_PORT env vars
# 3. CLAUDE_SESSION_ID / CLAUDECODE env vars (back-compat)
is_claude_code=false
if echo "$INPUT" | grep -q '"session_id"'; then
    is_claude_code=true
elif [ -n "${CLAUDE_CODE_ENTRYPOINT:-}" ] || [ -n "${CLAUDE_CODE_SSE_PORT:-}" ]; then
    is_claude_code=true
elif [ -n "${CLAUDE_SESSION_ID:-}" ] || [ -n "${CLAUDECODE:-}" ]; then
    is_claude_code=true
fi

if [ "$is_claude_code" = true ]; then
    exit 0
fi

# Check if file was read in current session
# We use a session tracking file to record Read operations
SESSION_TRACKER="/tmp/backbone-read-tracker-$(date +%Y%m%d).log"

file_was_read=false
if [ -f "$SESSION_TRACKER" ]; then
    # Normalize path for comparison (resolve relative paths)
    normalized_path=$(cd "$(dirname "$file_path")" 2>/dev/null && pwd)/$(basename "$file_path") 2>/dev/null || echo "$file_path"
    if grep -qxF "$normalized_path" "$SESSION_TRACKER" 2>/dev/null; then
        file_was_read=true
    fi
fi

if [ "$file_was_read" = false ]; then
    filename=$(basename "$file_path")
    cat <<EOF
{"decision":"block","reason":"READ-BEFORE-EDIT REQUIRED: You are attempting to modify '$filename' which already exists, but you have not read it in this session. Non-Claude runtimes require explicit Read before Edit to prevent infinite retry loops. Use the Read tool on '$file_path' first, then retry your edit."}
EOF
    exit 0
fi

# File was read — allow the edit
exit 0
