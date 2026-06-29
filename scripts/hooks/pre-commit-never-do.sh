#!/bin/bash
# pre-commit-never-do.sh: NEVER DO list enforcement (advisory)
#
# Checks staged files against the NEVER DO list from backbone/4-KNOWLEDGE.md:
#   1. Non-English identifiers in code files
#   2. `cd` without save/restore in scripts
#   3. Missing `set -e` in scripts
#
# Advisory only — warns but does not block.
# Override: export SKIP_NEVER_DO_CHECK=1

set -euo pipefail

RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

if [ "${SKIP_NEVER_DO_CHECK:-0}" = "1" ]; then
    exit 0
fi

STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null || true)
[ -z "$STAGED_FILES" ] && exit 0

WARNINGS=0

# ── Check 1: Non-English identifiers in code files ──────────────────────────
# Scans staged code files for non-ASCII characters outside of string literals
# and comments. Uses grep to find lines containing non-ASCII characters.
CODE_EXTENSIONS='\.(java|kt|go|py|js|ts|tsx|rb|php|c|cpp|h|hpp|rs)$'
NON_ENGLISH_FILES=""

while IFS= read -r file; do
    [ -z "$file" ] && continue
    if echo "$file" | grep -qE "$CODE_EXTENSIONS"; then
        full="$PROJECT_ROOT/$file"
        [ -f "$full" ] || continue
        # Look for lines with non-ASCII characters (heuristic: characters above U+007F)
        if grep -Pn '[^\x00-\x7F]' "$full" 2>/dev/null | head -5 | grep -qv '^\d+:\s*//\|^\d+:\s*\*\|^\d+:\s*"'; then
            NON_ENGLISH_FILES="$NON_ENGLISH_FILES\n  - $file"
            WARNINGS=$((WARNINGS + 1))
        fi
    fi
done <<< "$STAGED_FILES"

if [ -n "$NON_ENGLISH_FILES" ]; then
    echo ""
    echo -e "${YELLOW}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║  NEVER DO: Non-English identifiers detected         ║${NC}"
    echo -e "${YELLOW}╚══════════════════════════════════════════════════════╝${NC}"
    echo -e "$NON_ENGLISH_FILES"
    echo -e "${YELLOW}  → 4-KNOWLEDGE.md: Never use non-English in identifiers${NC}"
    echo ""
fi

# ── Check 2: cd without save/restore in scripts ────────────────────────────
# Scans staged .sh files for bare `cd` commands not paired with pushd/popd
# or saved/restored OLDPWD pattern.
CD_ISSUES=""

while IFS= read -r file; do
    [ -z "$file" ] && continue
    if echo "$file" | grep -qE '\.sh$'; then
        full="$PROJECT_ROOT/$file"
        [ -f "$full" ] || continue
        # Count cd commands vs pushd/popd pairs and OLDPWD restores
        cd_count=$(grep -cE '^\s*cd\s+' "$full" 2>/dev/null || true)
        pushd_count=$(grep -c 'pushd' "$full" 2>/dev/null || true)
        popd_count=$(grep -c 'popd' "$full" 2>/dev/null || true)
        oldpwd_count=$(grep -c 'OLDPWD' "$full" 2>/dev/null || true)
        safe_ops=$((pushd_count + popd_count + oldpwd_count))
        if [ "$cd_count" -gt 0 ] && [ "$cd_count" -gt "$safe_ops" ]; then
            CD_ISSUES="$CD_ISSUES\n  - $file ($cd_count cd, $safe_ops safe ops)"
            WARNINGS=$((WARNINGS + 1))
        fi
    fi
done <<< "$STAGED_FILES"

if [ -n "$CD_ISSUES" ]; then
    echo ""
    echo -e "${YELLOW}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║  NEVER DO: cd without save/restore in scripts      ║${NC}"
    echo -e "${YELLOW}╚══════════════════════════════════════════════════════╝${NC}"
    echo -e "$CD_ISSUES"
    echo -e "${YELLOW}  → Use pushd/popd or cd \"$OLDPWD\" to restore pwd${NC}"
    echo ""
fi

# ── Check 3: Missing set -e in new/modified scripts ────────────────────────
# Scans staged .sh files for missing error handling preamble.
SETE_ISSUES=""

while IFS= read -r file; do
    [ -z "$file" ] && continue
    if echo "$file" | grep -qE '\.sh$'; then
        full="$PROJECT_ROOT/$file"
        [ -f "$full" ] || continue
        # Check if file has any form of set -e or set -o errexit
        first_line=$(head -1 "$full" 2>/dev/null || true)
        # Only check scripts that start with #!/bin/bash or #!/bin/sh
        if echo "$first_line" | grep -qE '^#!/bin/(bash|sh)'; then
            if ! grep -qE '^\s*set\s+(-[a-z]*e[a-z]*|-o\s+errexit)' "$full" 2>/dev/null; then
                SETE_ISSUES="$SETE_ISSUES\n  - $file"
                WARNINGS=$((WARNINGS + 1))
            fi
        fi
    fi
done <<< "$STAGED_FILES"

if [ -n "$SETE_ISSUES" ]; then
    echo ""
    echo -e "${YELLOW}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║  NEVER DO: Missing set -e in scripts               ║${NC}"
    echo -e "${YELLOW}╚══════════════════════════════════════════════════════╝${NC}"
    echo -e "$SETE_ISSUES"
    echo -e "${YELLOW}  → Add set -e (or set -euo pipefail) for error handling${NC}"
    echo ""
fi

exit 0
