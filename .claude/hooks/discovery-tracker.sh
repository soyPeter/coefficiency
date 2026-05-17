#!/bin/bash
# PostDiscovery hook: Track undocumented discoveries
# Runs after Edit/Write to detect new discoveries needing documentation
# Triggers on patterns like "bug", "learned", "fix:", "trap:"
# Non-blocking warning — prompts but doesn't block

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"

# Read stdin JSON from Claude Code
INPUT=$(cat)
[ -z "$INPUT" ] && exit 0

# Parse tool, content from JSON
TOOL=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_name',''))" 2>/dev/null || true)
CONTENT=""

if [[ "$TOOL" == "Write" ]]; then
    CONTENT=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('content',''))" 2>/dev/null || true)
elif [[ "$TOOL" == "Edit" ]]; then
    CONTENT=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('new_string',''))" 2>/dev/null || true)
fi

# Only check Write/Edit
if [ -z "$CONTENT" ]; then
    exit 0
fi

# Discovery patterns - phrases that indicate a discovery was made
# Use positive lookbehind to avoid matching comments
DISCVERY_PATTERN='(Bug:|bug fix:|fix:|found that|discovered|learned|trap:|trap to|lesson:|pattern:|^## Lessons|^- .*[Ll]esson|- .*[Tt]rap)'

if echo "$CONTENT" | grep -qE "$DISCVERY_PATTERN"; then
    # Check if MEMORY.md index already mentions this discovery
    MEMORY_INDEX="$PROJECT_DIR/backbone/6-MEMORY.md"
    
    if [ -f "$MEMORY_INDEX" ]; then
        # Check for recent entries (last 30 days)
        RECENT_ENTRIES=$(grep -E "2026\.04\.(0[1-9]|1[0-9]|2[0-8])" "$MEMORY_INDEX" | wc -l | tr -d ' ')
        if [ "${RECENT_ENTRIES:-0}" -gt 0 ]; then
            exit 0  # Already has recent entries - likely documented
        fi
    fi
    
    # Prompt to document discovery
    echo ""
    echo "⚠️  DISCOVERY DETECTED - DOCUMENT?"
    echo ""
    echo "  Your edit contains patterns suggesting a discovery was made"
    echo "  (e.g., bug fix, lesson learned, trap to avoid)."
    echo ""
    echo "  AGENTS.md Rule: Knowledge Capture (MANDATORY)"
    echo "    - Add entry to backbone/6-MEMORY.md"
    echo "    - Use format: '## Lessons Learned: [Date]'"
    echo "    - Include: what was discovered, why it matters"
    echo ""
    echo "  ℹ️  See: backbone/6-MEMORY.md for examples"
    echo ""
fi

exit 0