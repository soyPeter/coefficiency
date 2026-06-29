#!/bin/bash
# scripts/qms-capa-create.sh — Create a Corrective Action from an NCR
#
# Links a CAPA to an existing nonconformance report and records
# root cause analysis, action plan, owner, and due date.
#
# Usage:
#   ./scripts/qms-capa-create.sh --ncr NCR-001 --owner "alice" --due 2026-06-23
#   ./scripts/qms-capa-create.sh --ncr NCR-001 --root-cause "..." --action-plan "..."
#   ./scripts/qms-capa-create.sh --help

set -euo pipefail
if [[ -f "$HOME/.backbone/scripts/lib/bb-root.sh" ]]; then
    source "$HOME/.backbone/scripts/lib/bb-root.sh"
else
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
    BB_ROOT="$PROJECT_ROOT"
fiCAPA_DIR="$PROJECT_ROOT/backbone/artifacts/qms/capa"
NCR_DIR="$PROJECT_ROOT/backbone/artifacts/qms/ncr"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

NCR_ID=""
ROOT_CAUSE=""
ACTION_PLAN=""
OWNER=""
DUE_DATE=""

show_help() {
    cat << 'EOF'
Usage: qms-capa-create.sh [options]

Create a Corrective Action (CAPA) linked to an existing NCR.

Required:
  --ncr NCR_ID       NCR to link this CAPA to (e.g. NCR-001)

Optional:
  --owner NAME       Person responsible (default: dev)
  --due DATE         Due date in YYYY-MM-DD format (default: 30 days from now)
  --root-cause TEXT  Root cause analysis (default: "Auto-generated from NCR")
  --action-plan TEXT Action plan description (default: "To be determined")
  -h, --help         Show this help message

Examples:
  qms-capa-create.sh --ncr NCR-001                                 # auto defaults
  qms-capa-create.sh --ncr NCR-001 --owner "alice" --due 2026-06-23
  qms-capa-create.sh --ncr NCR-001 --owner "bob" --due 2026-07-01 --root-cause "Missing validation layer" --action-plan "Add input sanitization middleware"
EOF
}

next_capa_id() {
    mkdir -p "$CAPA_DIR"
    local max_num=0
    local file
    for file in "$CAPA_DIR"/CAPA-*.yml; do
        if [[ -f "$file" ]]; then
            local basename
            basename="$(basename "$file" .yml)"
            local num="${basename#CAPA-}"
            if [[ "$num" =~ ^[0-9]+$ ]]; then
                if (( 10#$num > max_num )); then
                    max_num=$((10#$num))
                fi
            fi
        fi
    done
    local next_num=$((max_num + 1))
    printf "CAPA-%03d" "$next_num"
}

validate_ncr_exists() {
    local ncr="$1"
    local ncr_file="$NCR_DIR/$ncr.yml"
    if [[ ! -f "$ncr_file" ]]; then
        echo -e "${RED}❌ NCR not found: $ncr.yml${NC}" >&2
        echo -e "${YELLOW}Create it first with: ./scripts/qms-register-issue.sh${NC}" >&2
        exit 1
    fi
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --ncr)
                NCR_ID="$2"
                shift 2
                ;;
            --root-cause)
                ROOT_CAUSE="$2"
                shift 2
                ;;
            --action-plan)
                ACTION_PLAN="$2"
                shift 2
                ;;
            --owner)
                OWNER="$2"
                shift 2
                ;;
            --due)
                DUE_DATE="$2"
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

    if [[ -z "$NCR_ID" ]]; then
        echo -e "${RED}❌ Missing required: --ncr${NC}" >&2
        show_help
        exit 1
    fi
    if [[ -z "$OWNER" ]]; then
        OWNER="dev"
        echo -e "${YELLOW}  ⚠  --owner not provided, defaulting to: dev${NC}"
    fi
    if [[ -z "$DUE_DATE" ]]; then
        # Default to 30 days from now
        DUE_DATE=$(date -v+30d +%Y-%m-%d 2>/dev/null || date -d "+30 days" +%Y-%m-%d 2>/dev/null || echo "$(date +%Y-%m-%d)")
        echo -e "${YELLOW}  ⚠  --due not provided, defaulting to: $DUE_DATE${NC}"
    fi

    if [[ ! "$NCR_ID" =~ ^NCR-[0-9]{3}$ ]]; then
        echo -e "${RED}❌ Invalid NCR ID format: $NCR_ID (expected NCR-XXX)${NC}" >&2
        exit 1
    fi

    if [[ ! "$DUE_DATE" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        echo -e "${RED}❌ Invalid date format: $DUE_DATE (expected YYYY-MM-DD)${NC}" >&2
        exit 1
    fi

    if [[ -z "$ROOT_CAUSE" ]]; then
        ROOT_CAUSE="To be determined"
    fi
    if [[ -z "$ACTION_PLAN" ]]; then
        ACTION_PLAN="To be determined"
    fi
}

main() {
    parse_args "$@"
    validate_ncr_exists "$NCR_ID"

    local capa_id
    capa_id="$(next_capa_id)"
    local date_str
    date_str="$(date +%Y-%m-%d)"
    local file_path="$CAPA_DIR/$capa_id.yml"

    cat > "$file_path" << CAPA_EOF
# Corrective Action — $capa_id
# Created: $date_str
# References: $NCR_ID

id: "$capa_id"
ncr_ref: "$NCR_ID"
date: "$date_str"
owner: "$OWNER"
due_date: "$DUE_DATE"
root_cause: "$ROOT_CAUSE"
action_plan: "$ACTION_PLAN"
status: open
verification: ""
CAPA_EOF

    echo -e "${GREEN}✅ Created: $file_path${NC}"
    echo -e "${CYAN}  ID:         $capa_id${NC}"
    echo -e "${CYAN}  NCR Ref:    $NCR_ID${NC}"
    echo -e "${CYAN}  Owner:      $OWNER${NC}"
    echo -e "${CYAN}  Due:        $DUE_DATE${NC}"
    echo -e "${CYAN}  Root Cause: $ROOT_CAUSE${NC}"
    echo -e "${CYAN}  Action:     $ACTION_PLAN${NC}"
    echo -e "${YELLOW}  Status:     open${NC}"
    echo ""
    echo -e "${YELLOW}When action is complete, close with:${NC}"
    echo -e "${YELLOW}  ./scripts/qms-capa-close.sh --capa $capa_id --verification \"...\"${NC}"
}

main "$@"
