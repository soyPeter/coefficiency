#!/usr/bin/env bash
#<!-- VERSION: 2026.05.29 -->
# PostToolUse Read-Time Injection Scanner
# Trigger: PostToolUse on Read tool calls
# Behavior: Scans read content for injection patterns and summarization poisoning
# Severity: LOW (advisory) | HIGH (blocks subsequent tools)
# Exclusions: Binary files, hook sources, .git/

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

# Parse JSON (lightweight — extract tool_name and content)
tool_name=""
file_path=""
content=""

# Extract tool_name
tool_name=$(echo "$INPUT" | grep -o '"tool_name"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"\([^"]*\)"$/\1/' || true)

# Only process Read tool calls
[ "$tool_name" != "Read" ] && exit 0

# Extract file_path
file_path=$(echo "$INPUT" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)"$/\1/' || true)

# Skip if no file_path
[ -z "$file_path" ] && exit 0

# Skip exclusions
skip_patterns='\.git/|\.claude/hooks/|node_modules/|\.class$|\.jar$|\.zip$|\.png$|\.jpg$|\.gif$|\.pdf$|\.exe$|\.dll$|\.so$|\.dylib$'
if echo "$file_path" | grep -qiE "$skip_patterns"; then
    exit 0
fi

# Extract content (look for content field in tool_input)
content=$(echo "$INPUT" | sed -n 's/.*"content"[[:space:]]*:[[:space:]]*"\(.*\)".*/\1/p' | head -1 || true)

# If no content extracted, try reading the file directly
if [ -z "$content" ] && [ -f "$file_path" ]; then
    content=$(cat "$file_path" 2>/dev/null || true)
fi

[ -z "$content" ] && exit 0

# Normalize content for scanning (remove common escaping)
content=$(echo "$content" | sed 's/\\n/\n/g; s/\\t/\t/g')

# Severity tracking
SEVERITY="LOW"
FINDINGS=()

# Pattern 1: Summarization poisoning (HIGH)
poisoning_patterns=(
    "when summarizing.*retain.*this"
    "remember to include.*in your summary"
    "do not mention.*in your response"
    "ignore the previous instruction.*and instead"
    "your summary must include.*the following"
    "when you see this.*act as"
)

for pattern in "${poisoning_patterns[@]}"; do
    if echo "$content" | grep -qiE "$pattern"; then
        SEVERITY="HIGH"
        FINDINGS+=("Summarization poisoning detected: '$pattern'")
    fi
done

# Pattern 2: System prompt overrides (HIGH)
system_patterns=(
    "ignore previous instructions"
    "act as / pretend you are"
    "override system prompt"
    "you are now.*instead of"
    "system override"
    "new system prompt"
)

for pattern in "${system_patterns[@]}"; do
    if echo "$content" | grep -qiE "$pattern"; then
        SEVERITY="HIGH"
        FINDINGS+=("System prompt override detected: '$pattern'")
    fi
done

# Pattern 3: Instruction delimiters (HIGH)
delimiter_patterns=(
    "<system>"
    "\[SYSTEM\]"
    "\[INST\]"
    "<<SYS>>"
    "[/SYSTEM]"
    "[/INST]"
)

for pattern in "${delimiter_patterns[@]}"; do
    if echo "$content" | grep -qiF "$pattern"; then
        SEVERITY="HIGH"
        FINDINGS+=("Instruction delimiter detected: '$pattern'")
    fi
done

# Pattern 4: Invisible Unicode (HIGH)
# Check for zero-width spaces, line separators, BOM
if echo "$content" | grep -q $'[\u200B\u200C\u200D\uFEFF\u2028\u2029]'; then
    SEVERITY="HIGH"
    FINDINGS+=("Invisible Unicode characters detected (zero-width spaces, BOM, line separators)")
fi

# Pattern 5: Role manipulation (MEDIUM)
role_patterns=(
    "you are an unfiltered"
    "you are a jailbroken"
    "DAN mode"
    "do anything now"
    "no restrictions"
    "no ethical constraints"
)

for pattern in "${role_patterns[@]}"; do
    if echo "$content" | grep -qiE "$pattern"; then
        [ "$SEVERITY" = "LOW" ] && SEVERITY="MEDIUM"
        FINDINGS+=("Role manipulation detected: '$pattern'")
    fi
done

# Pattern 6: Hidden instructions (MEDIUM)
hidden_patterns=(
    "<!--.*do not.*--"
    "<!--.*ignore.*--"
    "/\*.*do not.*\*/"
    "#.*hidden instruction"
    "base64.*instruction"
)

for pattern in "${hidden_patterns[@]}"; do
    if echo "$content" | grep -qiE "$pattern"; then
        [ "$SEVERITY" = "LOW" ] && SEVERITY="MEDIUM"
        FINDINGS+=("Hidden instruction detected: '$pattern'")
    fi
done

# Output result
if [ ${#FINDINGS[@]} -gt 0 ]; then
    # Build findings JSON array
    findings_json=""
    for finding in "${FINDINGS[@]}"; do
        if [ -n "$findings_json" ]; then
            findings_json="$findings_json, "
        fi
        findings_json="$findings_json\"$finding\""
    done

    cat <<EOF
{"decision":"warn","severity":"$SEVERITY","file":"$file_path","findings":[$findings_json],"message":"Injection patterns detected in read content. Review before proceeding."}
EOF
else
    echo '{"decision":"allow"}'
fi

exit 0
