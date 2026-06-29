#!/bin/bash
# scripts/hooks/pre-release-qms.sh — QMS pre-release gate
#
# Blocks release if any critical NCR is still open.
# Warns on major/minor NCRs open > 30 days (aging).
# All critical nonconformances must have a CAPA before release.
#
# Usage:     ./scripts/hooks/pre-release-qms.sh
# Flags:     --strict  (also block on aging major NCRs)
# Exit 0 = allow release
# Exit 1 = block release

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
NCR_DIR="$PROJECT_ROOT/backbone/artifacts/qms/ncr"

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

BLOCK=0
WARN=0
STRICT=false
[[ "${1:-}" == "--strict" ]] && STRICT=true

NOW_EPOCH=$(date +%s)
AGING_DAYS=30
AGING_SECONDS=$((AGING_DAYS * 86400))

if [[ ! -d "$NCR_DIR" ]]; then
    exit 0
fi

echo -e "${YELLOW}🔍 QMS pre-release gates...${NC}"

for f in "$NCR_DIR"/*.yml; do
    [[ -f "$f" ]] || continue
    severity=""; status=""; id=""; title=""; date=""
    while IFS= read -r line; do
        case "$line" in
            severity:*) severity="${line#severity: }" ;;
            status:*) status="${line#status: }" ;;
            id:*) id="${line#id: }" ;;
            title:*) title="${line#title: }" ;;
            date:*) date="${line#date: }" ;;
        esac
    done < "$f"
    severity="${severity//\"/}"; status="${status//\"/}"
    id="${id//\"/}"; title="${title//\"/}"; date="${date//\"/}"

    # Block on open critical NCRs
    if [[ "$severity" == "critical" && "$status" == "open" ]]; then
        echo -e "${RED}❌ BLOCKED: Critical NCR open — $id: $title${NC}"
        echo -e "${RED}   Create a CAPA: ./scripts/qms-capa-create.sh --ncr $id${NC}"
        BLOCK=1
    fi

    # Warn on aging major/minor NCRs (> 30 days open)
    if [[ "$status" == "open" && -n "$date" && "$severity" != "critical" ]]; then
        CREATED_EPOCH=$(date -j -f "%Y-%m-%d" "$date" +%s 2>/dev/null || echo "0")
        if [[ "$CREATED_EPOCH" -gt 0 ]]; then
            AGE=$(( (NOW_EPOCH - CREATED_EPOCH) / 86400 ))
            if [[ "$AGE" -gt "$AGING_DAYS" ]]; then
                echo -e "${YELLOW}⚠️  AGING ($AGE days): $id ($severity) — $title${NC}"
                WARN=1
                if $STRICT && [[ "$severity" == "major" ]]; then
                    echo -e "${RED}   --strict: blocking on aging major NCR${NC}"
                    BLOCK=1
                fi
            fi
        fi
    fi
done

if [[ $WARN -gt 0 ]]; then
    echo -e "${YELLOW}   Aging NCRs found. Review: ./scripts/qms-report.sh --aging${NC}"
fi

if [[ $BLOCK -eq 0 ]]; then
    echo -e "${GREEN}✅ QMS pre-release gates passed${NC}"
fi

exit $BLOCK
