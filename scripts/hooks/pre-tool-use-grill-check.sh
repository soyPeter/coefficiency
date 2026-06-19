#!/bin/bash
# pre-tool-use-grill-check.sh: Gate G→P — Block PRDs without grill evidence
#
# Fires BEFORE Write/Edit to backbone/artifacts/prd/*.md
# Checks that the PRD includes:
#   1. `grilled: true` in frontmatter
#   2. A `## Grilling` section with all 5 branches covered
#   3. Each branch has at least 2 Q/A pairs
#
# The /grill-me skill must be used before creating PRDs for non-trivial features.
# After grilling, write the Q/A pairs into a `## Grilling` section in the PRD.
#
# Override: export CLAUDE_CODE_SKIP_GRILL=1

set -euo pipefail

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"

# Skip if override is set
if [ "${CLAUDE_CODE_SKIP_GRILL:-0}" = "1" ]; then
    exit 0
fi

# ---- Light mode bypass ----
if [ -f "backbone/.MODE" ]; then
    MODE=$(tr -d '[:space:]' < "backbone/.MODE" 2>/dev/null || echo "standard")
    [ "$MODE" = "light" ] && echo "  🟢 LIGHT MODE: Advisory only — grill check skipped." && exit 0
fi

# Read stdin JSON from Claude Code
INPUT=$(cat)
[ -z "$INPUT" ] && exit 0

# Parse tool and file path
TOOL=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_name',''))" 2>/dev/null || true)
TARGET_FILE=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))" 2>/dev/null || true)

# Only check Write/Edit to PRD files
if [[ "$TOOL" != "Write" && "$TOOL" != "Edit" ]]; then
    exit 0
fi

# Only check backbone/artifacts/prd/ or backbone/artifacts/changes/.../proposal.md files
if [[ "$TARGET_FILE" != *"backbone/artifacts/prd/"* ]] && [[ "$TARGET_FILE" != *"backbone/artifacts/changes/"*"/proposal.md" ]]; then
    exit 0
fi

# Extract content being written
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

# Check if this is a fix/docs/refactor PRD (exempt from grilling)
# Look for exempt keywords in the first 20 lines
HEADER=$(echo "$CONTENT" | head -20)
if echo "$HEADER" | grep -qiE '(fix|bug|docs|refactor|clean|chore|test|perf|ci|build|style)'; then
    # Likely exempt task type — allow without grill evidence
    exit 0
fi

# ── Validation 1: grilled: true in frontmatter ──────────────────────────────
if ! echo "$CONTENT" | grep -qE '^grilled:\s*true'; then
    echo ""
    echo -e "${YELLOW}⚠️  GRILL GATE G→P NOT SATISFIED${NC}"
    echo ""
    echo "  proposal.md / PRD missing grill evidence: $(basename "$TARGET_FILE")"
    echo ""
    echo "  Missing: 'grilled: true' in frontmatter."
    echo ""
    echo "  For feature work, use the DESIGN-FEATURE command:"
    echo "    /backbone:design-feature <name>"
    echo ""
    echo "  This will orchestrate: grill → EARS reqs → proposal → architecture →"
    echo "  design doc → traceability → tasks"
    echo ""
    echo "  Or override: export CLAUDE_CODE_SKIP_GRILL=1"
    echo ""
    exit 1
fi

# ── Validation 2: ## Grilling section exists ────────────────────────────────
if ! echo "$CONTENT" | grep -qE '^##\s+Grill(ing|ed| Log)?\s*$'; then
    echo ""
    echo -e "${YELLOW}⚠️  GRILL GATE G→P NOT SATISFIED${NC}"
    echo ""
    echo "  proposal.md missing grilling section: $(basename "$TARGET_FILE")"
    echo ""
    echo "  Missing: '## Grilling' section with Q/A pairs."
    echo ""
    echo "  For feature work, use the DESIGN-FEATURE command:"
    echo "    /backbone:design-feature <name>"
    echo ""
    echo "  It handles all 5 branches (Scope, Boundaries, Data, API, Implementation)"
    echo "  and creates the complete grilling section automatically."
    echo ""
    echo "  Or override: export CLAUDE_CODE_SKIP_GRILL=1"
    echo ""
    exit 1
fi

# ── Validation 3: All 5 branch headings present ─────────────────────────────
missing_branches=""

if ! echo "$CONTENT" | grep -qE '^###\s+Scope\s*$'; then
    missing_branches="${missing_branches}\n    - ### Scope"
fi
if ! echo "$CONTENT" | grep -qE '^###\s+Boundaries\s*$'; then
    missing_branches="${missing_branches}\n    - ### Boundaries"
fi
if ! echo "$CONTENT" | grep -qE '^###\s+Data'; then
    missing_branches="${missing_branches}\n    - ### Data & State"
fi
if ! echo "$CONTENT" | grep -qE '^###\s+API\s*$'; then
    missing_branches="${missing_branches}\n    - ### API"
fi
if ! echo "$CONTENT" | grep -qE '^###\s+Implementation'; then
    missing_branches="${missing_branches}\n    - ### Implementation Order"
fi

if [ -n "$missing_branches" ]; then
    echo ""
    echo -e "${YELLOW}⚠️  GRILL GATE G→P NOT SATISFIED${NC}"
    echo ""
    echo "  proposal.md grilling section incomplete: $(basename "$TARGET_FILE")"
    echo ""
    echo "  Missing branches in '## Grilling':"
    echo -e "$missing_branches"
    echo ""
    echo "  ALL 5 branches MUST be present with at least 2 Q/A pairs each:"
    echo "    - ### Scope"
    echo "    - ### Boundaries"
    echo "    - ### Data & State"
    echo "    - ### API"
    echo "    - ### Implementation Order"
    echo ""
    echo "  Or override: export CLAUDE_CODE_SKIP_GRILL=1"
    echo ""
    exit 1
fi

# ── Validation 4: Each branch has at least 2 Q/A pairs ──────────────────────
# Extract the grilling section and count Q/A pairs per branch
qa_issues=$(python3 -c "
import re
import sys

content = sys.stdin.read()

# Find the grilling section
grill_match = re.search(r'^##\s+Grill(ing|ed| Log)?\s*\$(.*?)(?=^##\s|\Z)', content, re.MULTILINE | re.DOTALL)
if not grill_match:
    print('NO_GRILLING_SECTION')
    sys.exit(0)

grilling = grill_match.group(2)

# Split by ### headings
branches = re.split(r'^###\s+', grilling, flags=re.MULTILINE)
issues = []

for branch in branches[1:]:  # Skip content before first ###
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
    echo ""
    echo -e "${YELLOW}⚠️  GRILL GATE G→P NOT SATISFIED${NC}"
    echo ""
    echo "  proposal.md grilling section has insufficient Q/A pairs: $(basename "$TARGET_FILE")"
    echo ""
    echo "  Each branch MUST have at least 2 Q/A pairs (4 lines minimum)."
    echo ""
    echo "  Issues found:"
    echo "$qa_issues" | sed 's/^ISSUES://' | tr '|' '\n' | sed 's/^/    - /'
    echo ""
    echo "  Example format:"
    echo "    ### Scope"
    echo "    - **Q:** What exactly should this feature do?"
    echo "    - **A:** [specific answer]"
    echo "    - **Q:** What should it NOT do?"
    echo "    - **A:** [specific answer]"
    echo ""
    echo "  Or override: export CLAUDE_CODE_SKIP_GRILL=1"
    echo ""
    exit 1
fi

exit 0
