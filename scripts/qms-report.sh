#!/bin/bash
# scripts/qms-report.sh — Generate QMS status and trend report
#
# Reads NCR and CAPA YAML files from backbone/artifacts/qms/ and produces
# a summary report with counts, trends, and aging items.
#
# Usage:
#   ./scripts/qms-report.sh              # Full report
#   ./scripts/qms-report.sh --summary    # One-line summary
#   ./scripts/qms-report.sh --aging      # Items past due
#   ./scripts/qms-report.sh --help

set -euo pipefail
if [[ -f "$HOME/.backbone/scripts/lib/bb-root.sh" ]]; then
    source "$HOME/.backbone/scripts/lib/bb-root.sh"
else
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
    BB_ROOT="$PROJECT_ROOT"
fiQMS_DIR="$PROJECT_ROOT/backbone/qms"
NCR_DIR="$QMS_DIR/ncr"
CAPA_DIR="$QMS_DIR/capa"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

MODE="full"
TODAY="$(date +%Y-%m-%d)"

show_help() {
    cat << 'EOF'
Usage: qms-report.sh [options]

Generate quality management system report from NCR and CAPA data.

Options:
  --summary     One-line summary (suitable for commit messages)
  --aging       Show only items past due
  -h, --help    Show this help message

Examples:
  qms-report.sh
  qms-report.sh --summary
  qms-report.sh --aging
EOF
}

parse_yaml_field() {
    local file="$1"
    local field="$2"
    grep "^${field}:" "$file" 2>/dev/null | sed "s/^${field}: *//" | sed 's/^"//;s/"$//' | tr -d '\n'
}

count_by_field() {
    local dir="$1"
    local field="$2"
    local pattern="$3"
    local ext="${4:-yml}"
    local count=0
    local f
    for f in "$dir"/*."$ext"; do
        [[ -f "$f" ]] || continue
        local val
        val="$(parse_yaml_field "$f" "$field")"
        if [[ "$val" == "$pattern" ]]; then
            count=$((count + 1))
        fi
    done
    echo "$count"
}

list_field_values() {
    local dir="$1"
    local field="$2"
    local ext="${3:-yml}"
    declare -a values=()
    local f
    for f in "$dir"/*."$ext"; do
        [[ -f "$f" ]] || continue
        local val
        val="$(parse_yaml_field "$f" "$field")"
        if [[ -n "$val" ]]; then
            echo "$val"
        fi
    done | sort | uniq -c | while read -r count key; do
        echo "$key:$count"
    done
}

report_full() {
    echo -e "${BLUE}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║        QMS Status Report — $(date +%Y-%m-%d)              ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════╝${NC}"
    echo ""

    local total_ncr=0
    local total_capa=0
    for f in "$NCR_DIR"/*.yml; do [[ -f "$f" ]] && total_ncr=$((total_ncr + 1)); done
    for f in "$CAPA_DIR"/*.yml; do [[ -f "$f" ]] && total_capa=$((total_capa + 1)); done

    echo -e "${BOLD}NCRs:${NC} $total_ncr total"
    echo -e "  Open:   $(count_by_field "$NCR_DIR" "status" "open")"
    echo -e "  Closed: $(count_by_field "$NCR_DIR" "status" "closed")"

    if [[ $total_ncr -gt 0 ]]; then
        echo ""
        echo -e "${BOLD}By Severity:${NC}"
        for s in critical major minor observation; do
            local c
            c="$(count_by_field "$NCR_DIR" "severity" "$s")"
            if [[ $c -gt 0 ]]; then
                echo -e "  ${s}: $c"
            fi
        done

        echo ""
        echo -e "${BOLD}By Category:${NC}"
        local cat_counts
        cat_counts="$(list_field_values "$NCR_DIR" "category")"
        while IFS= read -r line; do
            [[ -z "$line" ]] && continue
            local cat_name="${line%%:*}"
            local cat_count="${line##*:}"
            echo -e "  ${cat_name}: ${cat_count}"
        done <<< "$cat_counts" | sort
    fi

    echo ""
    echo -e "${BOLD}CAPAs:${NC} $total_capa total"
    for s in open "in-progress" verified closed; do
        local cc
        cc="$(count_by_field "$CAPA_DIR" "status" "$s")"
        if [[ $cc -gt 0 ]]; then
            echo -e "  ${s}: $cc"
        fi
    done

    if [[ $total_capa -gt 0 ]]; then
        echo ""
        echo -e "${YELLOW}${BOLD}Aging CAPAs (past due):${NC}"
        local aging=0
        local f
        for f in "$CAPA_DIR"/*.yml; do
            [[ -f "$f" ]] || continue
            local st
            st="$(parse_yaml_field "$f" "status")"
            [[ "$st" == "closed" ]] && continue
            local due
            due="$(parse_yaml_field "$f" "due_date")"
            if [[ -n "$due" && "$due" < "$TODAY" ]]; then
                local id
                id="$(parse_yaml_field "$f" "id")"
                local owner
                owner="$(parse_yaml_field "$f" "owner")"
                echo -e "  ${RED}⚠  $id${NC} (due: $due, owner: $owner)"
                aging=$((aging + 1))
            fi
        done
        if [[ $aging -eq 0 ]]; then
            echo -e "  ${GREEN}None${NC}"
        fi
    fi

    echo ""
    local closed_ncr
    closed_ncr="$(count_by_field "$NCR_DIR" "status" "closed")"
    if [[ $total_ncr -gt 0 ]]; then
        local closure_rate=$((closed_ncr * 100 / total_ncr))
        echo -e "${BOLD}Closure Rate:${NC} ${closure_rate}% (${closed_ncr}/${total_ncr})"
    fi
}

report_summary() {
    local total_ncr=0
    local open_ncr=0
    local total_capa=0
    local open_capa=0
    local aging=0
    for f in "$NCR_DIR"/*.yml; do [[ -f "$f" ]] && total_ncr=$((total_ncr + 1)); done
    for f in "$CAPA_DIR"/*.yml; do [[ -f "$f" ]] && total_capa=$((total_capa + 1)); done
    open_ncr="$(count_by_field "$NCR_DIR" "status" "open")"
    open_capa="$(count_by_field "$CAPA_DIR" "status" "open")"

    for f in "$CAPA_DIR"/*.yml; do
        [[ -f "$f" ]] || continue
        local st
        st="$(parse_yaml_field "$f" "status")"
        [[ "$st" == "closed" ]] && continue
        local due
        due="$(parse_yaml_field "$f" "due_date")"
        if [[ -n "$due" && "$due" < "$TODAY" ]]; then
            aging=$((aging + 1))
        fi
    done

    echo "QMS: ${total_ncr} NCRs (${open_ncr} open), ${total_capa} CAPAs (${open_capa} open, ${aging} aging)"
}

report_aging() {
    echo -e "${YELLOW}${BOLD}Aging Items (past due as of $TODAY)${NC}"
    echo ""
    local found=0
    local f
    for f in "$CAPA_DIR"/*.yml; do
        [[ -f "$f" ]] || continue
        local st
        st="$(parse_yaml_field "$f" "status")"
        [[ "$st" == "closed" ]] && continue
        local due
        due="$(parse_yaml_field "$f" "due_date")"
        if [[ -n "$due" && "$due" < "$TODAY" ]]; then
            local id
            id="$(parse_yaml_field "$f" "id")"
            local ncr_ref
            ncr_ref="$(parse_yaml_field "$f" "ncr_ref")"
            local owner
            owner="$(parse_yaml_field "$f" "owner")"
            local plan
            plan="$(parse_yaml_field "$f" "action_plan")"
            echo -e "${RED}⚠  $id${NC} (NCR: $ncr_ref)"
            echo -e "    Owner: $owner  Due: ${RED}$due${NC}"
            echo -e "    Plan:  $plan"
            found=$((found + 1))
        fi
    done
    if [[ $found -eq 0 ]]; then
        echo -e "${GREEN}No aging items${NC}"
    fi
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --summary)
                MODE="summary"
                shift
                ;;
            --aging)
                MODE="aging"
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                echo -e "${RED}❌ Unknown option: $1${NC}" >&2
                show_help
                exit 1
                ;;
        esac
    done
}

main() {
    parse_args "$@"

    case "$MODE" in
        full)    report_full ;;
        summary) report_summary ;;
        aging)   report_aging ;;
    esac
}

main "$@"
