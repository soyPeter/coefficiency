#!/bin/bash
# pre-commit-grill-check.sh: Gate G→P (pre-commit) — Block PRDs without grill evidence
#
# Cross-agent enforcement: works with Claude Code, OpenCode, Cursor, etc.
# When PRD files are staged, verifies they contain grill evidence.
#
# Validation levels:
#   1. grilled: true in frontmatter
#   2. ## Grilling section exists
#   3. All 5 branch headings present
#   4. Each branch has ≥2 Q/A pairs
#
# Override: export SKIP_GRILL_CHECK=1

set -euo pipefail

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [ -z "$PROJECT_ROOT" ]; then
    exit 0
fi

# Skip if override is set
if [ "${SKIP_GRILL_CHECK:-0}" = "1" ]; then
    exit 0
fi

# Get staged PRD or proposal files
STAGED_PRDS=$(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null | grep -E '^backbone/artifacts/changes/.*/proposal\.md$' | grep -v '^backbone/artifacts/changes/archive/' || true)
if [ -z "$STAGED_PRDS" ]; then
    STAGED_PRDS=$(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null | grep -E '^backbone/artifacts/prd/.*\.md$' || true)
fi

if [ -z "$STAGED_PRDS" ]; then
    exit 0
fi

ERRORS=0

while IFS= read -r prd_file; do
    [ -z "$prd_file" ] && continue
    
    FULL_PATH="$PROJECT_ROOT/$prd_file"
    if [ ! -f "$FULL_PATH" ]; then
        continue
    fi
    
    CONTENT=$(cat "$FULL_PATH")
    BASENAME=$(basename "$prd_file")
    
    # Check exempt types in first 20 lines
    HEADER=$(echo "$CONTENT" | head -20)
    if echo "$HEADER" | grep -qiE '(fix|bug|docs|refactor|clean|chore|test|perf|ci|build|style)'; then
        continue
    fi
    
    # ── Validation 1: grilled: true in frontmatter ────────────────────────────
    if ! echo "$CONTENT" | grep -qE '^grilled:\s*true'; then
        echo -e "${YELLOW}❌ GRILL GATE G→P: $BASENAME missing 'grilled: true'${NC}"
        ERRORS=$((ERRORS + 1))
        continue
    fi
    
    # ── Validation 2: ## Grilling section exists ──────────────────────────────
    if ! echo "$CONTENT" | grep -qE '^##\s+Grill(ing|ed| Log)?\s*$'; then
        echo -e "${YELLOW}❌ GRILL GATE G→P: $BASENAME missing '## Grilling' section${NC}"
        ERRORS=$((ERRORS + 1))
        continue
    fi
    
    # ── Validation 3: All 5 branch headings present ───────────────────────────
    missing_branches=""
    if ! echo "$CONTENT" | grep -qE '^###\s+Scope\s*$'; then
        missing_branches="$missing_branches Scope"
    fi
    if ! echo "$CONTENT" | grep -qE '^###\s+Boundaries\s*$'; then
        missing_branches="$missing_branches Boundaries"
    fi
    if ! echo "$CONTENT" | grep -qE '^###\s+Data'; then
        missing_branches="$missing_branches Data"
    fi
    if ! echo "$CONTENT" | grep -qE '^###\s+API\s*$'; then
        missing_branches="$missing_branches API"
    fi
    if ! echo "$CONTENT" | grep -qE '^###\s+Implementation'; then
        missing_branches="$missing_branches Implementation"
    fi
    
    if [ -n "$missing_branches" ]; then
        echo -e "${YELLOW}❌ GRILL GATE G→P: $BASENAME missing branches:$missing_branches${NC}"
        ERRORS=$((ERRORS + 1))
        continue
    fi
    
    # ── Validation 4: Each branch has at least 2 Q/A pairs ────────────────────
    qa_issues=$(python3 -c "
import re
import sys

content = sys.stdin.read()

grill_match = re.search(r'^##\s+Grill(ing|ed| Log)?\s*\$(.*?)(?=^##\s|\Z)', content, re.MULTILINE | re.DOTALL)
if not grill_match:
    print('NO_GRILLING_SECTION')
    sys.exit(0)

grilling = grill_match.group(2)
branches = re.split(r'^###\s+', grilling, flags=re.MULTILINE)
issues = []

for branch in branches[1:]:
    lines = branch.split('\n')
    branch_name = lines[0].strip()
    branch_content = '\n'.join(lines[1:])
    
    q_count = len(re.findall(r'^\s*-\s*\*\*Q:\*\*', branch_content, re.MULTILINE))
    a_count = len(re.findall(r'^\s*-\s*\*\*A:\*\*', branch_content, re.MULTILINE))
    
    if q_count < 2:
        issues.append(f'{branch_name}: only {q_count} Q (need >=2)')
    if a_count < 2:
        issues.append(f'{branch_name}: only {a_count} A (need >=2)')

if issues:
    print('ISSUES:' + '|'.join(issues))
" 2>/dev/null <<< "$CONTENT") || true

    if echo "$qa_issues" | grep -q "^ISSUES:"; then
        echo -e "${YELLOW}❌ GRILL GATE G→P: $BASENAME insufficient Q/A pairs${NC}"
        echo "$qa_issues" | sed 's/^ISSUES://' | tr '|' '\n' | sed 's/^/    - /'
        ERRORS=$((ERRORS + 1))
        continue
    fi
    
done <<< "$STAGED_PRDS"

if [ "$ERRORS" -gt 0 ]; then
    echo ""
    echo "  Before creating a PRD for feature work, you MUST:"
    echo "    1. Use the grill-me skill: view backbone/skills/general/grill-me/SKILL.md"
    echo "    2. Grill the user on all 5 branches"
    echo "    3. Add 'grilled: true' to PRD frontmatter"
    echo "    4. Write a '## Grilling' section with Q/A pairs"
    echo ""
    echo "  Or override: export SKIP_GRILL_CHECK=1"
    echo ""
    exit 1
fi

exit 0
