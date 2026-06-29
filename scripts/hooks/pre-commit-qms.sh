#!/bin/bash
# scripts/hooks/pre-commit-qms.sh — QMS pre-commit gate
#
# Advisory checks (warn but don't block):
#   1. Aging CAPAs past due
#   2. Fix/perf commits without linked NCRs
#
# Called by: pre-commit hook (Gate 10)
# Usage:     ./scripts/hooks/pre-commit-qms.sh

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CAPA_DIR="$PROJECT_ROOT/backbone/artifacts/qms/capa"
NCR_DIR="$PROJECT_ROOT/backbone/artifacts/qms/ncr"
CHANGES_DIR="$PROJECT_ROOT/backbone/changes"

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

TODAY="$(date +%Y-%m-%d)"
WARNINGS=0

# ── Check 1: Aging CAPAs ────────────────────────────────────────────────
if [[ -d "$CAPA_DIR" ]]; then
    for f in "$CAPA_DIR"/*.yml; do
        [[ -f "$f" ]] || continue
        status=""
        due=""
        id=""
        while IFS= read -r line; do
            case "$line" in
                status:*) status="${line#status: }" ;;
                due_date:*) due="${line#due_date: }" ;;
                id:*) id="${line#id: }" ;;
            esac
        done < "$f"
        status="${status//\"/}"
        due="${due//\"/}"
        id="${id//\"/}"

        if [[ "$status" != "closed" && -n "$due" && "$due" < "$TODAY" ]]; then
            if [[ $WARNINGS -eq 0 ]]; then
                echo ""
                echo -e "${YELLOW}╔══════════════════════════════════════════════════════╗${NC}"
                echo -e "${YELLOW}║  QMS Advisory — Aging CAPAs                        ║${NC}"
                echo -e "${YELLOW}╚══════════════════════════════════════════════════════╝${NC}"
            fi
            echo -e "${YELLOW}  ⚠  $id past due ($due)${NC}"
            WARNINGS=$((WARNINGS + 1))
        fi
    done
    if [[ $WARNINGS -gt 0 ]]; then
        echo -e "${YELLOW}  → Run ./scripts/qms-report.sh --aging for details${NC}"
        echo ""
    fi
fi

# ── Check 2: Fix/perf commits without NCR registration ──────────────────
# Detect if this is a fix: or perf: commit
COMMIT_MSG_FILE="${1:-}"
IS_FIX_COMMIT=0
if [ -n "$COMMIT_MSG_FILE" ] && [ -f "$COMMIT_MSG_FILE" ]; then
    COMMIT_MSG=$(head -n 1 "$COMMIT_MSG_FILE")
    if echo "$COMMIT_MSG" | grep -qE '^(fix|perf)(\([a-z0-9_-]+\))?:'; then
        IS_FIX_COMMIT=1
    fi
fi

if [ "$IS_FIX_COMMIT" = 1 ]; then
    # Check if any active change folder has linked NCRs
    FIX_WITHOUT_NCR=0
    if [ -d "$CHANGES_DIR" ]; then
        for change_dir in "$CHANGES_DIR"/CHNG-*/; do
            [ -d "$change_dir" ] && [ "$(basename "$change_dir")" != "archive" ] || continue
            chng_id=""
            cb=$(basename "$change_dir")
            chng_id="${cb%%-*}"
            [ -z "$chng_id" ] && continue

            # Check NCRs linked to this change
            has_ncr=0
            if [ -d "$NCR_DIR" ]; then
                for ncr_file in "$NCR_DIR"/*.yml; do
                    [ -f "$ncr_file" ] || continue
                    ncr_change=""
                    while IFS= read -r line; do
                        [[ "$line" =~ ^change: ]] && ncr_change="${line#change: }" && ncr_change="${ncr_change//\"/}"
                    done < "$ncr_file"
                    [ "$ncr_change" = "$chng_id" ] && has_ncr=1 && break
                done
            fi

            if [ "$has_ncr" = 0 ]; then
                FIX_WITHOUT_NCR=$((FIX_WITHOUT_NCR + 1))
            fi
        done
    fi

    # Also check for any NCRs at all in the project
    TOTAL_NCRS=0
    if [ -d "$NCR_DIR" ]; then
        for ncr_file in "$NCR_DIR"/*.yml; do
            [ -f "$ncr_file" ] && TOTAL_NCRS=$((TOTAL_NCRS + 1))
        done
    fi

    if [ "$TOTAL_NCRS" -eq 0 ]; then
        echo ""
        echo -e "${YELLOW}╔══════════════════════════════════════════════════════╗${NC}"
        echo -e "${YELLOW}║  QMS Advisory — No NCRs Registered                 ║${NC}"
        echo -e "${YELLOW}╚══════════════════════════════════════════════════════╝${NC}"
        echo -e "${YELLOW}  You are committing a fix, but no NCR exists.${NC}"
        echo -e "${YELLOW}  If this fix addresses a defect, register an NCR:${NC}"
        echo -e "${YELLOW}    ./scripts/qms-register-issue.sh \\${NC}"
        echo -e "${YELLOW}      --title \"...\" --severity major --category code --change CHNG-XXX${NC}"
        echo ""
    elif [ "$FIX_WITHOUT_NCR" -gt 0 ]; then
        echo ""
        echo -e "${YELLOW}╔══════════════════════════════════════════════════════╗${NC}"
        echo -e "${YELLOW}║  QMS Advisory — Fix Without Linked NCR              ║${NC}"
        echo -e "${YELLOW}╚══════════════════════════════════════════════════════╝${NC}"
        echo -e "${YELLOW}  $FIX_WITHOUT_NCR active change(s) have no linked NCRs.${NC}"
        echo -e "${YELLOW}  If this fix addresses a defect, register one:${NC}"
        echo -e "${YELLOW}    ./scripts/qms-register-issue.sh --change CHNG-XXX \\${NC}"
        echo -e "${YELLOW}      --title \"...\" --severity major --category code${NC}"
        echo ""
    fi
fi

exit 0
