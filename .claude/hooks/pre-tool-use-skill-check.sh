#!/bin/bash
# PreToolUse hook: Verify skill patterns before writing code
# Runs before Write/Edit tool use
# Parses stdin JSON to check new file content BEFORE file is written
#
# FEATURES:
# 1. Layer pattern violations → warning (advisory)
# 2. Skill acknowledgment required → BLOCKING until acknowledged
#
# Skill acknowledgment tracking: .claude/skill-acknowledgments.json

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
KNOWLEDGE_FILE="$PROJECT_DIR/backbone/4-KNOWLEDGE.md"
SKILL_ACK_FILE="$PROJECT_DIR/.claude/skill-acknowledgments.json"

# ---- Light mode bypass ----
if [ -f "$PROJECT_DIR/backbone/.MODE" ]; then
    MODE=$(tr -d '[:space:]' < "$PROJECT_DIR/backbone/.MODE" 2>/dev/null || echo "standard")
    if [ "$MODE" = "light" ]; then
        echo "  🟢 LIGHT MODE: Advisory only — skill/layer check skipped."
        exit 0
    fi
fi

# Detect framework
FRAMEWORK=""
if [ -f "$KNOWLEDGE_FILE" ]; then
    FRAMEWORK=$(grep -E '^\s*-\s+\*\*Core:' "$KNOWLEDGE_FILE" 2>/dev/null | grep -oE '(Quarkus|Spring Boot|Laravel|Kotlin|Go|Python)' | head -1 || true)
fi

# Map framework display name to skill key
FRAMEWORK_SKILL_KEY=""
case "$FRAMEWORK" in
    Quarkus) FRAMEWORK_SKILL_KEY="quarkus" ;;
    Spring*) FRAMEWORK_SKILL_KEY="springboot" ;;
    Laravel) FRAMEWORK_SKILL_KEY="laravel" ;;
    Kotlin) FRAMEWORK_SKILL_KEY="kotlin" ;;
    Go) FRAMEWORK_SKILL_KEY="golang" ;;
    Python) FRAMEWORK_SKILL_KEY="python" ;;
esac

# Read stdin JSON from Claude Code
INPUT=$(cat)
[ -z "$INPUT" ] && exit 0

# Parse tool and file path from JSON
TOOL=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_name',''))" 2>/dev/null || true)
TARGET_FILE=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))" 2>/dev/null || true)

# Parse content from tool_input
CONTENT=""
if [[ "$TOOL" == "Write" ]]; then
    CONTENT=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('content',''))" 2>/dev/null || true)
    [ -z "$CONTENT" ] && CONTENT=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('new_string',''))" 2>/dev/null || true)
elif [[ "$TOOL" == "Edit" ]]; then
    CONTENT=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('new_string',''))" 2>/dev/null || true)
fi

# Only check Write and Edit tools
if [[ "$TOOL" != "Write" && "$TOOL" != "Edit" ]]; then
    exit 0
fi

# Skip if no file
if [ -z "$TARGET_FILE" ]; then
    exit 0
fi

# Skip documentation and non-code files
if [[ "$TARGET_FILE" == *.md || "$TARGET_FILE" == *README* || "$TARGET_FILE" == *backbone/* ]]; then
    exit 0
fi

# Extract the layer from the file path
LAYER=""
LAYER_SKILL=""
case "$TARGET_FILE" in
    *domain/*)
        LAYER="domain"
        LAYER_SKILL="java/java-core"
        ;;
    *app/*)
        LAYER="app"
        case "$FRAMEWORK" in
            Quarkus) LAYER_SKILL="java/java-cdi" ;;
            Spring*) LAYER_SKILL="springboot/springboot-di" ;;
            *) LAYER_SKILL="" ;;
        esac
        ;;
    *infra/*)
        LAYER="infra"
        LAYER_SKILL=""
        ;;
    *api/*|*controller*|*resource*)
        LAYER="api"
        case "$FRAMEWORK" in
            Quarkus) LAYER_SKILL="quarkus/java-quarkus" ;;
            Spring*) LAYER_SKILL="springboot/springboot-patterns" ;;
            Laravel) LAYER_SKILL="laravel/laravel-patterns" ;;
            *) LAYER_SKILL="" ;;
        esac
        ;;
esac

# Skip if we can't determine the layer
if [ -z "$LAYER" ]; then
    exit 0
fi

# ============================================================
# PART 1: WORKTRUNK WORKFLOW CHECK (BLOCKING)
# ============================================================

# Only enforce for code files, not docs or backbone files
if [[ "$TARGET_FILE" != *.md && "$TARGET_FILE" != *README* && "$TARGET_FILE" != *backbone/* ]]; then
    # Check if we're in a git repo
    if git rev-parse --git-dir >/dev/null 2>&1; then
        # Check if we're in a worktree (not the main working tree)
        GIT_DIR=$(git rev-parse --git-dir 2>/dev/null || true)
        CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)
        
        # If not in a worktree and on main/master/dev branch
        if [[ "$GIT_DIR" != *"worktrees"* ]] && [[ "$CURRENT_BRANCH" =~ ^(main|master|dev|develop)$ ]]; then
            TASKS_FILE="$PROJECT_DIR/backbone/3-TASKS.md"
            
            if [ -f "$TASKS_FILE" ]; then
                # Find WIP tasks
                WIP_TASKS=$(grep -i "\[WIP\]" "$TASKS_FILE" 2>/dev/null || true)
                
                if [ -n "$WIP_TASKS" ]; then
                    # Check if any WIP task is feature work (not fix/docs/refactor)
                    FIX_KEYWORDS="fix|bug|docs|update|refactor|clean|remove|chore|test|style|perf|ci|build|revert"
                    
                    # Extract task descriptions (text after [WIP])
                    FEATURE_WORK=""
                    while IFS= read -r line; do
                        TASK_TEXT=$(echo "$line" | sed 's/.*\[WIP\]\s*//' | tr '[:upper:]' '[:lower:]')
                        
                        # If task text doesn't contain fix keywords, it's feature work
                        if ! echo "$TASK_TEXT" | grep -qiE "^\s*-?\s*($FIX_KEYWORDS)"; then
                            FEATURE_WORK="$line"
                            break
                        fi
                    done <<< "$WIP_TASKS"
                    
                    if [ -n "$FEATURE_WORK" ]; then
                        echo ""
                        echo "╔════════════════════════════════════════════════════════════════╗"
                        echo "║  🚫 BLOCKED: Feature work on main branch                      ║"
                        echo "╚════════════════════════════════════════════════════════════════╝"
                        echo ""
                        echo "  Current branch: $CURRENT_BRANCH"
                        echo "  You have a WIP feature task:"
                        echo "    $FEATURE_WORK"
                        echo ""
                        echo "  Agentic Backbone requires parallel feature work in worktrees."
                        echo ""
                        
                        # Try to auto-create worktree
                        TASK_DESC=$(echo "$FEATURE_WORK" | sed 's/.*\[WIP\]\s*//' | sed 's/[^a-zA-Z0-9 ]//g' | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/-*$//g' | sed 's/^-*//g')
                        BRANCH_NAME="feat/$TASK_DESC"
                        REPO_NAME=$(basename "$PROJECT_DIR")
                        WORKTREE_PATH="$PROJECT_DIR/../$REPO_NAME-$(echo "$BRANCH_NAME" | tr '/' '-')"
                        
                        echo "  🌳 Auto-creating worktree: $BRANCH_NAME"
                        echo ""
                        
                        # Use scripts/worktrunk.sh if available, otherwise raw git
                        if [ -f "$PROJECT_DIR/scripts/worktrunk.sh" ]; then
                            if "$PROJECT_DIR/scripts/worktrunk.sh" create "$TASK_DESC" 2>/dev/null; then
                                if [ -d "$WORKTREE_PATH" ]; then
                                    echo "  ✅ Worktree created: $WORKTREE_PATH"
                                    echo ""
                                    echo "  🔄 IMPORTANT: Change to the new worktree to continue:"
                                    echo "     cd $WORKTREE_PATH"
                                    echo ""
                                    echo "  Or restart your session in the new directory."
                                    echo ""
                                fi
                            else
                                echo "  ⚠️  Auto-creation failed. Create manually:"
                                echo "     $PROJECT_DIR/scripts/worktrunk.sh create $TASK_DESC"
                                echo ""
                            fi
                        else
                            # Raw git fallback
                            git branch "$BRANCH_NAME" dev 2>/dev/null || git branch "$BRANCH_NAME" main 2>/dev/null || true
                            if git worktree add "$WORKTREE_PATH" "$BRANCH_NAME" 2>/dev/null; then
                                echo "  ✅ Worktree created: $WORKTREE_PATH"
                                echo ""
                                echo "  🔄 IMPORTANT: Change to the new worktree to continue:"
                                echo "     cd $WORKTREE_PATH"
                                echo ""
                            else
                                echo "  ⚠️  Auto-creation failed. Create manually:"
                                echo "     git worktree add -b $BRANCH_NAME ../$REPO_NAME-$(echo "$BRANCH_NAME" | tr '/' '-') main"
                                echo ""
                            fi
                        fi
                        
                        echo "  Or if this is a fix/refactor, update 3-TASKS.md to use"
                        echo "  keywords: fix, bug, docs, update, refactor, clean, remove"
                        echo ""
                        echo "  Learn more: backbone/reference/guides/worktrunk.md"
                        echo ""
                        echo "╚════════════════════════════════════════════════════════════════╝"
                        echo ""
                        exit 1
                    fi
                fi
            fi
        fi
    fi
fi

# ============================================================
# PART 2: SKILL ACKNOWLEDGMENT CHECK (BLOCKING)
# ============================================================

check_skill_acknowledged() {
    local skill_path="$1"
    if [ -z "$skill_path" ]; then
        return 0  # No skill required
    fi
    
    if [ ! -f "$SKILL_ACK_FILE" ]; then
        return 1  # Not acknowledged
    fi
    
    # Check if skill is in acknowledged list
    if grep -q "\"skill_path\":.*\"backbone/skills/$skill_path/SKILL.md\"" "$SKILL_ACK_FILE" 2>/dev/null; then
        return 0
    fi
    return 1
}

acknowledge_skill() {
    local skill_path="$1"
    local session_id="${CLAUDE_SESSION_ID:-$(date +%s)}"
    
    mkdir -p "$PROJECT_DIR/.claude"
    
    # Create JSON entry
    local entry="{\"skill_path\": \"backbone/skills/$skill_path/SKILL.md\", \"acknowledged_at\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\", \"session_id\": \"$session_id\"}"
    
    if [ ! -f "$SKILL_ACK_FILE" ]; then
        echo "{\"acknowledged_skills\": [$entry]}" > "$SKILL_ACK_FILE"
    else
        # Add to existing list (avoid duplicates)
        local new_list=$(echo "$(cat "$SKILL_ACK_FILE")" | python3 -c "
import sys, json
data = json.load(sys.stdin)
entry = json.loads('''$entry''')
# Remove if already exists
data['acknowledged_skills'] = [s for s in data.get('acknowledged_skills', []) if s.get('skill_path') != entry['skill_path']]
data['acknowledged_skills'].append(entry)
print(json.dumps(data, indent=2))
" 2>/dev/null || echo "{\"acknowledged_skills\": [$entry]}")
        echo "$new_list" > "$SKILL_ACK_FILE"
    fi
}

# Check if skill needs to be acknowledged
REQUIRED_SKILL=""
if [ -n "$LAYER_SKILL" ]; then
    if ! check_skill_acknowledged "$LAYER_SKILL"; then
        REQUIRED_SKILL="$LAYER_SKILL"
    fi
fi

# If skill required but not acknowledged, block
if [ -n "$REQUIRED_SKILL" ]; then
    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║  ⚠️  SKILL ACKNOWLEDGMENT REQUIRED                            ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "  You are about to write code in: $LAYER layer"
    echo "  Framework: $FRAMEWORK"
    echo ""
    echo "  Required skill for this layer:"
    echo "    view backbone/skills/$REQUIRED_SKILL/SKILL.md"
    echo ""
    echo "  This skill contains patterns for:"
    case "$LAYER" in
        domain)
            echo "  - Pure Java domain model rules"
            echo "  - No framework dependencies"
            echo "  - Proper encapsulation"
            ;;
        app)
            echo "  - Use case patterns"
            echo "  - Dependency injection rules"
            echo "  - Service orchestration"
            ;;
        api)
            echo "  - REST resource annotations"
            echo "  - Request/response handling"
            echo "  - Error mapping patterns"
            ;;
    esac
    echo ""
    echo "  ─────────────────────────────────────────────────────────────"
    echo "  To acknowledge this skill and continue, type:"
    echo "    acknowledge"
    echo ""
    echo "  Or load the skill first, then continue."
    echo "  ─────────────────────────────────────────────────────────────"
    echo ""
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    
    # Check if the input contains 'acknowledge'
    if echo "$INPUT" | grep -q '"text"' 2>/dev/null; then
        USER_TEXT=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('text',''))" 2>/dev/null || true)
        if echo "$USER_TEXT" | grep -qi "^acknowledge$"; then
            acknowledge_skill "$REQUIRED_SKILL"
            echo "✅ Skill acknowledged: $REQUIRED_SKILL"
            exit 0  # Allow to proceed
        fi
    fi
    
    exit 1  # Block
fi

# ============================================================
# PART 3: LAYER PATTERN VIOLATIONS (BLOCKING)
# ============================================================

WARNINGS=""
BLOCK_LAYER=false

check_patterns() {
    local text="$1"
    local source="$2"
    
    case "$LAYER" in
        domain)
            if echo "$text" | grep -qE "org\.(jboss|quarkus|spring|weld|jakarta|io\.quarkus)"; then
                WARNINGS="$WARNINGS
  🚫 DOMAIN LAYER: Code must NOT import framework classes"
                BLOCK_LAYER=true
            fi
            if echo "$text" | grep -qE "@(Entity|Table|Repository|ApplicationScoped|Stateless)"; then
                WARNINGS="$WARNINGS
  🚫 DOMAIN LAYER: Must NOT use CDI/JPA annotations"
                BLOCK_LAYER=true
            fi
            if echo "$text" | grep -qE "@Data|@Getter|@Setter"; then
                WARNINGS="$WARNINGS
  🚫 DOMAIN LAYER: Use Java Records instead of Lombok @Data"
                BLOCK_LAYER=true
            fi
            ;;
        app)
            if echo "$text" | grep -qE "@ApplicationScoped|@Singleton|@RequestScoped|@SessionScoped"; then
                WARNINGS="$WARNINGS
  🚫 APP LAYER: Don't use CDI scopes (use in infra only)"
                BLOCK_LAYER=true
            fi
            ;;
        infra)
            ;;
        api)
            case "$FRAMEWORK" in
                Quarkus)
                    if echo "$text" | grep -qE "@(RestController|Controller)"; then
                        WARNINGS="$WARNINGS
  🚫 API LAYER: Use JAX-RS @Path instead of @RestController"
                        BLOCK_LAYER=true
                    fi
                    ;;
                Spring*)
                    if echo "$text" | grep -qE "@Path|@Produces.*APPLICATION_JSON"; then
                        WARNINGS="$WARNINGS
  🚫 API LAYER: Use Spring @RestController, @RequestMapping"
                        BLOCK_LAYER=true
                    fi
                    ;;
            esac
            ;;
    esac
}

# Check new content first (if provided), then file on disk
if [ -n "$CONTENT" ]; then
    check_patterns "$CONTENT" "new file content"
elif [ -f "$TARGET_FILE" ]; then
    check_patterns "$(cat "$TARGET_FILE")" "existing file"
fi

# Block if layer violations found
if [ "$BLOCK_LAYER" = true ]; then
    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║  🚫 LAYER CONVENTION VIOLATION — BLOCKED                      ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo "  File: $TARGET_FILE"
    echo "  Layer: $LAYER ($FRAMEWORK)"
    echo "$WARNINGS"
    echo ""
    echo "  Fix the violation or update 3-TASKS.md to mark this task as:"
    echo "    [WIP] refactor: ..."
    echo ""
    echo "  Load skill for correct patterns:"
    echo "    view backbone/skills/$LAYER_SKILL/SKILL.md"
    echo "  See: backbone/4-KNOWLEDGE.md → Never DO List"
    echo ""
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    exit 1
fi

exit 0
