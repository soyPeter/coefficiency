#!/bin/bash
# PreToolUse hook: Block Task subagents with conflicting file declarations
#
# Installed via: scripts/setup-hooks.sh
# Fires BEFORE each Claude Code Task tool use.
#
# PURPOSE:
#   Enforce AGENTS.md policy: "Sequential for conflicts — if two implementers
#   touch the same file, run sequentially."
#
# HOW IT WORKS:
#   1. Detects Task tool calls (subagent spawns)
#   2. Parses FILES: declaration from the prompt
#   3. Maintains .claude/subagent-registry.json with atomic locking
#   4. BLOCKS spawn if any declared file overlaps with a running subagent
#   5. Auto-removes stale entries after 15 minutes
#
# CONVENTION:
#   Subagents that write files MUST declare their targets in the prompt:
#
#     FILES: [dev-portal/src/pages/index.astro, dev-portal/src/lib/projects.ts]
#
#     You are backbone-implementer...
#
#   No FILES: declaration = conflicts not detectable = allowed silently
#
# Exit 0 = allow tool use
# Exit 1 = block tool use

set -euo pipefail

RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
REGISTRY_FILE="$PROJECT_DIR/.claude/subagent-registry.json"
LOCK_DIR="$PROJECT_DIR/.claude/subagent-registry.lock"
MAX_AGE_MINUTES=15

# ── Helpers ────────────────────────────────────────────────────────────────

# Acquire atomic lock using mkdir
acquire_lock() {
    local attempts=0
    while ! mkdir "$LOCK_DIR" 2>/dev/null; do
        attempts=$((attempts + 1))
        if [ "$attempts" -gt 50 ]; then
            # Lock held for >5 seconds, probably stale
            rmdir "$LOCK_DIR" 2>/dev/null || true
            mkdir "$LOCK_DIR" 2>/dev/null || {
                echo -e "${RED}❌ Subagent registry lock timeout${NC}" >&2
                exit 1
            }
            break
        fi
        sleep 0.1
    done
}

release_lock() {
    rmdir "$LOCK_DIR" 2>/dev/null || true
}

# Parse FILES: declaration from prompt text
# Supports: FILES: [file1, file2]  or  FILES: ["file1", "file2"]
# Portable — avoids grep -P (not available on macOS)
parse_files_declaration() {
    local prompt="$1"
    local files_line

    # Extract line starting with FILES:
    files_line=$(printf '%s\n' "$prompt" | grep -m1 '^FILES:' || true)

    if [ -z "$files_line" ]; then
        return 0
    fi

    # Extract content between brackets using sed (portable)
    local bracket_content
    bracket_content=$(printf '%s\n' "$files_line" | sed -n 's/^FILES:.*\[\(.*\)\].*/\1/p')

    if [ -z "$bracket_content" ]; then
        return 0
    fi

    # Split by comma, trim quotes and spaces, output one file per line
    # Use [[:space:]] instead of \s for BSD sed (macOS) compatibility
    printf '%s\n' "$bracket_content" | tr ',' '\n' | sed "s/^[[:space:]]*['\"]*//;s/['\"]*[[:space:]]*$//;s/^[[:space:]]*//;s/[[:space:]]*$//"
}

# Normalize file path for comparison (strip leading ./)
normalize_path() {
    local path="$1"
    # Remove leading ./
    path="${path#./}"
    # Remove leading /
    path="${path#/}"
    echo "$path"
}

# Check if two file lists overlap
have_overlap() {
    local new_files="$1"
    local existing_files="$2"

    while IFS= read -r new_file; do
        [ -z "$new_file" ] && continue
        local norm_new
        norm_new=$(normalize_path "$new_file")

        while IFS= read -r existing_file; do
            [ -z "$existing_file" ] && continue
            local norm_existing
            norm_existing=$(normalize_path "$existing_file")

            if [ "$norm_new" = "$norm_existing" ]; then
                echo "$norm_existing"
                return 0
            fi
        done <<< "$existing_files"
    done <<< "$new_files"

    return 1
}

# Remove stale entries from registry (older than MAX_AGE_MINUTES)
cleanup_stale_entries() {
    local now_epoch
    now_epoch=$(date +%s)
    local max_age_seconds=$((MAX_AGE_MINUTES * 60))

    if [ ! -f "$REGISTRY_FILE" ]; then
        return 0
    fi

    local cleaned
    cleaned=$(python3 -c "
import sys, json
from datetime import datetime, timezone

try:
    with open('$REGISTRY_FILE', 'r') as f:
        data = json.load(f)
except (json.JSONDecodeError, FileNotFoundError):
    print(json.dumps({'subagents': []}))
    sys.exit(0)

now = $now_epoch
max_age = $max_age_seconds
subagents = data.get('subagents', [])
cleaned = []

for s in subagents:
    started = s.get('started_at', '')
    try:
        started_epoch = int(datetime.fromisoformat(started.replace('Z', '+00:00')).timestamp())
        if now - started_epoch <= max_age:
            cleaned.append(s)
    except (ValueError, TypeError):
        pass  # Remove malformed entries

data['subagents'] = cleaned
print(json.dumps(data, indent=2))
" 2>/dev/null || echo '{"subagents": []}')

    echo "$cleaned" > "$REGISTRY_FILE"
}

# Add subagent entry to registry
# $1 = description, $2 = subagent_type, $3 = newline-separated files
add_registry_entry() {
    local description="$1"
    local subagent_type="$2"
    local files_list="$3"
    local now_iso
    now_iso=$(date -u +%Y-%m-%dT%H:%M:%SZ)

    # Build JSON safely using Python with stdin
    local updated
    updated=$(printf '%s\t%s\t%s\t%s\n' "$description" "$subagent_type" "$files_list" "$now_iso" | python3 -c "
import sys, json

description, subagent_type, files_list, now_iso = sys.stdin.read().strip().split('\t', 3)
files = [line.strip() for line in files_list.split('\n') if line.strip()]

entry = {
    'description': description,
    'subagent_type': subagent_type,
    'files': files,
    'started_at': now_iso
}

try:
    with open('$REGISTRY_FILE', 'r') as f:
        data = json.load(f)
except (json.JSONDecodeError, FileNotFoundError):
    data = {'subagents': []}

data['subagents'].append(entry)
print(json.dumps(data, indent=2))
" 2>/dev/null || echo '{"subagents": []}')

    echo "$updated" > "$REGISTRY_FILE"
}

# Get all files from existing registry entries
get_existing_files() {
    if [ ! -f "$REGISTRY_FILE" ]; then
        return 0
    fi

    python3 -c "
import json
try:
    with open('$REGISTRY_FILE', 'r') as f:
        data = json.load(f)
    for s in data.get('subagents', []):
        for file_path in s.get('files', []):
            print(file_path)
except (json.JSONDecodeError, FileNotFoundError):
    pass
" 2>/dev/null || true
}

# ── Main Logic ─────────────────────────────────────────────────────────────

# Skip if override env var is set (for emergency fixes)
if [ "${CLAUDE_CODE_SKIP_SUBAGENT_CONFLICT_CHECK:-0}" = "1" ]; then
    exit 0
fi

# ---- Light mode bypass ----
if [ -f "backbone/.MODE" ]; then
    MODE=$(tr -d '[:space:]' < "backbone/.MODE" 2>/dev/null || echo "standard")
    [ "$MODE" = "light" ] && echo "  🟢 LIGHT MODE: Advisory only — subagent conflict check skipped." && exit 0
fi

# Read stdin JSON from Claude Code
INPUT=$(cat)
[ -z "$INPUT" ] && exit 0

# Parse tool name
TOOL=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_name',''))" 2>/dev/null || true)

# Only check Task tools (subagent spawns)
if [[ "$TOOL" != "Task" ]]; then
    exit 0
fi

# Parse tool_input
TOOL_INPUT=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(json.dumps(d.get('tool_input',{})))" 2>/dev/null || true)
[ -z "$TOOL_INPUT" ] && exit 0

PROMPT=$(echo "$TOOL_INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('prompt',''))" 2>/dev/null || true)
SUBAGENT_TYPE=$(echo "$TOOL_INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('subagent_type',''))" 2>/dev/null || true)
DESCRIPTION=$(echo "$TOOL_INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('description',''))" 2>/dev/null || true)

# Skip if no prompt (malformed Task call)
[ -z "$PROMPT" ] && exit 0

# Extract FILES: declaration
DECLARED_FILES=$(parse_files_declaration "$PROMPT")

# If no FILES declaration, allow silently (not detectable)
if [ -z "$DECLARED_FILES" ]; then
    exit 0
fi

# Acquire lock
acquire_lock

# Clean up stale entries
cleanup_stale_entries

# Get existing files from registry
EXISTING_FILES=$(get_existing_files)

# Check for conflicts
CONFLICT_FILE=$(have_overlap "$DECLARED_FILES" "$EXISTING_FILES" || true)

if [ -n "$CONFLICT_FILE" ]; then
    # Conflict detected — find which subagent owns it
    CONFLICT_AGENT=$(python3 -c "
import json
try:
    with open('$REGISTRY_FILE', 'r') as f:
        data = json.load(f)
    for s in data.get('subagents', []):
        for fpath in s.get('files', []):
            norm = fpath.lstrip('./').lstrip('/')
            if norm == '$CONFLICT_FILE':
                print(f\"{s.get('subagent_type', 'unknown')} – {s.get('description', 'no description')}\")
                break
except (json.JSONDecodeError, FileNotFoundError):
    pass
" 2>/dev/null || echo "unknown subagent")

    release_lock

    echo ""
    echo -e "${RED}❌ SUBAGENT CONFLICT DETECTED${NC}"
    echo ""
    echo -e "${YELLOW}You are spawning a subagent that targets files already locked by a running subagent.${NC}"
    echo ""
    echo "  Conflict: $CONFLICT_FILE"
    echo "  Locked by: $CONFLICT_AGENT"
    echo ""
    echo -e "${BLUE}AGENTS.md policy:${NC} Sequential for conflicts — if two implementers"
    echo "touch the same file, run sequentially."
    echo ""
    echo "Options:"
    echo "  1. Wait for the existing subagent to complete (auto-expires in ${MAX_AGE_MINUTES} min)"
    echo "  2. Spawn sequentially instead of in parallel"
    echo "  3. Change your FILES: declaration to target different files"
    echo ""
    echo "To override (emergency only):"
    echo "  export CLAUDE_CODE_SKIP_SUBAGENT_CONFLICT_CHECK=1"
    echo ""
    echo "This is enforced by scripts/hooks/pre-tool-use-subagent-conflict-check.sh"
    echo ""

    exit 1
fi

# No conflict — add to registry
add_registry_entry "$DESCRIPTION" "$SUBAGENT_TYPE" "$DECLARED_FILES"

release_lock

exit 0
