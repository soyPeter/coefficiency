#!/bin/bash
# pre-commit-ears-check.sh: Validates EARS syntax in staged PRD files
#
# Fires in pre-commit hook. Checks that PRD requirements use valid
# EARS (Easy Approach to Requirements Syntax) patterns and proper REQ- IDs.
#
# EARS Patterns Checked:
#   - Event-driven: WHEN <event> THEN <system> SHALL <response>
#   - Feature-driven: IF <feature> THEN <system> SHALL <response>
#   - Ubiquitous: <system> SHALL <response>
#   - State-driven: WHILE <state> <system> SHALL <response>
#   - Optional: IF <condition> THEN <system> MAY <response>
#
# Also validates:
#   - REQ- IDs match pattern REQ-[A-Z]+-[0-9]+
#   - No duplicate REQ- IDs within a PRD
#   - Each requirement has a REQ- ID
#   - Requirements are in a ## Requirements section

set -euo pipefail

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
ERRORS=0
WARNINGS=0

# Get staged PRD or proposal files
STAGED_PRDS=$(git diff --cached --name-only 2>/dev/null | grep -E '^backbone/artifacts/prd/.*\.md$|^backbone/artifacts/changes/.*/proposal\.md$' || true)

if [ -z "$STAGED_PRDS" ]; then
    exit 0
fi

echo "🔍 Gate R→D+: Validating EARS syntax in proposals..."

# EARS pattern regex (case-insensitive)
# Matches: WHEN ... THEN ... SHALL / IF ... THEN ... SHALL / ... SHALL / WHILE ... SHALL / IF ... MAY
EARS_PATTERN='(?i)(WHEN|IF|WHILE).*\b(THEN\s+)?\w+\s+(SHALL|MAY|MUST|SHOULD)\b|\b\w+\s+(SHALL|MAY|MUST|SHOULD)\b'

for prd in $STAGED_PRDS; do
    [ -f "$prd" ] || continue
    
    echo "  Checking $(basename "$prd")..."
    
    # Check for ## Requirements section
    if ! grep -qE '^## +Requirements' "$prd"; then
        echo -e "    ${YELLOW}⚠️  Missing '## Requirements' section${NC}"
        WARNINGS=$((WARNINGS + 1))
    fi
    
    # Extract requirement lines (lines starting with - or * after ## Requirements)
    req_section=$(sed -n '/^## *Requirements/,/^## /p' "$prd" | tail -n +2 | awk 'NR>1 || !/^## /')
    
    if [ -z "$req_section" ]; then
        echo -e "    ${YELLOW}⚠️  No requirements found in ## Requirements section${NC}"
        WARNINGS=$((WARNINGS + 1))
        continue
    fi
    
    # Check each requirement line
    line_num=0
    REQ_IDS=()
    
    while IFS= read -r line; do
        line_num=$((line_num + 1))
        
        # Skip empty lines and non-requirement lines
        [[ "$line" =~ ^[[:space:]]*[-*] ]] || continue
        
        # Check for REQ- ID
        req_id=$(echo "$line" | grep -oE 'REQ-[A-Z0-9]+-[0-9]+' | head -1 || true)
        
        if [ -z "$req_id" ]; then
            echo -e "    ${RED}❌ Requirement missing REQ- ID: $line${NC}"
            ERRORS=$((ERRORS + 1))
            continue
        fi
        
        # Check REQ- ID format
        if ! echo "$req_id" | grep -qE '^REQ-[A-Z0-9]+-[0-9]+$'; then
            echo -e "    ${RED}❌ Invalid REQ- ID format: $req_id${NC}"
            ERRORS=$((ERRORS + 1))
            continue
        fi
        
        # Check for duplicates
        duplicate=0
        for existing in "${REQ_IDS[@]+${REQ_IDS[@]}}"; do
            if [ "$existing" = "$req_id" ]; then
                echo -e "    ${RED}❌ Duplicate REQ- ID: $req_id${NC}"
                ERRORS=$((ERRORS + 1))
                duplicate=1
                break
            fi
        done
        
        if [ "$duplicate" -eq 0 ]; then
            REQ_IDS+=("$req_id")
        fi
        
        # Check EARS pattern
        if ! echo "$line" | grep -qEi '(WHEN|IF|WHILE).*\b(THEN\s+)?\w+\s+(SHALL|MAY|MUST|SHOULD)\b|\b\w+\s+(SHALL|MAY|MUST|SHOULD)\b'; then
            echo -e "    ${YELLOW}⚠️  $req_id: Does not use EARS pattern${NC}"
            echo "       Expected: WHEN/IF/WHILE ... THEN ... SHALL/MAY ..."
            echo "       Got:      $line"
            WARNINGS=$((WARNINGS + 1))
        fi
        
    done <<< "$req_section"
    
    echo -e "    ${GREEN}✅ Checked ${#REQ_IDS[@]} requirement(s)${NC}"
done

# Summary
if [ "$ERRORS" -gt 0 ]; then
    echo ""
    echo -e "${RED}❌ EARS validation FAILED with $ERRORS error(s)${NC}"
    echo "   Fix requirements before committing."
    echo "   See: backbone/skills/general/ears-requirements/SKILL.md"
    exit 1
elif [ "$WARNINGS" -gt 0 ]; then
    echo ""
    echo -e "${YELLOW}⚠️  EARS validation passed with $WARNINGS warning(s)${NC}"
    echo "   Consider using EARS patterns for clearer requirements."
    exit 0
else
    echo -e "${GREEN}✅ All requirements use valid EARS syntax${NC}"
    exit 0
fi
