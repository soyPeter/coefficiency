#!/bin/bash
# SessionStart hook: Prompt agent to load required skills
# Runs at session start to remind agent of mandatory skills
# Exit 0 always — informational only

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
KNOWLEDGE_FILE="$PROJECT_DIR/backbone/4-KNOWLEDGE.md"

# Detect framework and language
FRAMEWORK=""
LANGUAGE=""

if [ -f "$KNOWLEDGE_FILE" ]; then
    FRAMEWORK=$(grep -E '^\s*-\s+\*\*Core:' "$KNOWLEDGE_FILE" 2>/dev/null | grep -oE '(Quarkus|Spring Boot|Laravel|Kotlin|Go|Python)' | head -1 || true)
    LANGUAGE=$(grep -E '^\s*-\s+\*\*Language:' "$KNOWLEDGE_FILE" 2>/dev/null | grep -oE '[A-Za-z]+' | head -1 || true)
fi

# Build required skills list
SKILLS=""

case "$LANGUAGE" in
    Java|kotlin|Kotlin)
        SKILLS="$SKILLS
  - view backbone/skills/java/java-core/SKILL.md"
        SKILLS="$SKILLS
  - view backbone/skills/java/java-cdi/SKILL.md"
        ;;
esac

case "$FRAMEWORK" in
    Quarkus)
        SKILLS="$SKILLS
  - view backbone/skills/quarkus/java-quarkus/SKILL.md"
        ;;
    Spring*)
        SKILLS="$SKILLS
  - view backbone/skills/springboot/springboot/SKILL.md"
        ;;
    Laravel)
        SKILLS="$SKILLS
  - view backbone/skills/laravel/laravel-patterns/SKILL.md"
        ;;
esac

# Always include build and commit skills
SKILLS="$SKILLS
  - view backbone/skills/java/build-conventions/SKILL.md"
SKILLS="$SKILLS
  - view backbone/skills/general/git-commit/SKILL.md"

# If no project initialized yet, show generic skills
if [ -z "$FRAMEWORK" ] && [ -z "$LANGUAGE" ]; then
    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║  📋 SESSION START - REQUIRED SKILLS                           ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "  Project not yet initialized. Before making changes:"
    echo ""
    echo "  1. Run ./scripts/init-backbone.sh to initialize"
    echo "  2. Read backbone/4-KNOWLEDGE.md"
    echo "  3. Read backbone/0-START-HERE.md"
    echo ""
    echo "  ℹ️  Skills will be displayed after initialization"
    echo ""
    exit 0
fi

# Show skills prompt
echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  📋 SESSION START - REQUIRED SKILLS                           ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "  Framework: ${FRAMEWORK:-unknown}"
echo "  Language: ${LANGUAGE:-unknown}"
echo ""
echo "  Before writing code, load these skills:$SKILLS"
echo ""
echo "  ℹ️  Load path: view backbone/skills/<category>/<skill-name>/SKILL.md"
echo "  ℹ️  See: backbone/9-AGENT-SKILLS.md for full list"
echo "  ℹ️  Read: backbone/8-WORKFLOW.md for Definition of Done"
echo ""
echo "  ⚠️  IMPORTANT: AGENTS.md mandates skill loading before coding."
echo "     Violations will trigger warnings via pre-tool-use hooks."
echo ""

exit 0