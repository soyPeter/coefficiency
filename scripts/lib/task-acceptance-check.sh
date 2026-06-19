#!/bin/bash
# =============================================================================
# scripts/lib/task-acceptance-check.sh — Shared library for task completion
# acceptance criteria validation.
#
# Usage:
#   source "$(dirname "$0")/../lib/task-acceptance-check.sh"
#   check_task_completion "$PROJECT_DIR" "$task_line"
#
# Returns:
#   0 = acceptance criteria met (or exempt)
#   1 = criteria not met (prints block message to stderr)
# =============================================================================

# NOTE: No 'set -e' here — this is a library meant to be sourced.
# Functions return error codes that callers handle.

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

# ── Task Type Detection ─────────────────────────────────────────────────────

# Check if task is exempt from acceptance criteria validation.
# Exempt types: fix, docs, refactor, chore, test, perf, ci, build
is_task_exempt() {
    local task_line="$1"
    # Match keyword after optional checkbox syntax: "- [x] fix:" or "fix:"
    if echo "$task_line" | grep -qiE '(^|\s)(fix|bug|docs|refactor|clean|chore|test|perf|ci|build|style)(\s|:)'; then
        return 0
    fi
    return 1
}

# Extract PRD reference from task line.
# Looks for patterns like: backbone/artifacts/prd/YYYY-MM-DD-feature.md or (PRD: ...)
extract_prd_from_task() {
    local task_line="$1"
    local prd_ref

    # Pattern 1: (PRD: backbone/artifacts/prd/file.md)
    prd_ref=$(echo "$task_line" | grep -oE 'backbone/artifacts/prd/[^)]+\.md' | head -1 || true)
    if [ -n "$prd_ref" ]; then
        echo "$prd_ref"
        return 0
    fi

    # Pattern 2: PRD: backbone/artifacts/prd/file.md
    prd_ref=$(echo "$task_line" | grep -oE 'PRD:\s*backbone/artifacts/prd/[^ ]+\.md' | sed 's/PRD://' | awk '{print $1}' | head -1 || true)
    if [ -n "$prd_ref" ]; then
        echo "$prd_ref"
        return 0
    fi

    # Pattern 3: Look for proposal.md in backbone/artifacts/changes/ (new path)
    if [ -d "backbone/changes" ]; then
        local chng_proposal
        chng_proposal=$(echo "$task_line" | grep -oE 'backbone/artifacts/changes/CHNG-[^/]+/proposal\.md' | head -1 || true)
        if [ -n "$chng_proposal" ]; then
            echo "$chng_proposal"
            return 0
        fi
        # Pattern 4: Look for any proposal.md in CHNG folders matching task keywords
        local task_keyword
        task_keyword=$(echo "$task_line" | grep -oE 'Task [0-9]+' | head -1 || true)
        if [ -z "$task_keyword" ]; then
            task_keyword=$(echo "$task_line" | grep -oE '[A-Z][a-z]+' | head -1 || true)
        fi
        # Try to find proposal.md in any change folder
        for chng_dir in backbone/artifacts/changes/CHNG-*; do
            [ -d "$chng_dir" ] || continue
            local prop="$chng_dir/proposal.md"
            if [ -f "$prop" ]; then
                echo "$prop"
                return 0
            fi
        done
    fi
    return 1
}

# ── PRD Requirement Extraction ──────────────────────────────────────────────

# Extract all REQ- IDs from a PRD file.
# Looks for patterns like: REQ-AUTH-001, REQ-API-042, etc.
get_req_ids_from_prd() {
    local prd_file="$1"

    if [ ! -f "$prd_file" ]; then
        echo ""
        return 0
    fi

    # Extract REQ- IDs from the PRD content
    # Matches lines like: "  REQ-AUTH-001: When the user ..." or "- REQ-AUTH-001"
    grep -oE 'REQ-[A-Z0-9]+-[0-9]+' "$prd_file" | sort -u || true
}

# ── Traceability Verification ───────────────────────────────────────────────

# Check traceability YAML for a given REQ-ID.
# Returns a space-separated string of statuses: "code tests"
# Each can be "ok" or "missing".
check_req_traceability() {
    local project_dir="$1"
    local req_id="$2"

    local trace_dir="$project_dir/backbone/artifacts/traceability"
    local code_status="missing"
    local tests_status="missing"

    if [ ! -d "$trace_dir" ]; then
        echo "$code_status $tests_status"
        return 0
    fi

    # Search all traceability YAML files for this REQ-ID
    for trace_file in "$trace_dir"/*.yml; do
        [ -f "$trace_file" ] || continue

        # Check if this file contains the REQ-ID
        if grep -q "$req_id" "$trace_file" 2>/dev/null; then
            # Extract the section for this REQ-ID
            # Look for the REQ-ID as a key, then check code: and tests: entries
            local section
            section=$(python3 -c "
import re
content = open('$trace_file').read()
# Find the block starting with this REQ-ID
match = re.search(r'^\s+$req_id:\s*(.*?)(?=^\s+REQ-[A-Z]+-[0-9]+:|\Z)', content, re.MULTILINE | re.DOTALL)
if match:
    block = match.group(1)
    has_code = 'code:' in block
    has_tests = 'tests:' in block
    # Check if entries are non-empty (have files listed)
    code_entries = re.findall(r'code:\s*(.+)', block)
    tests_entries = re.findall(r'tests:\s*(.+)', block)
    code_nonempty = any(c.strip() and c.strip() != '[]' for c in code_entries)
    tests_nonempty = any(t.strip() and t.strip() != '[]' for t in tests_entries)
    print('has_code' if has_code and code_nonempty else 'no_code')
    print('has_tests' if has_tests and tests_nonempty else 'no_tests')
else:
    print('no_code')
    print('no_tests')
" 2>/dev/null || true)

            if echo "$section" | grep -q "has_code"; then
                code_status="ok"
            fi
            if echo "$section" | grep -q "has_tests"; then
                tests_status="ok"
            fi
        fi
    done

    echo "$code_status $tests_status"
}

# ── Test Content Verification ───────────────────────────────────────────────

# Verify that test files actually contain the REQ-ID string.
# This ensures tests are genuinely linked to requirements, not just listed.
verify_test_content() {
    local project_dir="$1"
    local req_id="$2"

    local found=false

    # Search common test directories for the REQ-ID
    for test_dir in "$project_dir/src/test" "$project_dir/tests" "$project_dir/test"; do
        [ -d "$test_dir" ] || continue

        # Use find + grep to search for exact REQ-ID in test files
        if find "$test_dir" -type f \( -name "*.java" -o -name "*.kt" -o -name "*.go" -o -name "*.py" -o -name "*.js" -o -name "*.ts" \) -exec grep -l "$req_id" {} + 2>/dev/null | head -1 | grep -q .; then
            found=true
            break
        fi
    done

    if [ "$found" = true ]; then
        echo "ok"
    else
        echo "missing"
    fi
}

# ── Main Validation Entry Point ─────────────────────────────────────────────

# Check if a single task line can be marked complete.
# Prints block message to stderr and returns 1 if criteria not met.
# Returns 0 if criteria met or task is exempt.
check_task_completion() {
    local project_dir="$1"
    local task_line="$2"

    # Check override
    if [ "${CLAUDE_CODE_SKIP_TASK_COMPLETION:-0}" = "1" ]; then
        return 0
    fi

    # 1. Check if task is exempt
    if is_task_exempt "$task_line"; then
        return 0
    fi

    # 2. Extract PRD reference
    local prd_ref
    prd_ref=$(extract_prd_from_task "$task_line")

    if [ -z "$prd_ref" ]; then
        echo ""
        echo -e "${YELLOW}⚠️  TASK COMPLETION VALIDATION${NC}" >&2
        echo "" >&2
        echo "  Feature task must reference a PRD with acceptance criteria." >&2
        echo "" >&2
        echo "  Task: $task_line" >&2
        echo "" >&2
        echo "  Required format:" >&2
        echo "    - [ ] feat: Description (PRD: backbone/artifacts/prd/YYYY-MM-DD-feature.md)" >&2
        echo "" >&2
        echo "  Or mark as fix/docs/refactor if no PRD needed." >&2
        echo "" >&2
        return 1
    fi

    local prd_file="$project_dir/$prd_ref"
    if [ ! -f "$prd_file" ]; then
        echo ""
        echo -e "${YELLOW}⚠️  TASK COMPLETION VALIDATION${NC}" >&2
        echo "" >&2
        echo "  Referenced PRD not found: $prd_ref" >&2
        echo "" >&2
        return 1
    fi

    # 3. Extract REQ-IDs from PRD
    local req_ids
    req_ids=$(get_req_ids_from_prd "$prd_file")

    if [ -z "$req_ids" ]; then
        echo ""
        echo -e "${YELLOW}⚠️  TASK COMPLETION VALIDATION${NC}" >&2
        echo "" >&2
        echo "  PRD has no acceptance criteria (REQ- IDs)." >&2
        echo "  PRD: $prd_ref" >&2
        echo "" >&2
        echo "  Add EARS requirements with REQ- IDs to the PRD." >&2
        echo "  See: backbone/skills/general/ears-requirements/SKILL.md" >&2
        echo "" >&2
        return 1
    fi

    # 4. Check each REQ-ID
    local issues=""
    local all_ok=true

    while IFS= read -r req_id; do
        [ -z "$req_id" ] && continue

        local trace_result
        trace_result=$(check_req_traceability "$project_dir" "$req_id")

        local code_status
        code_status=$(echo "$trace_result" | awk '{print $1}')
        local tests_status
        tests_status=$(echo "$trace_result" | awk '{print $2}')

        local test_content_status="ok"
        if [ "$tests_status" = "ok" ]; then
            test_content_status=$(verify_test_content "$project_dir" "$req_id")
        fi

        if [ "$code_status" != "ok" ] || [ "$tests_status" != "ok" ] || [ "$test_content_status" != "ok" ]; then
            all_ok=false
            local issue=""
            if [ "$code_status" != "ok" ]; then
                issue="missing code implementation"
            elif [ "$tests_status" != "ok" ]; then
                issue="missing tests"
            elif [ "$test_content_status" != "ok" ]; then
                issue="tests don't reference REQ-ID"
            fi
            issues="${issues}\n  $req_id: $issue"
        fi
    done <<< "$req_ids"

    if [ "$all_ok" = false ]; then
        echo ""
        echo -e "${YELLOW}⚠️  TASK COMPLETION VALIDATION${NC}" >&2
        echo "" >&2
        echo -e "  Task cannot be marked complete — acceptance criteria not met:" >&2
        echo -e "$issues" >&2
        echo "" >&2
        echo "  PRD: $prd_ref" >&2
        echo "" >&2
        echo "  Run ./scripts/extract-traceability.sh to auto-build traceability." >&2
        echo "  Then verify with ./scripts/verify-traceability.sh" >&2
        echo "" >&2
        return 1
    fi

    return 0
}

# Check all newly-[x] tasks in a 3-TASKS.md diff.
# Used by pre-commit gate to validate staged changes.
# Returns 0 if all new [x] tasks are valid.
check_staged_tasks_completion() {
    local project_dir="$1"
    local diff_content="$2"

    local errors=0

    # Find lines that changed from [ ] or [WIP] to [x]
    local new_x_tasks
    new_x_tasks=$(echo "$diff_content" | grep -E '^\+.*-\s*\[x\]' | sed 's/^+//' || true)

    if [ -z "$new_x_tasks" ]; then
        return 0
    fi

    while IFS= read -r task_line; do
        [ -z "$task_line" ] && continue

        if ! check_task_completion "$project_dir" "$task_line" 2>/dev/null; then
            # Re-run to capture stderr for this specific task
            check_task_completion "$project_dir" "$task_line" >&2 || errors=$((errors + 1))
        fi
    done <<< "$new_x_tasks"

    return "$errors"
}
