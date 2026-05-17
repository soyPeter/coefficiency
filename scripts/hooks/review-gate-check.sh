#!/bin/bash
# post-doc-check.sh extension: Review Gate Validation
# 
# This script checks that review gates are satisfied before allowing
# implementation-phase work. It is called by the post-doc-check.sh hook
# after documentation checks.
#
# Gates:
#   Gate R→D: PRD reviewed before design starts
#   Gate D→I: Design reviewed before implementation starts
#   Gate I→V: Tests pass before validation

set -euo pipefail

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"

# Check if we're in implementation phase (looking at task text)
check_implementation_gate() {
    local tasks_file="$PROJECT_DIR/backbone/3-TASKS.md"
    
    if [ ! -f "$tasks_file" ]; then
        return 0
    fi
    
    # Check if any [WIP] task mentions implementation without design doc reference
    local wip_tasks
    wip_tasks=$(grep '^\s*-\s*\[WIP\]' "$tasks_file" 2>/dev/null || true)
    
    if [ -z "$wip_tasks" ]; then
        return 0
    fi
    
    # Check if WIP task has design doc reference
    while IFS= read -r task; do
        # Skip if task has design doc reference
        if echo "$task" | grep -qi 'design.*backbone/design/'; then
            continue
        fi
        
        # Skip if task is fix/docs/refactor (doesn't require design)
        if echo "$task" | grep -qiE 'fix|bug|docs|refactor|clean|chore|test'; then
            continue
        fi
        
        # Check if PRD exists but design doc doesn't
        local prd_ref
        prd_ref=$(echo "$task" | grep -oE 'backbone/prd/[^)]+' | head -1 || true)
        
        if [ -n "$prd_ref" ]; then
            # Extract feature name from PRD
            local feature
            feature=$(basename "$prd_ref" .md | sed 's/^[0-9]*-[0-9]*-[0-9]*-//')
            
            # Check if design doc exists
            local design_doc="$PROJECT_DIR/backbone/design/${feature}-design.md"
            
            if [ ! -f "$design_doc" ]; then
                echo ""
                echo -e "${YELLOW}⚠️  REVIEW GATE D→I NOT SATISFIED${NC}"
                echo ""
                echo "  Task: $task"
                echo "  PRD exists but design doc missing: $design_doc"
                echo ""
                echo "  For feature work, run the full design pipeline:"
                echo "    /backbone:design-feature <name>"
                echo ""
                echo "  Or mark task as fix/docs/refactor if no design needed."
                echo ""
                return 1
            fi
        fi
    done <<< "$wip_tasks"
    
    return 0
}

# Main
check_implementation_gate
exit $?
