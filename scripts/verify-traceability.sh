#!/bin/bash
# verify-traceability.sh: Validate traceability matrix completeness
#
# Usage:
#   ./scripts/verify-traceability.sh                    # Check all features
#   ./scripts/verify-traceability.sh <file.yml>         # Check specific feature
#
# NOTE: Uses only standard bash/python3 tools (no pyyaml dependency)

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

TRACE_DIR="${1:-storage/traceability}"
ERRORS=0
WARNINGS=0

# If argument is a single file
if [ -f "$TRACE_DIR" ]; then
    FILES=("$TRACE_DIR")
else
    FILES=($TRACE_DIR/*.yml)
fi

echo "🔍 Verifying traceability matrices..."
echo ""

# Collect all requirement IDs for uniqueness check
ALL_REQS=""

for file in "${FILES[@]}"; do
    [ -f "$file" ] || continue
    
    filename=$(basename "$file")
    echo "Checking $filename..."
    
    # Check basic YAML structure using embedded python (no pyyaml)
    if ! python3 -c "
import sys
content = open('$file').read()
# Basic structure checks
if 'feature:' not in content:
    print('MISSING_FEATURE')
    sys.exit(1)
if 'requirements:' not in content:
    print('MISSING_REQUIREMENTS')
    sys.exit(1)
# Check for REQ- IDs
import re
reqs = re.findall(r'^\s+(REQ-[A-Z]+-\d+):', content, re.MULTILINE)
if not reqs:
    print('NO_REQ_IDS')
    sys.exit(1)
print('VALID')
" 2>/dev/null; then
        echo -e "  ${RED}❌ Invalid traceability format${NC}"
        ERRORS=$((ERRORS + 1))
        continue
    fi
    
    # Extract requirement IDs using grep
    reqs=$(grep -E '^\s+REQ-[A-Z]+-[0-9]+:' "$file" | sed 's/://g' | awk '{print $1}')
    
    # Check for duplicates across all files
    while IFS= read -r req; do
        [ -z "$req" ] && continue
        if echo "$ALL_REQS" | grep -q "^$req$"; then
            echo -e "  ${RED}❌ Duplicate requirement ID: $req${NC}"
            ERRORS=$((ERRORS + 1))
        fi
        ALL_REQS="$ALL_REQS
$req"
    done <<< "$reqs"
    
    # Check each requirement has code and tests sections
    while IFS= read -r req; do
        [ -z "$req" ] && continue
        
        # Extract the requirement block (from REQ-XXX: to next REQ- or end of file)
        req_block=$(python3 -c "
import sys, re
content = open('$file').read()
# Find block for this requirement
pattern = r'$req:\s*(.*?)(?=\n\s+REQ-|\Z)'
match = re.search(pattern, content, re.DOTALL)
if match:
    print(match.group(1))
" 2>/dev/null || true)
        
        if [ -z "$req_block" ]; then
            echo -e "  ${RED}❌ $req: Could not extract requirement block${NC}"
            ERRORS=$((ERRORS + 1))
            continue
        fi
        
        # Check for code: section with actual entries
        code_section=$(echo "$req_block" | grep -A 20 '^\s*code:' || true)
        if [ -z "$code_section" ]; then
            echo -e "  ${YELLOW}⚠️  $req: No code references${NC}"
            WARNINGS=$((WARNINGS + 1))
        elif ! echo "$code_section" | grep -qE '^\s*-|\[.*\]'; then
            echo -e "  ${YELLOW}⚠️  $req: No code references${NC}"
            WARNINGS=$((WARNINGS + 1))
        fi
        
        # Check for tests: section with actual entries
        tests_section=$(echo "$req_block" | grep -A 20 '^\s*tests:' || true)
        if [ -z "$tests_section" ]; then
            echo -e "  ${YELLOW}⚠️  $req: No test references${NC}"
            WARNINGS=$((WARNINGS + 1))
        elif ! echo "$tests_section" | grep -qE '^\s*-|\[.*\]'; then
            echo -e "  ${YELLOW}⚠️  $req: No test references${NC}"
            WARNINGS=$((WARNINGS + 1))
        fi
        
        # Check file existence for code references
        code_files=$(echo "$req_block" | grep -A 20 '^\s*code:' | grep '^\s*-' | sed 's/^\s*-\s*["'"'"']*//;s/["'"'"']*$//;s/:.*//' | grep -v '^$' || true)
        while IFS= read -r code_file; do
            [ -z "$code_file" ] && continue
            if [ ! -f "$code_file" ]; then
                echo -e "  ${YELLOW}⚠️  $req: Code file not found: $code_file${NC}"
                WARNINGS=$((WARNINGS + 1))
            fi
        done <<< "$code_files"
        
        # Check file existence for test references
        test_files=$(echo "$req_block" | grep -A 20 '^\s*tests:' | grep '^\s*-' | sed 's/^\s*-\s*["'"'"']*//;s/["'"'"']*$//;s/:.*//' | grep -v '^$' || true)
        while IFS= read -r test_file; do
            [ -z "$test_file" ] && continue
            if [ ! -f "$test_file" ]; then
                echo -e "  ${YELLOW}⚠️  $req: Test file not found: $test_file${NC}"
                WARNINGS=$((WARNINGS + 1))
            fi
        done <<< "$test_files"
    done <<< "$reqs"
    
    echo -e "  ${GREEN}✅ $filename checked${NC}"
    echo ""
done

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ "$ERRORS" -gt 0 ]; then
    echo -e "${RED}❌ FAILED: $ERRORS error(s) found${NC}"
    exit 1
elif [ "$WARNINGS" -gt 0 ]; then
    echo -e "${YELLOW}⚠️  PASSED with $WARNINGS warning(s)${NC}"
    exit 0
else
    echo -e "${GREEN}✅ All traceability matrices valid${NC}"
    exit 0
fi
