#!/bin/bash
# pre-tool-use-task-granularity-check.sh: Gate P->T -- Block vague/over-sized tasks in 3-TASKS.md
#
# Fires BEFORE Write/Edit to backbone/3-TASKS.md when adding [WIP].
# Enforces two hard gates:
#   1. Planning doc exists for the referenced PRD (Gate P->T)
#   2. Task syntax is granular: size tag [XS/S/M/L], concrete WHAT+WHERE,
#      no vague verbs, no scope bloat words. XL is blocked.
#
# Override: export CLAUDE_CODE_SKIP_GRANULARITY=1

set -euo pipefail

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"

# Skip if override is set
if [ "${CLAUDE_CODE_SKIP_GRANULARITY:-0}" = "1" ]; then
    exit 0
fi

# ---- Light mode bypass ----
if [ -f "backbone/.MODE" ]; then
    MODE=$(tr -d '[:space:]' < "backbone/.MODE" 2>/dev/null || echo "standard")
    [ "$MODE" = "light" ] && echo "  🟢 LIGHT MODE: Advisory only — task granularity check skipped." && exit 0
fi

# Read stdin JSON from Claude Code
INPUT=$(cat)
[ -z "$INPUT" ] && exit 0

# Parse tool and file path
TOOL=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_name',''))" 2>/dev/null || true)
TARGET_FILE=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))" 2>/dev/null || true)

# Only check Write/Edit to 3-TASKS.md
if [[ "$TOOL" != "Write" && "$TOOL" != "Edit" ]]; then
    exit 0
fi

if [[ "$TARGET_FILE" != *"backbone/3-TASKS.md"* ]]; then
    exit 0
fi

# Extract new content being written
CONTENT=$(echo "$INPUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
tool = d.get('tool_name', '')
if tool == 'Write':
    print(d.get('tool_input', {}).get('content', ''))
elif tool == 'Edit':
    print(d.get('tool_input', {}).get('new_string', ''))
" 2>/dev/null || true)

if [ -z "$CONTENT" ]; then
    exit 0
fi

# Find lines that set [WIP] (from [ ] or newly added)
NEW_WIP_TASKS=$(echo "$CONTENT" | grep -E '^\s*-\s*\[WIP\]' || true)

if [ -z "$NEW_WIP_TASKS" ]; then
    exit 0
fi

# ── Shared validation function ──────────────────────────────────────────────

validate_task() {
    local task_line="$1"
    local errors=""
    local warnings=""
    local is_exempt=false

    # Extract task text after [WIP]
    local task_text
    task_text=$(echo "$task_line" | sed 's/.*\[WIP\]\s*//' | sed 's/^[[:space:]]*//')

    # Check exempt types
    if echo "$task_text" | grep -qiE '^(fix|bug|docs|refactor|clean|chore|test|perf|ci|build|style)[[:space:]:]'; then
        is_exempt=true
    fi

    # ── 1. Size tag check ───────────────────────────────────────────────────
    # Exempt tasks skip size tag requirement
    if [ "$is_exempt" = false ]; then
        local size_tag
        size_tag=$(echo "$task_text" | grep -oE '^\[[A-Z]{1,2}\]' | head -1 || true)

        if [ -z "$size_tag" ]; then
            errors="${errors}\n    - Missing size tag. Required: [XS], [S], [M], or [L]"
        else
            # Normalize: remove brackets
            local size
            size=$(echo "$size_tag" | tr -d '[]')

            if [ "$size" = "XL" ]; then
                errors="${errors}\n    - Size [XL] is forbidden. Break this task into smaller [XS/S/M/L] tasks."
            elif [ "$size" = "L" ]; then
                warnings="${warnings}\n    - Warning: [L] tasks should be rare. Consider breaking into [M] or smaller."
            fi
        fi
    fi

    # ── 2. Word count check (after size tag and type prefix) ────────────────
    # Strip size tag and conventional commit prefix for word count
    local words_only
    words_only=$(echo "$task_text" | sed 's/^\[[A-Z]\{1,2\}\]\s*//' | sed 's/^[[:space:]]*//' | sed 's/^[a-z]*(\([^)]*\)):\s*//i' | sed 's/^[a-z]*:\s*//i' | sed 's/^[[:space:]]*//')
    local word_count
    word_count=$(echo "$words_only" | wc -w | tr -d ' ')

    if [ "$word_count" -lt 5 ]; then
        errors="${errors}\n    - Too short ($word_count words after tag). Minimum 5 words describing WHAT and WHERE."
    fi

    # ── 3. Vague verb check ─────────────────────────────────────────────────
    local vague_verbs="implement|build|develop|do|make|setup|set up"
    if echo "$words_only" | grep -qiE "^($vague_verbs)\b"; then
        errors="${errors}\n    - Starts with vague verb. Use: add, fix, remove, configure, validate, create, update, extract, refactor."
    fi

    # ── 4. Scope bloat check ────────────────────────────────────────────────
    local bloat_words="and|all|entire|everything|system|module|feature|epic|whole|complete|full"
    local found_bloat
    found_bloat=$(echo "$words_only" | grep -oiE "\b($bloat_words)\b" | sort -u | tr '\n' ' ' | sed 's/ $//')
    if [ -n "$found_bloat" ]; then
        errors="${errors}\n    - Contains scope bloat word(s): '$found_bloat'. Each task must do ONE concrete thing."
    fi

    # ── 5. Tasks doc check (hard gate B) ────────────────────────────────────
    # Only for non-exempt tasks that reference a PRD or changes folder
    if [ "$is_exempt" = false ]; then
        local prd_ref change_ref
        prd_ref=$(echo "$task_line" | grep -oE 'backbone/artifacts/prd/[^ )]+\.md' | head -1 || true)
        change_ref=$(echo "$task_line" | grep -oE 'backbone/artifacts/changes/[^ )]+' | head -1 || true)

        if [ -n "$change_ref" ]; then
            # Check for tasks.md in the changes/ folder
            local change_dir="$PROJECT_DIR/$change_ref"
            # change_ref is e.g. backbone/artifacts/changes/CHNG-001 — dirname gives backbone/changes
            local change_base
            change_base=$(basename "$change_ref")  # CHNG-001
            local change_parent
            change_parent=$(dirname "$change_ref") # backbone/changes
            local tasks_file="$PROJECT_DIR/$change_parent/$change_base/tasks.md"
            if [ ! -f "$tasks_file" ]; then
                errors="${errors}\n    - tasks.md not found in change folder: $change_ref\n      Expected: $tasks_file"
            fi
        elif [ -n "$prd_ref" ]; then
            local prd_basename
            prd_basename=$(basename "$prd_ref" .md)
            local feature_name
            feature_name=$(echo "$prd_basename" | sed 's/^[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}-//')

            local planning_dir="$PROJECT_DIR/backbone/planning"
            local planning_found=false

            if [ -d "$planning_dir" ]; then
                for candidate in "$planning_dir"/*.md; do
                    [ -f "$candidate" ] || continue
                    local candidate_base
                    candidate_base=$(basename "$candidate" .md)
                    if echo "$candidate_base" | grep -qi "$feature_name" || echo "$feature_name" | grep -qi "$candidate_base"; then
                        planning_found=true
                        break
                    fi
                done
            fi

            if [ "$planning_found" = false ]; then
                errors="${errors}\n    - Missing planning doc for PRD: $prd_ref\n      Expected: backbone/artifacts/planning/*$feature_name*.md"
            fi
        fi
    fi

    # ── Return result ───────────────────────────────────────────────────────
    if [ -n "$errors" ]; then
        echo "BLOCK:$errors"
        return 1
    elif [ -n "$warnings" ]; then
        echo "WARN:$warnings"
        return 0
    else
        echo "OK"
        return 0
    fi
}

# ── Validate each new [WIP] task ────────────────────────────────────────────

errors_found=false
warnings_found=false
error_report=""
warning_report=""

while IFS= read -r task_line; do
    [ -z "$task_line" ] && continue

    result=$(validate_task "$task_line" || true)

    if echo "$result" | grep -q "^BLOCK:"; then
        errors_found=true
        task_errors=$(echo "$result" | sed 's/^BLOCK://')
        error_report="${error_report}\n  Task: $task_line${task_errors}"
    elif echo "$result" | grep -q "^WARN:"; then
        warnings_found=true
        task_warnings=$(echo "$result" | sed 's/^WARN://')
        warning_report="${warning_report}\n  Task: $task_line${task_warnings}"
    fi
done <<< "$NEW_WIP_TASKS"

# Print warnings (non-blocking)
if [ "$warnings_found" = true ]; then
    echo ""
    echo -e "${YELLOW}⚠️  TASK GRANULARITY WARNINGS${NC}"
    echo -e "$warning_report"
    echo ""
fi

# Print errors and block
if [ "$errors_found" = true ]; then
    echo ""
    echo -e "${YELLOW}❌ TASK GRANULARITY GATE P→T NOT SATISFIED${NC}"
    echo ""
    echo "  New [WIP] tasks failed validation:"
    echo -e "$error_report"
    echo ""
    echo "  Requirements for non-exempt tasks:"
    echo "    1. Planning doc MUST exist: backbone/artifacts/planning/<feature-name>.md"
    echo "    2. Size tag REQUIRED: [XS], [S], [M], [L]  (XL forbidden)"
    echo "    3. Minimum 5 words describing WHAT + WHERE"
    echo "    4. Use concrete verbs: add, fix, remove, configure, validate, create, update, extract, refactor"
    echo "    5. NO scope bloat: and, all, entire, everything, system, module, feature, epic"
    echo "    6. ONE thing per task"
    echo ""
    echo "  Good examples:"
    echo "    - [WIP] [S] feat: add email regex validator to UserRegistrationUseCase"
    echo "    - [WIP] [M] feat: create OrderPlaced domain event with JSON serialization"
    echo "    - [WIP] [XS] fix: remove unused import from JwtAuthenticationFilter"
    echo ""
    echo "  Override: export CLAUDE_CODE_SKIP_GRANULARITY=1"
    echo ""
    exit 1
fi

exit 0
