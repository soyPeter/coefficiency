#!/bin/bash
# scripts/qms-register-issue.sh — Register a nonconformance report (NCR)
#
# Creates a YAML file in backbone/artifacts/qms/ncr/ with ISO 9001-inspired
# nonconformance tracking fields.
#
# Usage:
#   ./scripts/qms-register-issue.sh --title "..." --severity major --category code
#   ./scripts/qms-register-issue.sh --title "..." --description "..." --source review
#   ./scripts/qms-register-issue.sh --help
#
# Severity: critical, major, minor, observation
# Category: process, documentation, code, configuration, performance, security, other
# Source:   review, test, incident, audit, user, other

set -euo pipefail
if [[ -f "$HOME/.backbone/scripts/lib/bb-root.sh" ]]; then
    source "$HOME/.backbone/scripts/lib/bb-root.sh"
else
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
    BB_ROOT="$PROJECT_ROOT"
fiNCR_DIR="$PROJECT_ROOT/backbone/artifacts/qms/ncr"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

TITLE=""
SEVERITY=""
CATEGORY=""
SOURCE=""
DESCRIPTION=""
CHANGE_ID=""

VALID_SEVERITIES=("critical" "major" "minor" "observation")
VALID_CATEGORIES=("process" "documentation" "code" "configuration" "performance" "security" "other")
VALID_SOURCES=("review" "test" "incident" "audit" "user" "other")

show_help() {
    cat << 'EOF'
Usage: qms-register-issue.sh [options]

Register a nonconformance report (NCR) in backbone/artifacts/qms/ncr/.

Required:
  --title TEXT       Short descriptive title of the nonconformance
  --severity LVL     Severity: critical, major, minor, observation
  --category CAT     Category: process, documentation, code, configuration,
                     performance, security, other

Optional:
  --source SRC       Source: review, test, incident, audit, user, other (default: other)
  --description TEXT Detailed description (default: same as title)
  --change CHNG-XXX  Link to a change folder in backbone/artifacts/changes/ (optional)
  -h, --help         Show this help message

Examples:
  qms-register-issue.sh --title "Missing input validation on login" --severity critical --category code
  qms-register-issue.sh --title "Outdated README" --severity minor --category documentation --source review
  qms-register-issue.sh --title "Race condition" --severity major --category code --change CHNG-009
EOF
}

validate_arg() {
    local value="$1"
    local label="$2"
    local valid_values=("${!3}")

    for v in "${valid_values[@]}"; do
        if [[ "$v" == "$value" ]]; then
            return 0
        fi
    done

    echo -e "${RED}❌ Invalid $label: $value${NC}" >&2
    echo -e "${YELLOW}Valid values: ${valid_values[*]}${NC}" >&2
    exit 1
}

next_ncr_id() {
    mkdir -p "$NCR_DIR"
    local max_num=0
    local file
    for file in "$NCR_DIR"/NCR-*.yml; do
        if [[ -f "$file" ]]; then
            local basename
            basename="$(basename "$file" .yml)"
            local num="${basename#NCR-}"
            if [[ "$num" =~ ^[0-9]+$ ]]; then
                if (( 10#$num > max_num )); then
                    max_num=$((10#$num))
                fi
            fi
        fi
    done
    local next_num=$((max_num + 1))
    printf "NCR-%03d" "$next_num"
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --title)
                TITLE="$2"
                shift 2
                ;;
            --severity)
                SEVERITY="$2"
                shift 2
                ;;
            --category)
                CATEGORY="$2"
                shift 2
                ;;
            --source)
                SOURCE="$2"
                shift 2
                ;;
            --description)
                DESCRIPTION="$2"
                shift 2
                ;;
            --change)
                CHANGE_ID="$2"
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

    if [[ -z "$TITLE" ]]; then
        echo -e "${RED}❌ Missing required: --title${NC}" >&2
        show_help
        exit 1
    fi
    if [[ -z "$SEVERITY" ]]; then
        echo -e "${RED}❌ Missing required: --severity${NC}" >&2
        show_help
        exit 1
    fi
    if [[ -z "$CATEGORY" ]]; then
        echo -e "${RED}❌ Missing required: --category${NC}" >&2
        show_help
        exit 1
    fi

    if [[ -z "$SOURCE" ]]; then
        SOURCE="other"
    fi
    if [[ -z "$DESCRIPTION" ]]; then
        DESCRIPTION="$TITLE"
    fi

    validate_arg "$SEVERITY" "severity" VALID_SEVERITIES[@]
    validate_arg "$CATEGORY" "category" VALID_CATEGORIES[@]
    validate_arg "$SOURCE" "source" VALID_SOURCES[@]
}

main() {
    parse_args "$@"

    # Validate --change if provided
    if [ -n "$CHANGE_ID" ]; then
        if ! [[ "$CHANGE_ID" =~ ^CHNG-[0-9]{3}$ ]]; then
            echo -e "${RED}❌ Invalid change ID: $CHANGE_ID${NC}" >&2
            echo -e "${YELLOW}Expected format: CHNG-XXX (e.g., CHNG-009)${NC}" >&2
            exit 1
        fi
        local change_found=false
        for cd in "$PROJECT_ROOT/backbone/changes"/"$CHANGE_ID"-*/; do
            if [ -d "$cd" ]; then
                change_found=true
                break
            fi
        done
        if [ "$change_found" = false ]; then
            echo -e "${YELLOW}⚠️  Change folder not found: $CHANGE_ID${NC}" >&2
            echo -e "${YELLOW}   NCR will be created without a change link.${NC}" >&2
            CHANGE_ID=""
        fi
    fi

    local ncr_id
    ncr_id="$(next_ncr_id)"
    local date_str
    date_str="$(date +%Y-%m-%d)"
    local file_path="$NCR_DIR/$ncr_id.yml"

    cat > "$file_path" << NCR_EOF
# Nonconformance Report — $ncr_id
# Created: $date_str

id: "$ncr_id"
date: "$date_str"
title: "$TITLE"
severity: $SEVERITY
category: $CATEGORY
source: $SOURCE
description: "$DESCRIPTION"
status: open
$( [ -n "$CHANGE_ID" ] && echo "change: $CHANGE_ID" )
NCR_EOF

    echo -e "${GREEN}✅ Created: $file_path${NC}"
    echo -e "${CYAN}  ID:       $ncr_id${NC}"
    echo -e "${CYAN}  Title:    $TITLE${NC}"
    echo -e "${CYAN}  Severity: $SEVERITY${NC}"
    echo -e "${CYAN}  Category: $CATEGORY${NC}"
    echo -e "${CYAN}  Source:   $SOURCE${NC}"
    if [ -n "$CHANGE_ID" ]; then
        echo -e "${CYAN}  Change:   $CHANGE_ID${NC}"
    fi
    echo -e "${YELLOW}  Status:   open${NC}"
    echo ""
    # ── Auto-create CAPA for this NCR ────────────────────────────────────
    local capa_script="$SCRIPT_DIR/qms-capa-create.sh"
    if [ -x "$capa_script" ]; then
        echo -e "${CYAN}  → Auto-creating CAPA linked to $ncr_id...${NC}"
        if bash "$capa_script" --ncr "$ncr_id" --root-cause "Auto-generated from NCR: $TITLE" --action-plan "To be determined"; then
            echo ""
            echo -e "${GREEN}✅ CAPA auto-created for $ncr_id${NC}"
        else
            echo -e "${YELLOW}⚠️  CAPA creation failed — create manually:${NC}"
            echo -e "${YELLOW}   ./scripts/qms-capa-create.sh --ncr $ncr_id${NC}"
        fi
    else
        echo -e "${YELLOW}Next step: Create a CAPA with:${NC}"
        echo -e "${YELLOW}  ./scripts/qms-capa-create.sh --ncr $ncr_id${NC}"
    fi
}

main "$@"
