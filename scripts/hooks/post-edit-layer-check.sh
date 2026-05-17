#!/bin/bash
# PostToolUse/Edit+Write hook: Real-time layer boundary check for Claude Code
# Fires immediately after Claude edits or writes a Java file
# Gives Claude a chance to fix violations in the same turn, before committing
# Non-blocking (exit 0 always) — informational feedback only

INPUT=$(cat)

# Fast-path: only proceed for Java files
FILE_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
inp = d.get('tool_input', {})
# Edit tool uses 'file_path'; Write tool uses 'file_path'
print(inp.get('file_path', ''))
" 2>/dev/null || true)

if ! echo "$FILE_PATH" | grep -qE '\.java$'; then
  exit 0
fi

# Only check files in domain/ or app/application/usecase layers
if ! echo "$FILE_PATH" | grep -qE '/(domain|app|application|usecase)/'; then
  exit 0
fi

# Only check files that actually exist (Write might create new files)
if [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

YELLOW='\033[1;33m'
NC='\033[0m'

VIOLATIONS=0

# Determine which layer check to apply
if echo "$FILE_PATH" | grep -q '/domain/'; then
  # Extract namespace prefix before /domain/
  java_rel=$(echo "$FILE_PATH" | sed 's|.*/src/main/java/||')
  namespace_path=$(echo "$java_rel" | sed 's|/domain/.*||')

  if [ -n "$namespace_path" ] && [ "$namespace_path" != "$java_rel" ]; then
    namespace_dot=$(echo "$namespace_path" | tr '/' '.')
    MATCHES=$(grep -nE "^import ${namespace_dot}\.(app|application|infra|infrastructure)\." "$FILE_PATH" 2>/dev/null || true)

    if [ -n "$MATCHES" ]; then
      echo ""
      echo "⚠️  LAYER BOUNDARY VIOLATION detected in: $FILE_PATH"
      echo "   Domain layer is importing from an upper layer:"
      echo "$MATCHES" | while read -r line; do echo "   ↳ $line"; done
      echo ""
      echo "   Fix: Remove these imports. Domain must not depend on app or infra."
      echo "   See backbone/4-KNOWLEDGE.md → Hexagonal Architecture rules."
      VIOLATIONS=$((VIOLATIONS + 1))
    fi
  fi
fi

if echo "$FILE_PATH" | grep -qE '/(app|application|usecase)/'; then
  # Extract namespace prefix before app/application/usecase
  java_rel=$(echo "$FILE_PATH" | sed 's|.*/src/main/java/||')
  namespace_path=$(echo "$java_rel" | sed 's|/app/.*||' | sed 's|/application/.*||' | sed 's|/usecase/.*||')

  if [ -n "$namespace_path" ]; then
    namespace_dot=$(echo "$namespace_path" | tr '/' '.')
    MATCHES=$(grep -nE "^import ${namespace_dot}\.(infra|infrastructure)\." "$FILE_PATH" 2>/dev/null || true)

    if [ -n "$MATCHES" ]; then
      echo ""
      echo "⚠️  LAYER BOUNDARY VIOLATION detected in: $FILE_PATH"
      echo "   Application layer is importing from the infrastructure layer:"
      echo "$MATCHES" | while read -r line; do echo "   ↳ $line"; done
      echo ""
      echo "   Fix: Remove these imports. App layer must not depend on infra directly."
      echo "   Use a port (interface) in domain/app, implemented in infra."
      echo "   See backbone/4-KNOWLEDGE.md → Hexagonal Architecture rules."
      VIOLATIONS=$((VIOLATIONS + 1))
    fi
  fi
fi

exit 0
