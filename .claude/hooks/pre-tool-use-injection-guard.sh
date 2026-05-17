#!/bin/bash
# =============================================================================
# .claude/hooks/pre-tool-use-injection-guard.sh
# BLOCKING injection scanner for Write/Edit operations on agent context files
# =============================================================================
# Trigger: PreToolUse
# Targets: .claude/*, AGENTS.md, CLAUDE.md, backbone/*.md
# Action: BLOCKS operation if injection patterns detected
# Bypass: Add "<!-- verified-safe -->" comment to file
# Silent fail: If hook crashes, exits 0 (never breaks agent)
# =============================================================================

# ── Silent Fail Guard ──────────────────────────────────────────────────────
# Wrap everything in a function so we can catch unexpected errors
# but still return exit 1 for intentional blocks
main() {

# ── Timeout Guard ──────────────────────────────────────────────────────────
(
  sleep 10
  exit 0
) &
TIMEOUT_PID=$!

trap 'kill $TIMEOUT_PID 2>/dev/null || true' EXIT

# ── Read stdin ─────────────────────────────────────────────────────────────
INPUT=""
while IFS= read -r line || [[ -n "$line" ]]; do
  INPUT="${INPUT}${line}\n"
done

kill $TIMEOUT_PID 2>/dev/null || true

# ── Parse JSON with Python (always available) ──────────────────────────────
PARSED=$(echo -e "$INPUT" | python3 -c '
import json, sys
try:
    data = json.load(sys.stdin)
    tool = data.get("tool_name", "")
    input_data = data.get("tool_input", {})
    file_path = input_data.get("file_path", "")
    content = input_data.get("content", "") or input_data.get("new_string", "")
    print(f"{tool}|{file_path}|{content}")
except:
    print("||")
' 2>/dev/null || echo "||")

TOOL=$(echo "$PARSED" | cut -d'|' -f1)
FILE_PATH=$(echo "$PARSED" | cut -d'|' -f2)
CONTENT=$(echo "$PARSED" | cut -d'|' -f3-)

# ── Only check Write/Edit ──────────────────────────────────────────────────
if [[ "$TOOL" != "Write" && "$TOOL" != "Edit" ]]; then
  exit 0
fi

# ── Check if target is agent context file ──────────────────────────────────
IS_CONTEXT_FILE=false

# Normalize path for matching
NORM_PATH=$(echo "$FILE_PATH" | sed 's|^\./||')

case "$NORM_PATH" in
  .claude/*|\\.claude/*)
    IS_CONTEXT_FILE=true
    ;;
  AGENTS.md|CLAUDE.md)
    IS_CONTEXT_FILE=true
    ;;
  backbone/*.md)
    IS_CONTEXT_FILE=true
    ;;
esac

if [[ "$IS_CONTEXT_FILE" != "true" ]]; then
  exit 0
fi

# ── Check for bypass marker ────────────────────────────────────────────────
if echo "$CONTENT" | grep -q '<!-- verified-safe -->'; then
  exit 0
fi

# ── Injection Pattern Detection (22 patterns) ──────────────────────────────
# Returns: pattern description if found, empty if clean
detect_injection() {
  local content="$1"
  local found=""

  # Pattern 1-5: Instruction override
  if echo "$content" | grep -qiE 'ignore\s+(all\s+)?(previous|prior|above|earlier|preceding)\s+(instructions|prompts|rules|directives|context)'; then
    found="'ignore previous instructions' pattern detected"
  elif echo "$content" | grep -qiE 'disregard\s+(all\s+)?(previous|prior|above)\s+(instructions|prompts|rules)'; then
    found="'disregard previous instructions' pattern detected"
  elif echo "$content" | grep -qiE 'forget\s+(all\s+)?(previous|prior|above)\s+(instructions|prompts|rules|context)'; then
    found="'forget previous instructions' pattern detected"
  elif echo "$content" | grep -qiE 'override\s+(all\s+)?(system|previous|safety)\s+(instructions|prompts|rules|checks|filters|guards)'; then
    found="'override system instructions' pattern detected"
  elif echo "$content" | grep -qiE 'override\s+(system|safety|security)\s+'; then
    found="'override system' pattern detected"
  # Pattern 6-11: Role manipulation
  elif echo "$content" | grep -qiE 'you\s+are\s+now\s+(a|an|my)\s+'; then
    found="'you are now' role manipulation detected"
  elif echo "$content" | grep -qiE 'from\s+now\s+on\s+(you|pretend|act|behave)'; then
    found="'from now on' role manipulation detected"
  elif echo "$content" | grep -qiE 'pretend\s+(you\s+are|to\s+be)\s+'; then
    found="'pretend you are' pattern detected"
  elif echo "$content" | grep -qiE 'act\s+as\s+(a|an|if|my)\s+'; then
    found="'act as' pattern detected"
  elif echo "$content" | grep -qiE 'roleplay\s+as\s+'; then
    found="'roleplay as' pattern detected"
  elif echo "$content" | grep -qiE 'assume\s+the\s+role\s+of\s+'; then
    found="'assume the role' pattern detected"
  # Pattern 12-17: System prompt extraction
  elif echo "$content" | grep -qiE 'output\s+(your|the)\s+(system\s+)?(prompt|instructions)'; then
    found="system prompt extraction attempt detected"
  elif echo "$content" | grep -qiE 'reveal\s+(your|the)\s+(system\s+)?(prompt|instructions)'; then
    found="system prompt reveal attempt detected"
  elif echo "$content" | grep -qiE 'show\s+me\s+(your|the)\s+(system\s+)?(prompt|instructions)'; then
    found="system prompt show attempt detected"
  elif echo "$content" | grep -qiE 'print\s+(your|the)\s+(system\s+)?(prompt|instructions)'; then
    found="system prompt print attempt detected"
  elif echo "$content" | grep -qiE 'what\s+(is|are)\s+(your|the)\s+(system\s+)?(prompt|instructions)'; then
    found="system prompt inquiry detected"
  elif echo "$content" | grep -qiE 'repeat\s+(your|the|all)\s+(system\s+)?(prompt|instructions|rules)'; then
    found="system prompt repeat attempt detected"
  # Pattern 18-22: Fake boundaries / jailbreak
  elif echo "$content" | grep -qiE '<\s*system\s*>'; then
    found="'<system>' tag detected"
  elif echo "$content" | grep -qiE '\[\s*SYSTEM\s*\]'; then
    found="'[SYSTEM]' marker detected"
  elif echo "$content" | grep -qiE '\[\s*INST\s*\]'; then
    found="'[INST]' marker detected"
  elif echo "$content" | grep -qiE '<<\s*SYS\s*>>'; then
    found="'<<SYS>>' marker detected"
  elif echo "$content" | grep -qiE 'do\s+anything\s+now'; then
    found="'do anything now' jailbreak pattern detected"
  elif echo "$content" | grep -qiE 'DAN\s+mode'; then
    found="'DAN mode' jailbreak pattern detected"
  elif echo "$content" | grep -qiE 'developer\s+mode\s+(enabled|output|activated)'; then
    found="'developer mode' jailbreak pattern detected"
  elif echo "$content" | grep -qiE 'jailbreak'; then
    found="'jailbreak' pattern detected"
  elif echo "$content" | grep -qiE 'bypass\s+(safety|content|security)\s+(filter|check|rule|guard)'; then
    found="'bypass safety' pattern detected"
  fi

  # If text patterns found, return early
  if [[ -n "$found" ]]; then
    echo "$found"
    return
  fi

  # Invisible Unicode detection (requires Python)
  local unicode_found
  unicode_found=$(echo "$content" | python3 -c '
import sys
content = sys.stdin.read()
invisible = [
  "\u200B", "\u200C", "\u200D", "\u200E", "\u200F",
  "\u2028", "\u2029", "\u202A", "\u202B", "\u202C", "\u202D", "\u202E", "\u202F",
  "\uFEFF", "\u00AD",
]
found = []
for char in invisible:
  if char in content:
    found.append(f"U+{ord(char):04X}")
for cp in range(0xE0000, 0xE007F + 1):
  char = chr(cp)
  if char in content:
    found.append(f"U+{cp:05X}")
if found:
  print(f"Invisible Unicode: {', '.join(found)}")
' 2>/dev/null || true)

  if [[ -n "$unicode_found" ]]; then
    echo "$unicode_found"
    return
  fi

  echo ""
}

RESULT=$(detect_injection "$CONTENT")

if [[ -n "$RESULT" ]]; then
  cat <<EOF
{
  "decision": "block",
  "reason": "🛡️ Injection Guard: $RESULT. If this is a false positive, add <!-- verified-safe --> to bypass.",
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "additionalContext": "Blocked write to agent context file: $FILE_PATH"
  }
}
EOF
  exit 1
fi

exit 0

} # end main()

# ── Execute with error handling ────────────────────────────────────────────
main "$@" || exit 0
