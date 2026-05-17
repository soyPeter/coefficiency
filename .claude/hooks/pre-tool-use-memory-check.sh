#!/bin/bash
# PreToolUse hook: Enforce MEMORY.md bidirectional documentation
# Runs before Write/Edit when agent writes to memory files
# Warns if index entry not updated alongside detail file
# Non-blocking — advises but doesn't block

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"

# Read stdin JSON from Claude Code
INPUT=$(cat)
[ -z "$INPUT" ] && exit 0

# Parse tool, file path from JSON
TOOL=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_name',''))" 2>/dev/null || true)
TARGET_FILE=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('filePath',''))" 2>/dev/null || true)

# Only check Write and Edit tools
if [[ "$TOOL" != "Write" && "$TOOL" != "Edit" ]]; then
    exit 0
fi

# Check if targeting memory files
if [[ -z "$TARGET_FILE" ]]; then
    exit 0
fi

# Normalize path for comparison
TARGET_PATH="$TARGET_FILE"
if [[ "$TARGET_PATH" != /* ]]; then
    TARGET_PATH="$PROJECT_DIR/$TARGET_PATH"
fi

# Memory file patterns
MEMORY_FILE="$PROJECT_DIR/backbone/6-MEMORY.md"
INDEX_FILE="$PROJECT_DIR/backbone/6-MEMORY.md"

# Check if writing to MEMORY.md directly
if [[ "$TARGET_FILE" == *"6-MEMORY.md" || "$TARGET_FILE" == *"MEMORY.md" ]]; then
    # Agent is writing to MEMORY.md - check if they mention index/d[[ in the content
    CONTENT=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('content',''))" 2>/dev/null || true)
    
    if [ -z "$CONTENT" ]; then
        CONTENT=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('new_string',''))" 2>/dev/null || true)
    fi
    
    # Check if content references the index format (d[[, memory/, etc.)
    if echo "$CONTENT" | grep -qE '^\[\[|memory/|lessons/|patterns/'; then
        exit 0  # Likely updating index entry or detail file - ok
    fi
    
    if echo "$CONTENT" | grep -qE '\[\[[a-z0-9/-]+\]\]'; then
        exit 0  # Has reference format like [[memory/xxx]] - ok
    fi
    
    # Warn about missing index entry
    echo ""
    echo "⚠️  MEMORY UPDATE WITHOUT INDEX ENTRY"
    echo ""
    echo "  You are writing to backbone/6-MEMORY.md but the content"
    echo "  doesn't appear to reference an index entry."
    echo ""
    echo "  AGENTS.md Rule: Bidirectional Documentation requires:"
    echo "    1. If creating NEW memory/lessons/xxx.md → update 6-MEMORY.md index"
    echo "    2. Reference format: [[memory/lessons/YYYYMMDD-title]]"
    echo "    3. Add pointer at top of 6-MEMORY.md"
    echo ""
    echo "  ℹ️  Load skill: view backbone/skills/general/git-commit/SKILL.md"
    echo "  ℹ️  See: backbone/6-MEMORY.md for index format examples"
    echo ""
    exit 0  # Non-blocking warning
fi

# Check if writing to detail files (memory/lessons/, memory/patterns/)
if [[ "$TARGET_FILE" == *memory/lessons/* || "$TARGET_FILE" == *memory/patterns/* ]]; then
    # Extract the filename for index check
    DETAIL_FILE=$(basename "$TARGET_FILE" .md)
    
    # Check if index references this detail file
    if [ -f "$INDEX_FILE" ]; then
        if grep -qE "\[\[$DETAIL_FILE\]\]" "$INDEX_FILE"; then
            exit 0  # Index already has this entry
        fi
    fi
    
    # Warn about missing index update
    echo ""
    echo "⚠️  MEMORY DETAIL FILE WITHOUT INDEX UPDATE"
    echo ""
    echo "  Creating: $TARGET_FILE"
    echo "  but 6-MEMORY.md index doesn't reference it."
    echo ""
    echo "  AGENTS.md Rule: Bidirectional Documentation"
    echo "    - Add entry: [[$DETAIL_FILE]] in backbone/6-MEMORY.md"
    echo "    - Example: - [[memory/lessons/20260428-example]] - Description"
    echo ""
    exit 0  # Non-blocking warning
fi

exit 0