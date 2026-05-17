#!/bin/bash
# SessionStart hook: Architecture drift detector and session resume checkpoint
# Installed via: scripts/setup-hooks.sh
# Fires at the start of each Claude Code session.
# 1. Resume checkpoint — surfaces open [WIP] tasks from previous session
# 2. Architecture drift scan — finds layer violations across ALL Java files
# Non-blocking — informational only (exit 0 always)

RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ── Part 1: Session Resume Checkpoint ─────────────────────────────────────────
# If [WIP] tasks exist, surface them immediately so Claude picks up where it
# left off rather than starting fresh. (Stop hook shows them at session END;
# this hook shows them at session START for continuity.)

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
TASKS_FILE="$PROJECT_DIR/backbone/3-TASKS.md"
if [ -f "$TASKS_FILE" ]; then
  WIP_LINES=$(grep -n "\[WIP\]" "$TASKS_FILE" 2>/dev/null || true)
  if [ -n "$WIP_LINES" ]; then
    WIP_COUNT=$(echo "$WIP_LINES" | wc -l | tr -d ' ')
    echo ""
    echo "🔄 SESSION RESUME — ${WIP_COUNT} open WIP task(s) carried over:"
    echo "$WIP_LINES" | while IFS= read -r line; do
      LINE_NUM=$(echo "$line" | cut -d: -f1)
      TASK_TEXT=$(echo "$line" | cut -d: -f2- | sed 's/^[[:space:]]*//')
      echo "  Line ${LINE_NUM}: ${TASK_TEXT}"
    done
    echo ""
    echo "  Resume these tasks or mark [ ] if not started before beginning new work."
    echo ""
  fi
fi

# ── Part 2: Architecture Drift Scan ───────────────────────────────────────────
# Scans all Java files (not just staged) for layer boundary violations.
# Catches drift introduced outside Claude sessions (IDE edits, direct changes).
# Uses a fast grep-based scan — approximate but quick enough for session start.

DOMAIN_VIOLS=()
APP_VIOLS=()

# Scan domain layer: look for imports from app/application/infra/infrastructure
while IFS= read -r file; do
  java_rel=$(echo "$file" | sed 's|.*/src/main/java/||')
  namespace_path=$(echo "$java_rel" | sed 's|/domain/.*||')
  if [ -n "$namespace_path" ] && [ "$namespace_path" != "$java_rel" ]; then
    namespace_dot=$(echo "$namespace_path" | tr '/' '.')
    if grep -qE "^import ${namespace_dot}\.(app|application|infra|infrastructure)\." "$file" 2>/dev/null; then
      DOMAIN_VIOLS+=("$file")
    fi
  fi
done < <(find . -name "*.java" -path "*/domain/*" \
           -not -path "./.git/*" -not -path "./build/*" \
           -not -path "./*/generated-sources/*" 2>/dev/null)

# Scan app/application/usecase layer: look for imports from infra/infrastructure
while IFS= read -r file; do
  java_rel=$(echo "$file" | sed 's|.*/src/main/java/||')
  namespace_path=$(echo "$java_rel" | sed 's|/app/.*||' | sed 's|/application/.*||' | sed 's|/usecase/.*||')
  if [ -n "$namespace_path" ] && [ "$namespace_path" != "$java_rel" ]; then
    namespace_dot=$(echo "$namespace_path" | tr '/' '.')
    if grep -qE "^import ${namespace_dot}\.(infra|infrastructure)\." "$file" 2>/dev/null; then
      APP_VIOLS+=("$file")
    fi
  fi
done < <(find . -name "*.java" \
           \( -path "*/app/*" -o -path "*/application/*" -o -path "*/usecase/*" \) \
           -not -path "./.git/*" -not -path "./build/*" \
           -not -path "./*/generated-sources/*" 2>/dev/null)

TOTAL=$(( ${#DOMAIN_VIOLS[@]} + ${#APP_VIOLS[@]} ))

if [ "$TOTAL" -gt 0 ]; then
  echo ""
  echo -e "${RED}🏗️  ARCHITECTURE DRIFT — ${TOTAL} layer violation(s) detected across codebase:${NC}"
  [ "${#DOMAIN_VIOLS[@]}" -gt 0 ] && echo "  Domain→upper-layer imports : ${#DOMAIN_VIOLS[@]} file(s)"
  [ "${#APP_VIOLS[@]}"    -gt 0 ] && echo "  App→infra imports          : ${#APP_VIOLS[@]} file(s)"
  echo ""

  SHOWN=0
  for f in "${DOMAIN_VIOLS[@]}"; do
    [ $SHOWN -ge 3 ] && break
    echo "  ↳ [domain→upper] $f"
    SHOWN=$((SHOWN + 1))
  done
  for f in "${APP_VIOLS[@]}"; do
    [ $SHOWN -ge 3 ] && break
    echo "  ↳ [app→infra]    $f"
    SHOWN=$((SHOWN + 1))
  done
  [ "$TOTAL" -gt 3 ] && echo "  ... and $((TOTAL - 3)) more"

  echo ""
  echo "  These violations exist in the codebase independently of your current task."
  echo "  To investigate: SKIP_BOUNDARIES=1 — or track as a task in backbone/3-TASKS.md"
  echo "  To fix: remove the violating imports and use ports/interfaces instead."
  echo "  See backbone/4-KNOWLEDGE.md → Hexagonal Architecture rules."
  echo ""
fi

exit 0
