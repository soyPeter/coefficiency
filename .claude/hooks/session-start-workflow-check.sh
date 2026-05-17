#!/bin/bash
# SessionStart hook: Workflow checklist reminder for agents
# Installed via: scripts/setup-hooks.sh
# Fires at the beginning of each Claude Code session
# Non-blocking — informational only

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
KNOWLEDGE_FILE="$PROJECT_DIR/backbone/4-KNOWLEDGE.md"
WORKFLOW_FILE="$PROJECT_DIR/backbone/8-WORKFLOW.md"
TASKS_FILE="$PROJECT_DIR/backbone/3-TASKS.md"
DECISIONS_FILE="$PROJECT_DIR/backbone/5-DECISIONS.md"
MEMORY_FILE="$PROJECT_DIR/backbone/6-MEMORY.md"
START_FILE="$PROJECT_DIR/backbone/0-START-HERE.md"
SKILL_ACK_FILE="$PROJECT_DIR/.claude/skill-acknowledgments.json"

# Detect framework from 4-KNOWLEDGE.md if available
FRAMEWORK=""
BUILD_TOOL=""
JAVA_VERSION=""

if [ -f "$KNOWLEDGE_FILE" ]; then
    FRAMEWORK=$(grep -E '^\s*-\s+\*\*Core:' "$KNOWLEDGE_FILE" 2>/dev/null | grep -oE '(Quarkus|Spring Boot|Laravel|Kotlin|Go|Python|PostgreSQL)' | head -1 || true)
    BUILD_TOOL=$(grep -E '^\s*-\s+\*\*Build:' "$KNOWLEDGE_FILE" 2>/dev/null | grep -oE '(Gradle|Maven|Composer|Go|pip)' | head -1 || true)
    JAVA_VERSION=$(grep -E '^\s*-\s+\*\*Core:' "$KNOWLEDGE_FILE" 2>/dev/null | grep -oE 'Java [0-9]+' | head -1 || true)
fi

# Map framework to conventions file
case "$FRAMEWORK" in
    *Quarkus*) CONVENTIONS_FILE="$PROJECT_DIR/backbone/reference/quarkus-conventions.md" ;;
    *Spring*) CONVENTIONS_FILE="$PROJECT_DIR/backbone/reference/springboot-conventions.md" ;;
    *Laravel*) CONVENTIONS_FILE="$PROJECT_DIR/backbone/reference/laravel-conventions.md" ;;
    *Kotlin*) CONVENTIONS_FILE="$PROJECT_DIR/backbone/reference/kotlin-conventions.md" ;;
    *Go*) CONVENTIONS_FILE="$PROJECT_DIR/backbone/reference/golang-conventions.md" ;;
    *Python*) CONVENTIONS_FILE="$PROJECT_DIR/backbone/reference/python-conventions.md" ;;
    *) CONVENTIONS_FILE="$PROJECT_DIR/backbone/reference/${FRAMEWORK,,}-conventions.md" ;;
esac

# Build build command display
case "$BUILD_TOOL" in
    Gradle) BUILD_CMD="./gradlew build" ;;
    Maven) BUILD_CMD="./mvnw clean install" ;;
    Composer) BUILD_CMD="composer install" ;;
    Go) BUILD_CMD="go build" ;;
    pip) BUILD_CMD="pip install -r requirements.txt" ;;
    *) BUILD_CMD="./gradlew build" ;;
esac

# Detect framework-specific skills directory
SKILLS_DIR="$PROJECT_DIR/backbone/skills"
FRAMEWORK_SKILLS=""
case "$FRAMEWORK" in
    *Quarkus*) FRAMEWORK_SKILLS="quarkus" ;;
    *Spring*) FRAMEWORK_SKILLS="spring" ;;
    *Laravel*|*PHP*) FRAMEWORK_SKILLS="php" ;;
    *Kotlin*) FRAMEWORK_SKILLS="kotlin" ;;
    *Go*) FRAMEWORK_SKILLS="golang" ;;
    *Python*) FRAMEWORK_SKILLS="python" ;;
esac

# ── Knowledge file completeness check ─────────────────────────────────────────
KNOWLEDGE_TODOS=()
if [ -f "$KNOWLEDGE_FILE" ]; then
    while IFS= read -r line; do
        KNOWLEDGE_TODOS+=("$line")
    done < <(grep -n '<!-- TODO' "$KNOWLEDGE_FILE" 2>/dev/null || true)
fi

if [ "${#KNOWLEDGE_TODOS[@]}" -gt 0 ]; then
    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║  ⛔  KNOWLEDGE GAP — backbone/4-KNOWLEDGE.md is incomplete    ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "  ${#KNOWLEDGE_TODOS[@]} unfilled TODO(s) detected in backbone/4-KNOWLEDGE.md:"
    echo ""
    for todo_line in "${KNOWLEDGE_TODOS[@]}"; do
        LINE_NUM=$(echo "$todo_line" | cut -d: -f1)
        LINE_TEXT=$(echo "$todo_line" | cut -d: -f2- | sed 's/^[[:space:]]*//')
        echo "  Line ${LINE_NUM}: ${LINE_TEXT}"
    done
    echo ""
    echo "  ⚠️  ACTION REQUIRED before proceeding:"
    echo "     1. Open backbone/4-KNOWLEDGE.md"
    echo "     2. Replace each <!-- TODO: ... --> with the actual value"
    echo "     3. The tech stack must be fully defined before agents can operate correctly"
    echo ""
fi

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  🚀 BACKBONE WORKFLOW CHECKLIST — Read Before Making Changes   ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "  ⚠️  ENFORCEMENT: You MUST load skills before writing code!"
echo ""
echo "  Required checklist:"
echo ""
echo "  □ 1. Read backbone/4-KNOWLEDGE.md"
[ -n "$FRAMEWORK" ] && echo "       - Understand tech stack ($FRAMEWORK${JAVA_VERSION:+, $JAVA_VERSION})" || echo "       - Understand tech stack and constraints"
echo "       - Review NEVER DO constraints"
[ -n "$BUILD_TOOL" ] && echo "       - Check $BUILD_TOOL build commands" || echo "       - Check build commands"
echo ""

# Only show conventions if file exists
if [ -f "$CONVENTIONS_FILE" ]; then
    CONV_NAME=$(basename "$CONVENTIONS_FILE" .md)
    echo "  □ 2. Read backbone/reference/$CONV_NAME.md"
    echo "       - Learn framework-specific patterns"
    echo "       - Verify endpoint patterns"
    echo "       - Check security and testing conventions"
    echo ""
else
    echo "  □ 2. Read backbone/reference/*-conventions.md"
    echo "       - Learn framework-specific patterns"
    echo ""
fi

if [ -f "$WORKFLOW_FILE" ]; then
    echo "  □ 3. Read backbone/8-WORKFLOW.md"
    echo "       - Understand Definition of Done requirements"
    echo "       - Review test coverage rules (80%+ on core logic)"
    echo "       - Check pre-commit workflow"
    echo ""
fi

# ── WIP Task Skills Check ──────────────────────────────────────────────────
WIP_TASK_FOUND=false
WIP_TASK_NAME=""
WIP_REQUIRED_SKILLS=()

if [ -f "$TASKS_FILE" ]; then
    # Find WIP tasks and extract required skills
    while IFS= read -r line; do
        # Check for WIP task marker
        if echo "$line" | grep -qE '^\s*###\s+\[WIP\]'; then
            WIP_TASK_FOUND=true
            WIP_TASK_NAME=$(echo "$line" | sed 's/^[[:space:]]*###[[:space:]]*\[WIP\][[:space:]]*//')
        # Check for required skills in WIP task
        elif [ "$WIP_TASK_FOUND" = true ] && echo "$line" | grep -qE 'Required Skills|Required skills'; then
            # Extract skill paths from backtick blocks
            while IFS= read -r skill_line; do
                skill=$(echo "$skill_line" | grep -oE '`[^`]+`' | tr -d '`' | tr -d ' ')
                if [ -n "$skill" ]; then
                    WIP_REQUIRED_SKILLS+=("$skill")
                fi
            done < <(echo "$line" | grep -oE '`[^`]+`' | tr -d '`' | grep "view backbone/skills" || true)
        fi
    done < "$TASKS_FILE"
fi

# Count acknowledged skills
ACKNOWLEDGED_COUNT=0
TOTAL_REQUIRED=${#WIP_REQUIRED_SKILLS[@]}

if [ -f "$SKILL_ACK_FILE" ] && [ "$TOTAL_REQUIRED" -gt 0 ]; then
    for skill in "${WIP_REQUIRED_SKILLS[@]}"; do
        if grep -q "$(basename "$skill")" "$SKILL_ACK_FILE" 2>/dev/null; then
            ACKNOWLEDGED_COUNT=$((ACKNOWLEDGED_COUNT + 1))
        fi
    done
fi

if [ "$WIP_TASK_FOUND" = true ]; then
    echo "  □ 4. Check backbone/3-TASKS.md"
    echo "       - Current WIP task: $WIP_TASK_NAME"
    echo ""
    
    if [ "$TOTAL_REQUIRED" -gt 0 ]; then
        echo "  ╔════════════════════════════════════════════════════════════════╗"
        echo "  ║  📋 TASK-LINKED SKILLS                                      ║"
        echo "  ╚════════════════════════════════════════════════════════════════╝"
        echo ""
        echo "  ⚠️  WIP Task requires these skills:"
        echo ""
        
        idx=1
        for skill in "${WIP_REQUIRED_SKILLS[@]}"; do
            skill_name=$(basename "$skill" .md)
            acknowledged=false
            if [ -f "$SKILL_ACK_FILE" ] && grep -q "$(basename "$skill")" "$SKILL_ACK_FILE" 2>/dev/null; then
                acknowledged=true
            fi
            
            if [ "$acknowledged" = true ]; then
                echo "    [$idx] ✓ $skill_name (acknowledged)"
            else
                echo "    [$idx] ○ $skill_name (NOT acknowledged)"
            fi
            idx=$((idx + 1))
        done
        
        echo ""
        echo "  Progress: $ACKNOWLEDGED_COUNT/$TOTAL_REQUIRED skills acknowledged"
        
        if [ "$ACKNOWLEDGED_COUNT" -lt "$TOTAL_REQUIRED" ]; then
            echo ""
            echo "  ⚠️  Load required skills before starting work:"
            for skill in "${WIP_REQUIRED_SKILLS[@]}"; do
                echo "     view $skill"
            done
        else
            echo ""
            echo "  ✅ All required skills acknowledged for this task"
        fi
        echo ""
    fi
else
    if [ -f "$TASKS_FILE" ]; then
        echo "  □ 4. Check backbone/3-TASKS.md"
        echo "       - Identify current WIP tasks"
        echo "       - Read the task description"
        echo "       - Set [WIP] marker before starting"
        echo ""
    fi
fi

if [ -f "$START_FILE" ]; then
    echo "  ℹ️  Full documentation roadmap: backbone/0-START-HERE.md"
fi
echo ""

# ── Auto-Worktree Check ────────────────────────────────────────────────────
# If feature WIP task on main/dev branch and not in worktree → auto-create

AUTO_WORKTRUNK_DONE=false

if [ "$WIP_TASK_FOUND" = true ] && command -v git &> /dev/null; then
    if git rev-parse --git-dir >/dev/null 2>&1; then
        CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)
        GIT_DIR=$(git rev-parse --git-dir 2>/dev/null || true)
        
        # Check if on protected branch and NOT in a worktree
        if [[ "$CURRENT_BRANCH" =~ ^(main|master|dev|develop)$ ]] && [[ "$GIT_DIR" != *"worktrees"* ]]; then
            # Check if WIP task is feature work (not fix/docs/refactor)
            FIX_KEYWORDS="fix|bug|docs|update|refactor|clean|remove|chore|test|style|perf|ci|build|revert"
            TASK_LOWER=$(echo "$WIP_TASK_NAME" | tr '[:upper:]' '[:lower:]')
            
            if ! echo "$TASK_LOWER" | grep -qiE "^\s*-?\s*($FIX_KEYWORDS)"; then
                echo ""
                echo "╔════════════════════════════════════════════════════════════════╗"
                echo "║  🌳  AUTO-WORKTREE: Feature work detected                     ║"
                echo "╚════════════════════════════════════════════════════════════════╝"
                echo ""
                echo "  Current branch: $CURRENT_BRANCH"
                echo "  WIP task: $WIP_TASK_NAME"
                echo ""
                echo "  Agentic Backbone requires feature work in isolated worktrees."
                echo ""
                
                # Generate branch name from task
                BRANCH_NAME=$(echo "$WIP_TASK_NAME" | sed 's/[^a-zA-Z0-9 ]//g' | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/-*$//g' | sed 's/^-*//g')
                BRANCH_NAME="feat/$BRANCH_NAME"
                
                REPO_NAME=$(basename "$PROJECT_DIR")
                WORKTREE_PATH="$PROJECT_DIR/../$REPO_NAME-$(echo "$BRANCH_NAME" | tr '/' '-')"
                
                if [ -f "$PROJECT_DIR/scripts/worktrunk.sh" ]; then
                    echo "  Creating worktree via scripts/worktrunk.sh: $BRANCH_NAME"
                    echo ""
                    
                    TASK_DESC=$(echo "$BRANCH_NAME" | sed 's/^feat\///')
                    if "$PROJECT_DIR/scripts/worktrunk.sh" create "$TASK_DESC" 2>/dev/null; then
                        if [ -d "$WORKTREE_PATH" ]; then
                            echo "  ✅ Worktree created: $WORKTREE_PATH"
                            echo ""
                            echo "  🔄 IMPORTANT: Your working directory has changed."
                            echo "     New project root: $WORKTREE_PATH"
                            echo ""
                            echo "  Please cd to the new worktree to continue:"
                            echo "     cd $WORKTREE_PATH"
                            echo ""
                            echo "  Or restart your session in the new directory."
                            echo ""
                            AUTO_WORKTRUNK_DONE=true
                        fi
                    else
                        echo "  ⚠️  Failed to create worktree. Try manually:"
                        echo "     $PROJECT_DIR/scripts/worktrunk.sh create $TASK_DESC"
                        echo ""
                    fi
                else
                    echo "  ⚠️  scripts/worktrunk.sh not found. Creating with raw git..."
                    echo ""
                    
                    BASE_BRANCH="dev"
                    git show-ref --verify --quiet "refs/heads/dev" || BASE_BRANCH="main"
                    git show-ref --verify --quiet "refs/heads/main" || BASE_BRANCH="master"
                    
                    git branch "$BRANCH_NAME" "$BASE_BRANCH" 2>/dev/null || true
                    if git worktree add "$WORKTREE_PATH" "$BRANCH_NAME" 2>/dev/null; then
                        echo "  ✅ Worktree created: $WORKTREE_PATH"
                        echo ""
                        echo "  🔄 IMPORTANT: cd to the new worktree to continue:"
                        echo "     cd $WORKTREE_PATH"
                        echo ""
                        AUTO_WORKTRUNK_DONE=true
                    else
                        echo "  ⚠️  Failed. Create manually:"
                        echo "     git worktree add -b $BRANCH_NAME ../$REPO_NAME-$(echo "$BRANCH_NAME" | tr '/' '-') $BASE_BRANCH"
                        echo ""
                    fi
                fi
                
                echo "╚════════════════════════════════════════════════════════════════╝"
                echo ""
            fi
        fi
    fi
fi

# Display required skills section
echo "  ⚠️  REQUIRED SKILLS - Load these BEFORE coding:"
echo ""
# Parse skills and display load commands
for skill_cat in java $FRAMEWORK_SKILLS; do
    if [ -d "$SKILLS_DIR/$skill_cat" ]; then
        for skill_file in "$SKILLS_DIR/$skill_cat"/*/SKILL.md; do
            if [ -f "$skill_file" ]; then
                skill_name=$(basename "$(dirname "$skill_file")")
                echo "     ✓ Load: view backbone/skills/$skill_cat/$skill_name/SKILL.md"
            fi
        done
        break
    fi
done
echo ""
echo "  ℹ️  To load a skill, use: view backbone/skills/<category>/<skill-name>/SKILL.md"
echo ""

echo "  After work is complete:"
echo "    - Mark task [x] in backbone/3-TASKS.md"
if [ -f "$DECISIONS_FILE" ]; then
    echo "    - Update backbone/5-DECISIONS.md with architectural decisions"
fi
if [ -f "$MEMORY_FILE" ]; then
    echo "    - Update backbone/6-MEMORY.md with insights/pitfalls learned"
fi
echo "    - Commit with conventional message: feat(scope): description"
echo ""

# Add merge reminder if in worktree
if [ "$AUTO_WORKTRUNK_DONE" = false ] && [ -n "$GIT_DIR" ] && [[ "$GIT_DIR" == *"worktrees"* ]]; then
    echo "  🌳 You are in a worktree. When done:"
    echo "     bash scripts/merge-feature.sh"
    echo ""
fi

echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

exit 0
