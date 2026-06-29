#!/bin/bash
# scripts/qms-capa-close.sh — Close a CAPA with verification of effectiveness
#
# Records how the corrective action was verified and transitions
# the CAPA status from open/in-progress to verified → closed.
#
# Usage:
#   ./scripts/qms-capa-close.sh --capa CAPA-001 --verification "..."
#   ./scripts/qms-capa-close.sh --capa CAPA-001 --status verified
#   ./scripts/qms-capa-close.sh --help

set -euo pipefail
if [[ -f "$HOME/.backbone/scripts/lib/bb-root.sh" ]]; then
    source "$HOME/.backbone/scripts/lib/bb-root.sh"
else
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
    BB_ROOT="$PROJECT_ROOT"
fi
CAPA_DIR="$PROJECT_ROOT/backbone/artifacts/qms/capa"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

CAPA_ID=""
VERIFICATION=""
NEW_STATUS=""
VALID_STATUSES=("verified" "closed")

show_help() {
    cat << 'EOF'
Usage: qms-capa-close.sh [options]

Close or verify a Corrective Action (CAPA).

Required:
  --capa CAPA_ID         CAPA to close (e.g. CAPA-001)
  --verification TEXT    Description of verification performed

Optional:
  --status STATUS        Target status: verified or closed (default: closed)
  -h, --help             Show this help message

Status lifecycle:
  open → in-progress → verified → closed

Examples:
  qms-capa-close.sh --capa CAPA-001 --verification "Input sanitization deployed and tested in staging"
  qms-capa-close.sh --capa CAPA-001 --status verified --verification "Fix reviewed and approved"
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --capa)
                CAPA_ID="$2"
                shift 2
                ;;
            --verification)
                VERIFICATION="$2"
                shift 2
                ;;
            --status)
                NEW_STATUS="$2"
                shift 2
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            -*)
                echo -e "${RED}❌ Unknown option: $1${NC}" >&2
                show_help
                exit 1
                ;;
            *)
                echo -e "${RED}❌ Unexpected argument: $1${NC}" >&2
                show_help
                exit 1
                ;;
        esac
    done

    if [[ -z "$CAPA_ID" ]]; then
        echo -e "${RED}❌ Missing required: --capa${NC}" >&2
        show_help
        exit 1
    fi
    if [[ -z "$VERIFICATION" ]]; then
        echo -e "${RED}❌ Missing required: --verification${NC}" >&2
        show_help
        exit 1
    fi

    if [[ ! "$CAPA_ID" =~ ^CAPA-[0-9]{3}$ ]]; then
        echo -e "${RED}❌ Invalid CAPA ID format: $CAPA_ID (expected CAPA-XXX)${NC}" >&2
        exit 1
    fi

    if [[ -z "$NEW_STATUS" ]]; then
        NEW_STATUS="closed"
    fi

    local valid=false
    for s in "${VALID_STATUSES[@]}"; do
        if [[ "$s" == "$NEW_STATUS" ]]; then
            valid=true
            break
        fi
    done
    if [[ "$valid" == false ]]; then
        echo -e "${RED}❌ Invalid status: $NEW_STATUS (expected: verified or closed)${NC}" >&2
        exit 1
    fi
}

main() {
    parse_args "$@"

    local file_path="$CAPA_DIR/$CAPA_ID.yml"
    if [[ ! -f "$file_path" ]]; then
        echo -e "${RED}❌ CAPA not found: $CAPA_ID.yml${NC}" >&2
        echo -e "${YELLOW}Available CAPAs:${NC}" >&2
        ls -1 "$CAPA_DIR"/*.yml 2>/dev/null | sed 's/.*\///' | sed 's/\.yml$//' >&2 || echo "  (none)" >&2
        exit 1
    fi

    local old_status
    old_status="$(grep '^status:' "$file_path" | sed 's/^status: *//')"

    if [[ "$old_status" == "closed" ]]; then
        echo -e "${YELLOW}⚠️  CAPA $CAPA_ID is already closed${NC}"
        exit 0
    fi

    local close_date
    close_date="$(date +%Y-%m-%d)"

    case "$NEW_STATUS" in
        verified)
            if [[ "$old_status" == "closed" ]]; then
                echo -e "${YELLOW}⚠️  Cannot verify a closed CAPA${NC}"
                exit 1
            fi
            ;;
        closed)
            if [[ "$old_status" == "open" ]]; then
                echo -e "${YELLOW}ℹ️  Skipping 'verified' → closing directly${NC}"
            fi
            ;;
    esac

    if [[ "$(uname)" == "Darwin" ]]; then
        sed -i '' "s/^status:.*/status: $NEW_STATUS/" "$file_path"
        sed -i '' "s/^verification:.*/verification: \"$VERIFICATION\"/" "$file_path"
    else
        sed -i "s/^status:.*/status: $NEW_STATUS/" "$file_path"
        sed -i "s/^verification:.*/verification: \"$VERIFICATION\"/" "$file_path"
    fi

    echo -e "${GREEN}✅ $CAPA_ID → $NEW_STATUS${NC}"
    echo -e "${CYAN}  Verification: $VERIFICATION${NC}"
    echo -e "${CYAN}  Closed on:    $close_date${NC}"
}

main "$@"
