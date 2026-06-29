#!/bin/bash
# scripts/backbone-change-archive.sh — Archive a completed change
#
# Gate Z checks:
#   1. All tasks are [x] (no [WIP] or [ ] remaining)
#   2. proposal.md contains **REQ-XXX** bullets
#   3. design.md exists and is non-empty
#   4. No open NCRs linked to this change (QMS integration)
#
# On pass: moves backbone/artifacts/changes/<id>-<name>/ → backbone/artifacts/changes/archive/<id>-YYYY-MM-DD/
# On fail: prints what's missing, exits 1
#
# Usage:
#   ./scripts/backbone-change-archive.sh CHNG-001
#   ./scripts/backbone-change-archive.sh CHNG-001 --force  (skip QMS checks)

set -euo pipefail
if [[ -f "$HOME/.backbone/scripts/lib/bb-root.sh" ]]; then
    source "$HOME/.backbone/scripts/lib/bb-root.sh"
else
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
    BB_ROOT="$PROJECT_ROOT"
fi
CHANGES_DIR="$PROJECT_ROOT/backbone/artifacts/changes"
NCR_DIR="$PROJECT_ROOT/backbone/artifacts/qms/ncr"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

FORCE=0

show_help() {
    cat << 'EOF'
Usage: backbone-change-archive.sh [options] CHNG-XXX

Archive a completed change folder from backbone/artifacts/changes/ to backbone/artifacts/changes/archive/.

Gate Z checks (all must pass):
  1. All tasks in tasks.md are [x] (no [WIP] or [ ])
  2. proposal.md contains **REQ-XXX** bullets
  3. design.md exists and is non-empty
  4. No open NCRs linked to this change (QMS integration)

Options:
  --force   Skip QMS integration checks (Gate Z4)

Example:
  backbone-change-archive.sh CHNG-001
  backbone-change-archive.sh --force CHNG-001
EOF
}

find_change_dir() {
    local id="$1"
    for dir in "$CHANGES_DIR"/"$id"-*/; do
        if [[ -d "$dir" ]]; then
            echo "$dir"
            return 0
        fi
    done
    return 1
}

main() {
    # Parse arguments
    local args=()
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --force) FORCE=1; shift ;;
            -h|--help) show_help; exit 0 ;;
            *) args+=("$1"); shift ;;
        esac
    done
    set -- "${args[@]}"

    if [[ $# -lt 1 ]]; then
        show_help
        exit 1
    fi

    local chng_id="$1"

    if ! [[ "$chng_id" =~ ^CHNG-[0-9]{3}$ ]]; then
        echo -e "${RED}❌ Invalid change ID: $chng_id${NC}" >&2
        echo -e "${YELLOW}Expected format: CHNG-XXX (e.g., CHNG-001)${NC}" >&2
        exit 1
    fi

    local change_dir
    change_dir="$(find_change_dir "$chng_id")" || {
        echo -e "${RED}❌ Change not found: $chng_id${NC}" >&2
        echo -e "${YELLOW}Looked in: $CHANGES_DIR/${chng_id}-*/${NC}" >&2
        exit 1
    }

    local change_name
    change_name="$(basename "$change_dir")"

    local proposal="$change_dir/proposal.md"
    local design="$change_dir/design.md"
    local tasks="$change_dir/tasks.md"

    local errors=0

    # ── Gate Z1: All tasks [x] ──────────────────────────────────────────
    echo -e "${CYAN}🔍 Gate Z1: Checking task completion...${NC}"
    local incomplete=0
    if [[ -f "$tasks" ]]; then
        while IFS= read -r line; do
            if [[ "$line" =~ ^[[:space:]]*##\ \[[[:space:]]\] ]] || [[ "$line" =~ ^[[:space:]]*##\ \[WIP\] ]]; then
                echo -e "  ${RED}✗ Incomplete:${NC} ${line//\#\# /}"
                incomplete=$((incomplete + 1))
            fi
        done < "$tasks"
        if [[ $incomplete -eq 0 ]]; then
            echo -e "  ${GREEN}✓ All tasks completed${NC}"
        else
            echo -e "  ${RED}✗ $incomplete task(s) incomplete${NC}"
            errors=$((errors + 1))
        fi
    else
        echo -e "  ${YELLOW}⚠  No tasks.md found — skipping task check${NC}"
    fi

    # ── Gate Z2: proposal REQ-XXX ───────────────────────────────────────
    echo -e "${CYAN}🔍 Gate Z2: Checking proposal REQ-XXX format...${NC}"
    if [[ -f "$proposal" ]]; then
        if grep -qE '\*\*REQ-[A-Z0-9]+-[0-9]+(\.[0-9]+)?\*\*' "$proposal"; then
            echo -e "  ${GREEN}✓ proposal.md has REQ-XXX requirements${NC}"
        else
            echo -e "  ${RED}✗ proposal.md missing **REQ-XXX** bullets${NC}"
            errors=$((errors + 1))
        fi
    else
        echo -e "  ${RED}✗ proposal.md not found${NC}"
        errors=$((errors + 1))
    fi

    # ── Gate Z3: design non-empty ───────────────────────────────────────
    echo -e "${CYAN}🔍 Gate Z3: Checking design.md...${NC}"
    if [[ -f "$design" ]]; then
        local line_count
        line_count=$(wc -l < "$design")
        if [[ "$line_count" -ge 3 ]]; then
            echo -e "  ${GREEN}✓ design.md exists and has content${NC}"
        else
            echo -e "  ${RED}✗ design.md is practically empty (${line_count} lines)${NC}"
            errors=$((errors + 1))
        fi
    else
        echo -e "  ${RED}✗ design.md not found${NC}"
        errors=$((errors + 1))
    fi

    # ── Gate Z4: Open NCRs linked to this change (QMS) ──────────────────
    local open_ncrs=()
    if [[ "$FORCE" -eq 0 ]] && [[ -d "$NCR_DIR" ]]; then
        echo -e "${CYAN}🔍 Gate Z4: Checking QMS NCRs linked to $chng_id...${NC}"
        for ncr in "$NCR_DIR"/*.yml; do
            [[ -f "$ncr" ]] || continue
            local ncr_change=""
            local ncr_status=""
            local ncr_title=""
            local ncr_severity=""
            while IFS= read -r line; do
                case "$line" in
                    change:*) ncr_change="${line#change: }" ;;
                    status:*) ncr_status="${line#status: }" ;;
                    title:*) ncr_title="${line#title: }" ;;
                    severity:*) ncr_severity="${line#severity: }" ;;
                esac
            done < "$ncr"
            ncr_change="${ncr_change//\"/}"
            ncr_status="${ncr_status//\"/}"
            ncr_title="${ncr_title//\"/}"
            ncr_severity="${ncr_severity//\"/}"
            if [[ "$ncr_change" == "$chng_id" && "$ncr_status" == "open" ]]; then
                open_ncrs+=("$ncr_severity: $ncr_title")
                echo -e "  ${RED}✗ Open NCR linked: $(basename "$ncr" .yml) — $ncr_title${NC}"
            fi
        done
        if [[ ${#open_ncrs[@]} -eq 0 ]]; then
            echo -e "  ${GREEN}✓ No open NCRs linked to this change${NC}"
        else
            echo -e "  ${RED}✗ ${#open_ncrs[@]} open NCR(s) linked to $chng_id${NC}"
            errors=$((errors + 1))
        fi
    elif [[ "$FORCE" -eq 1 ]]; then
        echo -e "  ${YELLOW}⚠  Gate Z4: skipped (--force)${NC}"
    fi

    # ── Summary ─────────────────────────────────────────────────────────
    if [[ $errors -gt 0 ]]; then
        echo ""
        echo -e "${RED}❌ Gate Z FAILED — $errors check(s) failed${NC}"
        echo -e "${YELLOW}Fix the issues above, then re-run the archive command.${NC}"
        echo -e "${YELLOW}Use --force to skip QMS checks (Gate Z4 only).${NC}"
        exit 1
    fi

    # ── Auto-generate lessons-learned if NCRs were linked ───────────────
    local date_str
    date_str="$(date +%Y-%m-%d)"
    local archive_dir="$CHANGES_DIR/archive/$chng_id-$date_str"

    mkdir -p "$CHANGES_DIR/archive"

    # Move change dir first so we can write into archive dir
    mv "$change_dir" "$archive_dir"

    # Auto-generate lessons-learned if NCRs were linked to this change
    if [[ -d "$NCR_DIR" ]]; then
        local linked_ncrs=()
        for ncr in "$NCR_DIR"/*.yml; do
            [[ -f "$ncr" ]] || continue
            local nc=""
            while IFS= read -r line; do
                [[ "$line" =~ ^change: ]] && nc="${line#change: }" && nc="${nc//\"/}"
            done < "$ncr"
            [[ "$nc" == "$chng_id" ]] && linked_ncrs+=("$(basename "$ncr" .yml)")
        done

        if [[ ${#linked_ncrs[@]} -gt 0 ]]; then
            cat > "$archive_dir/lessons-learned.md" << LL_EOF
# Lessons Learned — $chng_id

**Archived:** $date_str
**Linked NCRs:** ${linked_ncrs[*]}

## What Went Wrong

*Describe the root cause and contributing factors.*

## Corrective Actions

*Summarize the CAPAs taken to address this.*

## Prevention

*What process or tool change prevents this from recurring?*

---
*Auto-generated by backbone-change-archive.sh on $date_str*
LL_EOF
            echo -e "  ${GREEN}📝 Created: lessons-learned.md (fill in root cause and prevention)${NC}"
        fi
    fi

    # ── Update Changes Index ─────────────────────────────────────────────
    local index_file="$CHANGES_DIR/INDEX.md"
    local slug
    slug=$(basename "$change_dir" | sed "s/^$chng_id-//")
    # Extract first line of proposal for a short description
    local description
    description=$(grep -v '^#' "$proposal" 2>/dev/null | grep -E '^\*\*What:\*\*' | head -1 | sed 's/\*\*What:\*\*\s*//' || echo "$slug")

    if [ ! -f "$index_file" ]; then
        cat > "$index_file" << INDEX_EOF
# Changes Index

Auto-generated index of all changes (active and archived).
Active changes are in \`backbone/artifacts/changes/CHNG-*/\`.
Archived changes are in \`backbone/artifacts/changes/archive/CHNG-*\`.

| ID | Title | Status | Archived | Location |
|----|-------|--------|----------|----------|
INDEX_EOF
    fi

    # Update index: replace existing Active row, or append if not found
    local escaped_desc
    escaped_desc=$(echo "$description" | sed 's#|#\\|#g')
    local archive_line="| $chng_id | $escaped_desc | Archived | $date_str | \`archive/$chng_id-$date_str/\` |"
    if grep -q "^| $chng_id |" "$index_file" 2>/dev/null; then
        sed -i '' "s#^| $chng_id |.*#$archive_line#" "$index_file"
    else
        echo "$archive_line" >> "$index_file"
    fi

    echo ""
    echo -e "${GREEN}✅ Archived: $change_name${NC}"
    echo -e "  ${CYAN}From:${NC} $change_dir"
    echo -e "  ${CYAN}To:${NC}   $archive_dir"
    echo -e "  ${CYAN}Index:${NC} $index_file"
    echo ""
    echo -e "${GREEN}All Gate Z checks passed.${NC}"
}

main "$@"
