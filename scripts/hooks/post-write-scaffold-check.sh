#!/bin/bash
# PostToolUse/Write hook: Validate new module scaffold when a build file is written
# Installed via: scripts/setup-hooks.sh
# Fires after every Write tool call.
# Only activates when a new Gradle build file is written (signals new module creation).
# Non-blocking — informational only (exit 0 always)

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(d.get('tool_input', {}).get('file_path', ''))
" 2>/dev/null || true)

# Only trigger for Gradle build files
if ! echo "$FILE_PATH" | grep -qE 'build\.gradle(\.kts)?$'; then
  exit 0
fi

MODULE_DIR=$(dirname "$FILE_PATH")

# Skip root build file
if [ "$MODULE_DIR" = "." ] || [ -z "$MODULE_DIR" ]; then
  exit 0
fi

# Only check if this looks like a new module (src tree doesn't exist yet or was just created)
if [ ! -d "$MODULE_DIR" ]; then
  exit 0
fi

MISSING=""

# Standard Java source tree
if [ ! -d "$MODULE_DIR/src/main/java" ]; then
  MISSING="$MISSING\n  - src/main/java/          (Java source root)"
fi
if [ ! -d "$MODULE_DIR/src/test/java" ]; then
  MISSING="$MISSING\n  - src/test/java/          (Test source root)"
fi

# Hexagonal architecture layers (check under src/main/java if it exists)
JAVA_ROOT="$MODULE_DIR/src/main/java"
if [ -d "$JAVA_ROOT" ]; then
  HAS_DOMAIN=$(find "$JAVA_ROOT" -type d -name "domain" 2>/dev/null | head -1)
  HAS_APP=$(find "$JAVA_ROOT" -type d \( -name "app" -o -name "application" \) 2>/dev/null | head -1)
  HAS_INFRA=$(find "$JAVA_ROOT" -type d \( -name "infra" -o -name "infrastructure" \) 2>/dev/null | head -1)

  [ -z "$HAS_DOMAIN" ] && MISSING="$MISSING\n  - **/domain/              (hexagonal: pure domain model and ports)"
  [ -z "$HAS_APP" ]    && MISSING="$MISSING\n  - **/app/                 (hexagonal: use-case / application layer)"
  [ -z "$HAS_INFRA" ]  && MISSING="$MISSING\n  - **/infra/               (hexagonal: adapters / infrastructure layer)"
fi

if [ -n "$MISSING" ]; then
  MODULE_NAME=$(basename "$MODULE_DIR")
  echo ""
  echo "⚠️  NEW MODULE SCAFFOLD INCOMPLETE: $MODULE_DIR"
  echo "   The following expected structure is missing:"
  echo -e "$MISSING"
  echo ""
  echo "   Expected hexagonal layout for module '${MODULE_NAME}':"
  echo "     src/main/java/<your.package>/${MODULE_NAME}/domain/model/"
  echo "     src/main/java/<your.package>/${MODULE_NAME}/domain/port/"
  echo "     src/main/java/<your.package>/${MODULE_NAME}/app/"
  echo "     src/main/java/<your.package>/${MODULE_NAME}/infra/"
  echo "     src/test/java/<your.package>/${MODULE_NAME}/"
  echo ""
  echo "   See backbone/4-KNOWLEDGE.md → Module Structure for naming conventions."
  echo ""
fi

exit 0
