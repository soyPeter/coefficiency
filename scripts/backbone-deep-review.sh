#!/bin/bash
# backbone-deep-review.sh — Full-spectrum code analysis orchestrator
# Usage: ./scripts/backbone-deep-review.sh [--output-dir backbone/artifacts/reports]
#
# Spawns 4 parallel subagents to analyze DDD/SOLID/Architecture, API/Security,
# Code Quality, and Test Quality, then compiles a consolidated report.
#
# Designed for: OpenCode (via /backbone-deep-review), Claude Code (same),
#               or standalone via this script.

set -euo pipefail
if [[ -f "$HOME/.backbone/scripts/lib/bb-root.sh" ]]; then
    source "$HOME/.backbone/scripts/lib/bb-root.sh"
else
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
    BB_ROOT="$PROJECT_ROOT"
fi
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR="${1:-$PROJECT_DIR/backbone/artifacts/reports}"
DATE_TAG=$(date +%Y-%m-%d)
PLANNING_DIR="$PROJECT_DIR/.planning/codebase"
REPORT_FILE="$OUTPUT_DIR/deep-review-$DATE_TAG.md"

echo "=== backbone-deep-review ==="
echo "Project: $PROJECT_DIR"
echo "Output:  $REPORT_FILE"
echo ""

# Phase 1: Validate project structure
if [ ! -d "$PROJECT_DIR/src/main/java" ]; then
  echo "ERROR: src/main/java not found — is this a Java project?"
  exit 1
fi

mkdir -p "$PLANNING_DIR" "$OUTPUT_DIR"

# Count scope
JAVA_FILES=$(find "$PROJECT_DIR/src/main/java" -name "*.java" | wc -l)
TS_FILES=$(find "$PROJECT_DIR/frontend/src" -name "*.ts" -o -name "*.tsx" 2>/dev/null | wc -l || echo "0")
TEST_FILES=$(find "$PROJECT_DIR/src/test/java" -name "*.java" 2>/dev/null | wc -l || echo "0")

echo "Scope: $JAVA_FILES Java files, $TS_FILES TS/TSX files, $TEST_FILES test files"
echo ""

# Phase 2: Load required skills
echo "Loading skills..."
for skill in \
  "$PROJECT_DIR/backbone/skills/general/coding-standards/SKILL.md" \
  "$PROJECT_DIR/backbone/skills/cross-cutting/code-quality/SKILL.md" \
  "$PROJECT_DIR/backbone/skills/cross-cutting/testing/test-quality/SKILL.md" \
  "$PROJECT_DIR/backbone/skills/cross-cutting/security/SKILL.md" \
  "$PROJECT_DIR/backbone/skills/cross-cutting/architecture/SKILL.md" \
  "$PROJECT_DIR/backbone/skills/cross-cutting/code-review/SKILL.md"; do
  if [ -f "$skill" ]; then
    echo "  OK $(basename $(dirname $skill))"
  else
    echo "  -- $(basename $(dirname $skill)) — not found (non-fatal)"
  fi
done
echo ""

# Phase 3: Subagent protocol documentation
# AI agents reading this script should execute the following protocol:

echo "Protocol for AI agent:"
echo ""
echo "1. Read backbone/4-KNOWLEDGE.md, backbone/8-WORKFLOW.md"
echo "2. Spawn 4 parallel gsd-codebase-mapper subagents:"
echo "   a) DDD + SOLID + Architecture -> $PLANNING_DIR/ANALYSIS.md"
echo "   b) API Contracts + Security    -> $PLANNING_DIR/API_ANALYSIS.md"
echo "   c) Code Quality + Clean Code   -> $PLANNING_DIR/CONCERNS.md"
echo "   d) Test Quality + Coverage     -> $PLANNING_DIR/TESTING.md"
echo "3. Compile all 4 into $REPORT_FILE"
echo "4. Clean up: rm -rf $PLANNING_DIR"
echo ""
echo "=== Ready ==="
