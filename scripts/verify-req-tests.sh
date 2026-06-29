#!/bin/bash
# verify-req-tests.sh — Verify REQ-IDs from a change proposal have test coverage
#
# Usage:
#   ./scripts/verify-req-tests.sh CHNG-XXX
#   ./scripts/verify-req-tests.sh --project-dir /path CHNG-XXX
#   ./scripts/verify-req-tests.sh --run-tests CHNG-XXX
#   ./scripts/verify-req-tests.sh --dry-run CHNG-XXX
#
# Exit codes:
#   0  All REQ-IDs covered (and tests pass if --run-tests)
#   1  Coverage gaps found (advisory, non-blocking)
#   2  Test failures detected (blocking, only with --run-tests)

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;36m'
NC='\033[0m'

PROJECT_DIR=""
RUN_TESTS=0
DRY_RUN=0
CHNG_ID=""

# Parse arguments
while [ $# -gt 0 ]; do
    case "$1" in
        --project-dir)
            PROJECT_DIR="$2"
            shift 2
            ;;
        --run-tests)
            RUN_TESTS=1
            shift
            ;;
        --dry-run)
            DRY_RUN=1
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [options] CHNG-XXX"
            echo ""
            echo "Verify each REQ-ID in the proposal has test coverage."
            echo ""
            echo "Arguments:"
            echo "  CHNG-XXX              Change ID (required)"
            echo ""
            echo "Options:"
            echo "  --project-dir PATH    Project directory (auto-detect from cwd)"
            echo "  --run-tests           Also execute test suites"
            echo "  --dry-run             Show what would be done without writing"
            echo "  -h, --help            Show this help"
            echo ""
            echo "Exit codes:"
            echo "  0  All REQ-IDs covered (and tests pass if --run-tests)"
            echo "  1  Coverage gaps found (advisory)"
            echo "  2  Test failures detected (blocking, only with --run-tests)"
            exit 0
            ;;
        *)
            if [ -z "$CHNG_ID" ]; then
                CHNG_ID="$1"
            else
                echo "Unknown argument: $1"
                exit 1
            fi
            shift
            ;;
    esac
done

if [ -z "$CHNG_ID" ]; then
    echo "Usage: $0 [options] CHNG-XXX"
    exit 1
fi

# Auto-detect project dir
if [ -z "$PROJECT_DIR" ]; then
    PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
fi

# Resolve change folder
CHANGE_FOLDER=$(find "$PROJECT_DIR/backbone/artifacts/changes" -maxdepth 1 -type d -name "${CHNG_ID}-*" 2>/dev/null | head -1)
if [ -z "$CHANGE_FOLDER" ]; then
    CHANGE_FOLDER=$(find "$PROJECT_DIR/backbone/artifacts/changes/archive" -maxdepth 1 -type d -name "${CHNG_ID}-*" 2>/dev/null | head -1)
fi

if [ -z "$CHANGE_FOLDER" ]; then
    echo -e "${RED}❌ Change folder not found for $CHNG_ID${NC}"
    exit 1
fi

PROPOSAL="$CHANGE_FOLDER/proposal.md"
if [ ! -f "$PROPOSAL" ]; then
    echo -e "${RED}❌ proposal.md not found in $CHANGE_FOLDER${NC}"
    exit 1
fi

# Detect change type — exempt fix/docs/refactor/chore/test
CHANGE_TYPE=""
if grep -qiE "fix|docs|refactor|chore|test" <<< "$(basename "$CHANGE_FOLDER")" 2>/dev/null; then
    CHANGE_TYPE="exempt"
fi

echo -e "${BLUE}=== Verifying REQ-ID test coverage for $CHNG_ID ===${NC}"
echo "  Change folder: $CHANGE_FOLDER"

if [ "$CHANGE_TYPE" = "exempt" ]; then
    echo -e "  ${YELLOW}⚠️  Change type is fix/docs/refactor/chore/test — skipping verification${NC}"
    exit 0
fi

# Extract REQ-IDs from proposal
REQ_IDS=$(grep -oE 'REQ-[A-Z]+-[0-9]+' "$PROPOSAL" | sort -u || true)

if [ -z "$REQ_IDS" ]; then
    echo -e "  ${YELLOW}⚠️  No REQ-IDs found in proposal${NC}"
    exit 0
fi

REQ_COUNT=$(echo "$REQ_IDS" | wc -l | tr -d ' ')
echo "  Found $REQ_COUNT REQ-ID(s) in proposal"

# Dry run
if [ "$DRY_RUN" = "1" ]; then
    echo ""
    echo -e "${BLUE}--- DRY RUN: Coverage Scan Preview ---${NC}"
    while IFS= read -r req; do
        [ -z "$req" ] && continue
        echo "  $req → search test files..."
    done <<< "$REQ_IDS"
    if [ "$RUN_TESTS" = "1" ]; then
        echo "  --run-tests would execute: bats, pytest, vitest"
    fi
    echo ""
    echo -e "${GREEN}✅ Dry run complete — no files written${NC}"
    exit 0
fi

# Search test directories for each REQ-ID
TEST_DIRS=("$PROJECT_DIR/tests" "$PROJECT_DIR/tests/python" "$PROJECT_DIR/dev-portal/src/lib/__tests__")

COVERED=0
MISSING=0
declare -a COVERAGE_ROWS

while IFS= read -r req; do
    [ -z "$req" ] && continue
    found=""
    for test_dir in "${TEST_DIRS[@]}"; do
        if [ -d "$test_dir" ]; then
            match=$(grep -rl "$req" "$test_dir" 2>/dev/null | head -3 || true)
            if [ -n "$match" ]; then
                locations=$(echo "$match" | while read -r f; do
                    linenum=$(grep -n "$req" "$f" 2>/dev/null | head -1 | cut -d: -f1 || echo "1")
                    echo "$f:$linenum"
                done | tr '\n' ', ' | sed 's/, $//')
                found="$locations"
                break
            fi
        fi
    done
    if [ -n "$found" ]; then
        COVERED=$((COVERED + 1))
        COVERAGE_ROWS+=("$req|✅ COVERED|$found")
    else
        MISSING=$((MISSING + 1))
        COVERAGE_ROWS+=("$req|⚠️  MISSING|—")
    fi
done <<< "$REQ_IDS"

TOTAL=$((COVERED + MISSING))

# Print coverage table
echo ""
echo -e "${BLUE}Coverage Table:${NC}"
printf "  %-20s %-14s %s\n" "REQ-ID" "Status" "Location"
printf "  %-20s %-14s %s\n" "------" "------" "--------"
for row in "${COVERAGE_ROWS[@]}"; do
    IFS='|' read -r id status location <<< "$row"
    if [ "$status" = "✅ COVERED" ]; then
        printf "  ${GREEN}%-20s %-14s${NC} %s\n" "$id" "$status" "$location"
    else
        printf "  ${YELLOW}%-20s %-14s${NC} %s\n" "$id" "$status" "$location"
    fi
done
echo ""
echo -e "  Summary: $GREEN_COLOR$COVERED/$TOTAL covered${NC}"

# Write report
REPORT_DIR="$PROJECT_DIR/backbone/artifacts/reports"
mkdir -p "$REPORT_DIR"
REPORT_FILE="$REPORT_DIR/${CHNG_ID}-verify-$(date +%Y-%m-%d).md"

{
    echo "# Verification Report: $CHNG_ID"
    echo "**Date:** $(date +%Y-%m-%d)"
    echo "**Mode:** ${RUN_TESTS:+test-run}${RUN_TESTS:-scan}"
    echo ""
    echo "## Coverage Summary"
    echo "- Total REQ-IDs: $TOTAL"
    echo "- Covered: $COVERED"
    echo "- Missing: $MISSING"
    if [ "$TOTAL" -gt 0 ]; then
        PASS_PCT=$((COVERED * 100 / TOTAL))
        echo "- Pass rate: ${PASS_PCT}%"
    fi
    echo ""
    echo "## Coverage Details"
    echo "| REQ-ID | Status | Location |"
    echo "|--------|--------|----------|"
    for row in "${COVERAGE_ROWS[@]}"; do
        IFS='|' read -r id status location <<< "$row"
        echo "| $id | $status | $location |"
    done
    if [ "$MISSING" -gt 0 ]; then
        echo ""
        echo "## Missing Requirements"
        for row in "${COVERAGE_ROWS[@]}"; do
            IFS='|' read -r id status location <<< "$row"
            if [ "$status" = "⚠️  MISSING" ]; then
                echo "- $id: Add tests before archiving"
            fi
        done
    fi
} > "$REPORT_FILE"

echo -e "  ${GREEN}✓ Report: $REPORT_FILE${NC}"

# Run tests if requested
TEST_FAILURES=0
if [ "$RUN_TESTS" = "1" ]; then
    echo ""
    echo -e "${BLUE}--- Running test suites ---${NC}"

    if [ -f "$PROJECT_DIR/package.json" ]; then
        echo -n "  bats tests... "
        if bats "$PROJECT_DIR/tests" 2>/dev/null; then
            echo -e "${GREEN}PASS${NC}"
        else
            echo -e "${RED}FAIL${NC}"
            TEST_FAILURES=$((TEST_FAILURES + 1))
        fi
    fi

    if [ -d "$PROJECT_DIR/tests/python" ]; then
        echo -n "  pytest... "
        if (cd "$PROJECT_DIR" && pytest tests/python/ -q 2>/dev/null); then
            echo -e "${GREEN}PASS${NC}"
        else
            echo -e "${RED}FAIL${NC}"
            TEST_FAILURES=$((TEST_FAILURES + 1))
        fi
    fi

    if [ -d "$PROJECT_DIR/dev-portal" ]; then
        echo -n "  vitest (dev-portal)... "
        if (cd "$PROJECT_DIR/dev-portal" && npx vitest run --reporter=dot 2>/dev/null); then
            echo -e "${GREEN}PASS${NC}"
        else
            echo -e "${RED}FAIL${NC}"
            TEST_FAILURES=$((TEST_FAILURES + 1))
        fi
    fi
fi

echo ""
if [ "$MISSING" -gt 0 ]; then
    echo -e "${YELLOW}⚠️  $MISSING REQ-ID(s) lack test coverage — add tests or use fix/docs/refactor type${NC}"
fi
if [ "$TEST_FAILURES" -gt 0 ]; then
    echo -e "${RED}❌ $TEST_FAILURES test suite(s) failed — blocking close${NC}"
    exit 2
fi
if [ "$MISSING" -gt 0 ]; then
    exit 1
fi
echo -e "${GREEN}✅ All $COVERED REQ-ID(s) have test coverage${NC}"
exit 0
