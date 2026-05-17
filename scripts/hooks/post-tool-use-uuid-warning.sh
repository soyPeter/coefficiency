#!/bin/bash
# post-tool-use-uuid-warning.sh: Warn when UUID is used instead of TSID in Java files
#
# Fires AFTER Write/Edit to Java files.
# Shows a warning (non-blocking) when UUID patterns are detected.
# Suggests TSID (Time-Sorted Unique Identifier) as the preferred alternative.
#
# Why TSID over UUID:
#   - Sortable by time (database-friendly clustering)
#   - Shorter (13 chars vs 36) — better for URLs, logs, indexes
#   - Contains embedded timestamp — no extra created_at needed for ordering
#   - No coordination required (unlike DB sequences)
#   - Lexicographically sortable
#
# Libraries:
#   - tsid-creator: com.github.f4b6a3:tsid-creator
#   - hypersistence-utils: io.hypersistence.utils for Hibernate TSID

set -u

YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"

# Read stdin JSON from Claude Code
INPUT=$(cat)
[ -z "$INPUT" ] && exit 0

# Parse tool and file path
TOOL=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_name',''))" 2>/dev/null || true)
TARGET_FILE=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))" 2>/dev/null || true)

# Only check Write/Edit to Java files
if [[ "$TOOL" != "Write" && "$TOOL" != "Edit" ]]; then
    exit 0
fi

if [[ "$TARGET_FILE" != *.java ]]; then
    exit 0
fi

# Skip if override is set
if [ "${SKIP_UUID_WARNING:-0}" = "1" ]; then
    exit 0
fi

# Get file content
if [ "$TOOL" = "Write" ]; then
    CONTENT=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('content',''))" 2>/dev/null || true)
else
    # For Edit, check new_string
    CONTENT=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('new_string',''))" 2>/dev/null || true)
fi

if [ -z "$CONTENT" ]; then
    exit 0
fi

# Detect UUID patterns
WARNINGS=""

# Pattern 1: java.util.UUID import
if echo "$CONTENT" | grep -qE 'import\s+java\.util\.UUID'; then
    WARNINGS="${WARNINGS}\n  - Uses java.util.UUID import"
fi

# Pattern 2: UUID.randomUUID() usage
if echo "$CONTENT" | grep -qE 'UUID\.randomUUID\(\)'; then
    WARNINGS="${WARNINGS}\n  - Uses UUID.randomUUID()"
fi

# Pattern 3: GenerationType.UUID in JPA
if echo "$CONTENT" | grep -qE 'GenerationType\.UUID'; then
    WARNINGS="${WARNINGS}\n  - Uses JPA GenerationType.UUID"
fi

# Pattern 4: UUID type in fields/parameters
if echo "$CONTENT" | grep -qE '\bUUID\b'; then
    WARNINGS="${WARNINGS}\n  - Uses UUID type"
fi

if [ -n "$WARNINGS" ]; then
    echo ""
    echo -e "${YELLOW}⚠️  UUID DETECTED — Consider TSID instead${NC}"
    echo ""
    echo "  File: $TARGET_FILE"
    echo -e "${YELLOW}  Detected patterns:${NC}"
    echo -e "$WARNINGS"
    echo ""
    echo -e "${BLUE}  Why TSID?${NC}"
    echo "    • Sortable by time (database-friendly clustering)"
    echo "    • Shorter: 13 chars vs 36 (better for URLs, logs, indexes)"
    echo "    • Embedded timestamp — no extra created_at for ordering"
    echo "    • No coordination needed (unlike DB sequences)"
    echo ""
    echo -e "${BLUE}  Migration options:${NC}"
    echo "    1. tsid-creator: com.github.f4b6a3:tsid-creator"
    echo "       TsidCreator.getTsid().toLong() // 64-bit long"
    echo "       TsidCreator.getTsid().toString() // 13-char string"
    echo ""
    echo "    2. Hibernate (JPA): io.hypersistence.utils:hibernate-util"
    echo "       @Id @Tsid private Long id;"
    echo "       @Id @Tsid private String id; // 13-char TSID"
    echo ""
    echo "    3. Quarkus/Spring Boot + tsid-creator:"
    echo "       implementation(\"com.github.f4b6a3:tsid-creator:5.2.6\")"
    echo ""
    echo "  See: backbone/skills/java/java-core/standards/tsid-patterns.md"
    echo "  Override: export SKIP_UUID_WARNING=1"
    echo ""
fi

exit 0
