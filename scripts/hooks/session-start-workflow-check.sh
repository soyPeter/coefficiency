#!/bin/bash
# SessionStart hook: Workflow checklist reminder for agents
# Installed via: scripts/setup-hooks.sh
# Fires at the beginning of each Claude Code session
# BLOCKING — agents must acknowledge required files before proceeding

set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
KNOWLEDGE_FILE="$PROJECT_DIR/backbone/4-KNOWLEDGE.md"
WORKFLOW_FILE="$PROJECT_DIR/backbone/8-WORKFLOW.md"
TASKS_FILE="$PROJECT_DIR/backbone/3-TASKS.md"
DECISIONS_FILE="$PROJECT_DIR/backbone/5-DECISIONS.md"
MEMORY_FILE="$PROJECT_DIR/backbone/6-MEMORY.md"
START_FILE="$PROJECT_DIR/backbone/0-START-HERE.md"
SKILL_ACK_FILE="$PROJECT_DIR/.claude/skill-acknowledgments.json"
SESSION_FILE="$PROJECT_DIR/backbone/SESSION.md"

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# ── Detect framework from 4-KNOWLEDGE.md ────────────────────────────────────
FRAMEWORK=""
BUILD_TOOL=""

if [ -f "$KNOWLEDGE_FILE" ]; then
    FRAMEWORK=$(grep -E '^\s*-\s+\*\*Core:' "$KNOWLEDGE_FILE" 2>/dev/null | grep -oE '(Quarkus|Spring Boot|Laravel|Kotlin|Go|Python|PostgreSQL)' | head -1 || true)
    BUILD_TOOL=$(grep -E '^\s*-\s+\*\*Build:' "$KNOWLEDGE_FILE" 2>/dev/null | grep -oE '(Gradle|Maven|Composer|Go|pip)' | head -1 || true)
fi

# Map framework to conventions file (macOS-compatible lowercase)
FRAMEWORK_LOWER=$(echo "$FRAMEWORK" | tr '[:upper:]' '[:lower:]')
case "$FRAMEWORK" in
    *Quarkus*) CONVENTIONS_FILE="$PROJECT_DIR/backbone/reference/quarkus-conventions.md" ;;
    *Spring*) CONVENTIONS_FILE="$PROJECT_DIR/backbone/reference/springboot-conventions.md" ;;
    *Laravel*) CONVENTIONS_FILE="$PROJECT_DIR/backbone/reference/laravel-conventions.md" ;;
    *Kotlin*) CONVENTIONS_FILE="$PROJECT_DIR/backbone/reference/kotlin-conventions.md" ;;
    *Go*) CONVENTIONS_FILE="$PROJECT_DIR/backbone/reference/golang-conventions.md" ;;
    *Python*) CONVENTIONS_FILE="$PROJECT_DIR/backbone/reference/python-conventions.md" ;;
    *) CONVENTIONS_FILE="$PROJECT_DIR/backbone/reference/${FRAMEWORK_LOWER}-conventions.md" ;;
esac

# Build command display
case "$BUILD_TOOL" in
    Gradle) BUILD_CMD="./gradlew build" ;;
    Maven) BUILD_CMD="./mvnw clean install" ;;
    Composer) BUILD_CMD="composer install" ;;
    Go) BUILD_CMD="go build" ;;
    pip) BUILD_CMD="pip install -r requirements.txt" ;;
    *) BUILD_CMD="npm run build" ;;
esac

# ── Auto-discover ALL available skills ──────────────────────────────────────
SKILLS_DIR="$PROJECT_DIR/backbone/skills"
discover_skills() {
    local category="$1"
    local dir="$SKILLS_DIR/$category"
    if [ -d "$dir" ]; then
        find "$dir" -name "SKILL.md" -type f | while read -r skill_file; do
            local skill_name
            skill_name=$(basename "$(dirname "$skill_file")")
            echo "      $skill_name"
        done
    fi
}

# ── Knowledge file completeness check ───────────────────────────────────────
KNOWLEDGE_TODOS=()
if [ -f "$KNOWLEDGE_FILE" ]; then
    while IFS= read -r line; do
        KNOWLEDGE_TODOS+=("$line")
    done < <(grep -n '<!-- TODO' "$KNOWLEDGE_FILE" 2>/dev/null || true)
fi

if [ "${#KNOWLEDGE_TODOS[@]}" -gt 0 ]; then
    echo ""
    echo -e "${RED}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║  ⛔  KNOWLEDGE GAP — backbone/4-KNOWLEDGE.md is incomplete    ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "  ${#KNOWLEDGE_TODOS[@]} unfilled TODO(s) detected:"
    for todo_line in "${KNOWLEDGE_TODOS[@]}"; do
        LINE_NUM=$(echo "$todo_line" | cut -d: -f1)
        LINE_TEXT=$(echo "$todo_line" | cut -d: -f2- | sed 's/^[[:space:]]*//')
        echo "    Line ${LINE_NUM}: ${LINE_TEXT}"
    done
    echo ""
fi

# ── WIP Task Detection ──────────────────────────────────────────────────────
WIP_TASKS=""
WIP_COUNT=0

if [ -f "$TASKS_FILE" ]; then
    WIP_TASKS=$(grep -E '^\s*-\s*\[WIP\]' "$TASKS_FILE" 2>/dev/null || true)
    WIP_COUNT=$(echo "$WIP_TASKS" | grep -c '^' || true)
    # Handle empty string case
    if [ -z "$WIP_TASKS" ]; then
        WIP_COUNT=0
    fi
fi

# ── Print Workflow Checklist ────────────────────────────────────────────────
echo ""
echo -e "${YELLOW}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║  🚀 BACKBONE WORKFLOW CHECKLIST — Read Before Making Changes   ║${NC}"
echo -e "${YELLOW}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${RED}⚠️  ENFORCEMENT: You MUST read required files before writing code!${NC}"
echo ""
echo "  Required checklist:"
echo ""
echo "  □ 1. Read AGENTS.md (this project's agent bootstrap guide)"
echo "       - Single-page summary of everything you need"
echo ""
echo "  □ 2. Read backbone/4-KNOWLEDGE.md"
[ -n "$FRAMEWORK" ] && echo "       - Tech stack: $FRAMEWORK" || echo "       - Understand tech stack and constraints"
[ -n "$BUILD_TOOL" ] && echo "       - Build command: $BUILD_CMD" || echo "       - Check build commands"
echo ""

if [ -f "$CONVENTIONS_FILE" ]; then
    CONV_NAME=$(basename "$CONVENTIONS_FILE" .md)
    echo "  □ 3. Read backbone/reference/$CONV_NAME.md"
    echo "       - Framework-specific patterns and syntax"
    echo ""
fi

if [ -f "$WORKFLOW_FILE" ]; then
    echo "  □ 4. Read backbone/8-WORKFLOW.md"
    echo "       - Definition of Done requirements"
    echo "       - Pre-commit workflow and gates"
    echo ""
fi

# ── WIP Tasks Banner ────────────────────────────────────────────────────────
if [ "$WIP_COUNT" -gt 0 ]; then
    echo -e "  ${RED}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "  ${RED}║  🔄 ACTIVE WIP TASKS ($WIP_COUNT)                                      ║${NC}"
    echo -e "  ${RED}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "$WIP_TASKS" | head -5 | sed 's/^/    /'
    if [ "$WIP_COUNT" -gt 5 ]; then
        echo "    ... and $((WIP_COUNT - 5)) more"
    fi
    echo ""
fi

# ── Available Skills Discovery ──────────────────────────────────────────────
echo "  📚 Available Skills (auto-discovered from backbone/skills/):"
echo ""

for category in general cross-cutting java quarkus springboot kotlin golang python laravel; do
    skills=$(discover_skills "$category" | sort)
    if [ -n "$skills" ]; then
        echo "    $category/"
        echo "$skills" | sed 's/^/      /' | head -10
        skill_count=$(echo "$skills" | grep -c '^' || true)
        if [ "$skill_count" -gt 10 ]; then
            echo "      ... and $((skill_count - 10)) more"
        fi
    fi
done

echo ""
echo "  To load: view backbone/skills/<category>/<skill-name>/SKILL.md"
echo ""

# ── Skill Acknowledgment Check ──────────────────────────────────────────────
SKILLS_ACKNOWLEDGED=false
if [ -f "$SKILL_ACK_FILE" ]; then
    ACK_COUNT=$(grep -c '"acknowledged": true' "$SKILL_ACK_FILE" 2>/dev/null || true)
    if [ "$ACK_COUNT" -gt 0 ]; then
        SKILLS_ACKNOWLEDGED=true
    fi
fi

if [ "$SKILLS_ACKNOWLEDGED" = true ]; then
    echo -e "  ${GREEN}✅ Skills acknowledged this session${NC}"
else
    echo -e "  ${RED}❌ No skills acknowledged yet${NC}"
    echo "     The pre-tool-use hook will block Write/Edit until you acknowledge"
    echo "     Type 'acknowledge' when prompted, or load a skill first"
fi
echo ""

# ── Session File Regeneration ───────────────────────────────────────────────
if [ -f "$TASKS_FILE" ]; then
    cat > "$SESSION_FILE" << EOF
<!-- AUTO-GENERATED: Regenerated on each session start -->
# Session State

## Session Start
- Date: $(date '+%Y-%m-%d %H:%M:%S')
- Framework: ${FRAMEWORK:-unknown}
- Build Tool: ${BUILD_TOOL:-unknown}

## Files Read
<!-- Hook updates this when you read a file -->
- [ ] AGENTS.md
- [ ] backbone/4-KNOWLEDGE.md
- [ ] backbone/8-WORKFLOW.md
- [ ] backbone/3-TASKS.md

## Skills Acknowledged
<!-- Hook updates this when you acknowledge a skill -->

## Current WIP Tasks
$(echo "$WIP_TASKS" | sed 's/^/  /' || echo "  (none)")

## Tasks Completed This Session
<!-- Add completed tasks here, they will be synced to 3-TASKS.md -->

## Cost Tracking
<!-- Call \`/backbone:cost-track\` after significant work to log estimates -->
<!-- Heuristic: ~15k tokens per subagent spawn + ~500 per file read + ~2k per tool call -->

### Session Cost Summary
- Tasks logged: 0
- Total estimated tokens: ~0k input / ~0k output
- Total estimated cost: ~\$0.00

### Cost Log
<!-- Append entries here: ### Cost Log — YYYY-MM-DD HH:MM -->

## Decisions Made
<!-- Will be appended to 5-DECISIONS.md on commit -->

## Memory / Pitfalls
<!-- Will be appended to 6-MEMORY.md on commit -->
EOF
fi

echo "  After work is complete:"
echo "    - Mark task [x] in backbone/3-TASKS.md"
if [ -f "$DECISIONS_FILE" ]; then
    echo "    - Update backbone/5-DECISIONS.md with decisions"
fi
if [ -f "$MEMORY_FILE" ]; then
    echo "    - Update backbone/6-MEMORY.md with insights"
fi
echo "    - Commit: feat(scope): description"
echo ""
echo -e "${YELLOW}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# ── Blocking Check ──────────────────────────────────────────────────────────
# Exit 1 if this is a new session with no skill acknowledgments and WIP tasks exist
if [ "$SKILLS_ACKNOWLEDGED" = false ] && [ "$WIP_COUNT" -gt 0 ]; then
    echo -e "${RED}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║  🚫 BLOCKED: Read required files and acknowledge skills       ║${NC}"
    echo -e "${RED}║                                                               ║${NC}"
    echo -e "${RED}║  1. Read AGENTS.md and backbone/4-KNOWLEDGE.md               ║${NC}"
    echo -e "${RED}║  2. Load a relevant skill: view backbone/skills/...          ║${NC}"
    echo -e "${RED}║  3. Type 'acknowledge' when the hook prompts you             ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    exit 1
fi

exit 0
