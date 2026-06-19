#!/usr/bin/env bash
#<!-- VERSION: 2026.05.29 -->
# PostToolUse Context Monitor Hook
# Trigger: PostToolUse after every tool call
# Behavior: Tracks session tool usage and warns at thresholds
# Thresholds: WARNING (35% remaining) | CRITICAL (25% remaining)
# Debounce: Every 5 calls, unless escalation
# Auto-action: Append to STATE.md on CRITICAL
# Note: Context window % is estimated from call count heuristics

set -euo pipefail

# Silent fail — never break the agent
handle_error() {
    exit 0
}
trap handle_error ERR

# Session tracking file
SESSION_TRACKER="/tmp/backbone-session-$(date +%Y%m%d).tracker"
STATE_FILE="backbone/artifacts/changes/STATE.md"

# Initialize tracker if not exists
if [ ! -f "$SESSION_TRACKER" ]; then
    echo "0" > "$SESSION_TRACKER"
fi

# Read stdin with timeout
INPUT=""
if IFS= read -r -t 5 INPUT; then
    : # success
else
    exit 0
fi

[ -z "$INPUT" ] && exit 0

# Increment call count
call_count=$(cat "$SESSION_TRACKER" 2>/dev/null || echo "0")
call_count=$((call_count + 1))
echo "$call_count" > "$SESSION_TRACKER"

# Heuristic thresholds (adjust based on typical session length)
# Typical Claude Code session: ~40-60 tool calls before context issues
WARNING_THRESHOLD=25   # ~60% used
CRITICAL_THRESHOLD=35  # ~85% used

SEVERITY=""
MESSAGE=""

if [ "$call_count" -ge "$CRITICAL_THRESHOLD" ]; then
    SEVERITY="CRITICAL"
    MESSAGE="Context window critically low (~85%+ used). Stop immediately, save state, and commit."
elif [ "$call_count" -ge "$WARNING_THRESHOLD" ]; then
    # Debounce: only warn every 5 calls at WARNING level
    if [ $((call_count % 5)) -ne 0 ]; then
        exit 0
    fi
    SEVERITY="WARNING"
    MESSAGE="Context window warning (~60%+ used). Consider wrapping up and committing soon."
else
    exit 0
fi

# Output warning
cat <<EOF
{"decision":"warn","severity":"$SEVERITY","call_count":$call_count,"message":"$MESSAGE"}
EOF

# Auto-append to STATE.md on CRITICAL
if [ "$SEVERITY" = "CRITICAL" ] && [ -f "$STATE_FILE" ]; then
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    {
        echo ""
        echo "## Session Context Alert"
        echo "**Time:** $timestamp"
        echo "**Severity:** $SEVERITY"
        echo "**Tool Calls:** $call_count"
        echo "**Message:** $MESSAGE"
        echo "**Action:** Session paused for state preservation"
    } >> "$STATE_FILE"
fi

exit 0
