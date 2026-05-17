#!/bin/bash
# scripts/compact-backbone.sh — Compact old backbone entries into archives
#
# Scans backbone directories, groups old files by time period,
# compacts them into archive files, and backs up originals.
#
# Usage:
#   ./scripts/compact-backbone.sh decisions              # Compact decisions/ (90d, quarterly)
#   ./scripts/compact-backbone.sh --age 60 prd          # Compact PRDs older than 60 days
#   ./scripts/compact-backbone.sh --dry-run memory      # Preview without changes
#   ./scripts/compact-backbone.sh --restore decisions   # Restore from .backup/
#   ./scripts/compact-backbone.sh --all                 # Compact all directories
#
# Rules:
#   - Decisions: only archive Accepted/Rejected, skip Pending/Proposed
#   - PRDs: only archive Implemented/Abandoned, skip Draft/In Review
#   - Planning/Memory/Releases: archive all older than threshold
#   - Always backs up originals to .backup/ (reversible)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Defaults
AGE_DAYS=90
PERIOD="quarterly"
DRY_RUN=false
RESTORE=false
COMPACT_ALL=false
TARGET_DIR=""

show_help() {
    cat << 'EOF'
Usage: compact-backbone.sh [options] <directory>

Compact old backbone entries into archives by time period.

Arguments:
  directory      Directory to compact: decisions, memory, prd, planning, releases
                 (or memory/lessons, memory/patterns for subdirectories)

Options:
  --age N        Only compact files older than N days (default: 90)
  --period P     Grouping period: monthly, quarterly, yearly (default: quarterly)
  --dry-run      Preview changes without writing files
  --restore      Reverse: move .backup/ files back to active
  --all          Compact all supported directories
  -h, --help     Show this help message

Examples:
  compact-backbone.sh decisions                    # Compact decisions (90d, quarterly)
  compact-backbone.sh --age 60 --period monthly prd
  compact-backbone.sh --dry-run memory             # Preview only
  compact-backbone.sh --restore decisions          # Restore from backup
  compact-backbone.sh --all                        # Compact everything

Smart Rules:
  - Decisions: archive Accepted/Rejected only, skip Pending/Proposed
  - PRDs: archive Implemented/Abandoned only, skip Draft/In Review
  - Planning/Memory/Releases: archive all older than threshold

All operations are reversible via --restore.
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --age)
                AGE_DAYS="$2"
                shift 2
                ;;
            --period)
                PERIOD="$2"
                shift 2
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --restore)
                RESTORE=true
                shift
                ;;
            --all)
                COMPACT_ALL=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            -*)
                echo -e "${RED}❌ Unknown option: $1${NC}"
                show_help
                exit 1
                ;;
            *)
                if [[ -z "$TARGET_DIR" ]]; then
                    TARGET_DIR="$1"
                else
                    echo -e "${RED}❌ Only one directory allowed${NC}"
                    exit 1
                fi
                shift
                ;;
        esac
    done

    if [[ "$COMPACT_ALL" == false && -z "$TARGET_DIR" ]]; then
        echo -e "${RED}❌ Error: directory required (or use --all)${NC}"
        show_help
        exit 1
    fi

    case "$PERIOD" in
        monthly|quarterly|yearly) ;;
        *)
            echo -e "${RED}❌ Invalid period: $PERIOD (must be monthly, quarterly, or yearly)${NC}"
            exit 1
            ;;
    esac
}

# Resolve directory path from shorthand
resolve_dir() {
    local dir="$1"
    case "$dir" in
        decisions) echo "$PROJECT_ROOT/backbone/decisions" ;;
        memory) echo "$PROJECT_ROOT/backbone/memory" ;;
        "memory/lessons"|"memory-lessons") echo "$PROJECT_ROOT/backbone/memory/lessons" ;;
        "memory/patterns"|"memory-patterns") echo "$PROJECT_ROOT/backbone/memory/patterns" ;;
        prd) echo "$PROJECT_ROOT/backbone/prd" ;;
        planning) echo "$PROJECT_ROOT/backbone/planning" ;;
        releases) echo "$PROJECT_ROOT/backbone/releases" ;;
        *)
            if [[ -d "$PROJECT_ROOT/backbone/$dir" ]]; then
                echo "$PROJECT_ROOT/backbone/$dir"
            elif [[ -d "$dir" ]]; then
                echo "$dir"
            else
                echo ""
            fi
            ;;
    esac
}

# Extract date from filename (20260412-title.md → 20260412)
extract_date() {
    local filename="$(basename "$1")"
    # Try YYYYMMDD pattern first
    if [[ "$filename" =~ ^([0-9]{8}) ]]; then
        echo "${BASH_REMATCH[1]}"
        return 0
    fi
    # Try vX.Y.Z pattern for releases
    if [[ "$filename" =~ ^v([0-9]+\.[0-9]+) ]]; then
        echo "${BASH_REMATCH[1]}"
        return 0
    fi
    # Fallback to file mtime
    stat -f "%Sm" -t "%Y%m%d" "$1" 2>/dev/null || stat -c "%Y" "$1" | xargs -I{} date -r {} +%Y%m%d 2>/dev/null || echo ""
}

# Check if file is old enough
is_old_enough() {
    local file="$1"
    local file_date
    file_date="$(extract_date "$file")"
    if [[ -z "$file_date" ]]; then
        return 1
    fi

    local file_epoch
    file_epoch="$(date -j -f "%Y%m%d" "$file_date" "+%s" 2>/dev/null || date -d "${file_date:0:4}-${file_date:4:2}-${file_date:6:2}" +%s 2>/dev/null || echo "")"
    if [[ -z "$file_epoch" ]]; then
        return 1
    fi

    local cutoff_epoch
    cutoff_epoch="$(date -v-${AGE_DAYS}d +%s 2>/dev/null || date -d "$AGE_DAYS days ago" +%s 2>/dev/null)"

    [[ "$file_epoch" -lt "$cutoff_epoch" ]]
}

# Check if file should be skipped based on status
should_skip_by_status() {
    local file="$1"
    local dir_type="$2"
    local content
    content="$(head -20 "$file" 2>/dev/null || echo "")"

    case "$dir_type" in
        decisions)
            # Skip Pending or Proposed decisions
            if echo "$content" | grep -qiE "^\*\*Status:\*\*\s*(Pending|Proposed)"; then
                return 0
            fi
            ;;
        prd)
            # Skip Draft or In Review PRDs
            if echo "$content" | grep -qiE "^\*\*Status:\*\*\s*(Draft|In Review|Review)"; then
                return 0
            fi
            # Also check frontmatter status
            if echo "$content" | grep -qiE "^status:\s*(draft|in-review|review)"; then
                return 0
            fi
            ;;
    esac
    return 1
}

# Determine period label from date
period_label() {
    local date_str="$1"
    local year="${date_str:0:4}"
    local month="${date_str:4:2}"

    case "$PERIOD" in
        monthly)
            echo "${year}-${month}"
            ;;
        quarterly)
            local quarter
            case "$month" in
                01|02|03) quarter="Q1" ;;
                04|05|06) quarter="Q2" ;;
                07|08|09) quarter="Q3" ;;
                10|11|12) quarter="Q4" ;;
            esac
            echo "${year}-${quarter}"
            ;;
        yearly)
            echo "$year"
            ;;
    esac
}

# Extract title from file
extract_title() {
    local file="$1"
    local title
    title="$(grep -m1 "^# " "$file" 2>/dev/null | sed 's/^# //' || basename "$file" .md)"
    echo "$title"
}

# Extract status from file
extract_status() {
    local file="$1"
    local status
    status="$(grep -m1 -iE "^\*\*Status:\*\*" "$file" 2>/dev/null | sed 's/.*:\*\*\s*//' || echo "—")"
    echo "$status"
}

# Compact a single directory
compact_directory() {
    local dir="$1"
    local dir_name
    dir_name="$(basename "$dir")"
    local parent_dir
    parent_dir="$(dirname "$dir")"
    local archive_dir="$parent_dir/archive"
    local backup_dir="$dir/.backup"
    local dir_type

    # Determine directory type for status filtering
    case "$dir_name" in
        decisions) dir_type="decisions" ;;
        prd) dir_type="prd" ;;
        planning) dir_type="planning" ;;
        lessons|patterns) dir_type="memory" ;;
        releases) dir_type="releases" ;;
        *) dir_type="other" ;;
    esac

    echo -e "${BLUE}📦 Compacting: $dir_name${NC}"

    if [[ "$RESTORE" == true ]]; then
        restore_directory "$dir"
        return
    fi

    # Collect eligible files
    local -a eligible_files=()
    local file
    while IFS= read -r -d '' file; do
        # Skip index.md, archive/, .backup/
        local basename_file
        basename_file="$(basename "$file")"
        [[ "$basename_file" == "index.md" ]] && continue
        [[ "$file" == */archive/* ]] && continue
        [[ "$file" == */.backup/* ]] && continue

        if is_old_enough "$file"; then
            if should_skip_by_status "$file" "$dir_type"; then
                echo -e "  ${YELLOW}⏭️  Skipping (active status): $(basename "$file")${NC}"
                continue
            fi
            eligible_files+=("$file")
        fi
    done < <(find "$dir" -maxdepth 1 -type f -name "*.md" -print0 2>/dev/null)

    if [[ ${#eligible_files[@]} -eq 0 ]]; then
        echo -e "  ${GREEN}✓ No files to compact (all newer than ${AGE_DAYS} days or active status)${NC}"
        return
    fi

    echo -e "  ${CYAN}→ Found ${#eligible_files[@]} file(s) to compact${NC}"

    # Group files by period using temp files (bash 3.2 compatible)
    local tmp_group_dir
    tmp_group_dir="$(mktemp -d)"
    trap "rm -rf '$tmp_group_dir'" EXIT

    local f
    for f in "${eligible_files[@]}"; do
        local date_str
        date_str="$(extract_date "$f")"
        local label
        label="$(period_label "$date_str")"
        # Sanitize label for filename
        local safe_label
        safe_label="$(echo "$label" | sed 's/[^a-zA-Z0-9_-]/_/g')"
        echo "$f" >> "$tmp_group_dir/$safe_label"
    done

    # Create archive for each period group
    local period_file
    for period_file in "$tmp_group_dir"/*; do
        [[ -f "$period_file" ]] || continue
        local period
        period="$(basename "$period_file")"
        local archive_file="$archive_dir/${dir_name}-${period}.md"
        local file_count
        file_count="$(wc -l < "$period_file" | tr -d ' ')"

        echo -e "  ${BLUE}→ Creating archive: archive/$(basename "$archive_file")${NC}"

        if [[ "$DRY_RUN" == true ]]; then
            echo -e "    ${CYAN}[DRY-RUN] Would create archive with $file_count files${NC}"
            continue
        fi

        mkdir -p "$archive_dir"
        mkdir -p "$backup_dir"

        # Build archive content
        {
            echo "# $(tr '[:lower:]' '[:upper:]' <<< "${dir_name:0:1}")${dir_name:1} Archive — $period"
            echo ""
            echo "*Compacted from $file_count file(s) on $(date +%Y-%m-%d)*"
            echo ""
            echo "## Index"
            echo ""
            echo "| Date | Title | Status |"
            echo "|------|-------|--------|"

            while IFS= read -r idx_file; do
                [[ -z "$idx_file" ]] && continue
                local idx_date
                idx_date="$(extract_date "$idx_file")"
                local idx_title
                idx_title="$(extract_title "$idx_file")"
                local idx_status
                idx_status="$(extract_status "$idx_file")"
                echo "| ${idx_date:0:4}-${idx_date:4:2}-${idx_date:6:2} | $idx_title | $idx_status |"
            done < "$period_file"

            echo ""
            echo "---"
            echo ""

            while IFS= read -r content_file; do
                [[ -z "$content_file" ]] && continue
                echo "<!-- Source: $(basename "$content_file") -->"
                echo ""
                cat "$content_file"
                echo ""
                echo "---"
                echo ""
            done < "$period_file"
        } > "$archive_file"

        # Move originals to backup
        while IFS= read -r backup_file; do
            [[ -z "$backup_file" ]] && continue
            mv "$backup_file" "$backup_dir/"
            echo -e "    ${GREEN}✓ Archived: $(basename "$backup_file")${NC}"
        done < "$period_file"
    done

    # Regenerate index
    regenerate_index "$dir"
}

# Restore files from .backup/
restore_directory() {
    local dir="$1"
    local backup_dir="$dir/.backup"
    local dir_name
    dir_name="$(basename "$dir")"

    echo -e "${BLUE}🔄 Restoring: $dir_name${NC}"

    if [[ ! -d "$backup_dir" ]]; then
        echo -e "  ${YELLOW}⚠️  No backup directory found${NC}"
        return
    fi

    local count=0
    local file
    while IFS= read -r -d '' file; do
        mv "$file" "$dir/"
        count=$((count + 1))
        echo -e "  ${GREEN}✓ Restored: $(basename "$file")${NC}"
    done < <(find "$backup_dir" -maxdepth 1 -type f -name "*.md" -print0 2>/dev/null)

    if [[ $count -eq 0 ]]; then
        echo -e "  ${YELLOW}⚠️  No files to restore${NC}"
        return
    fi

    # Remove archive files that would now be duplicates
    local archive_dir="$(dirname "$dir")/archive"
    if [[ -d "$archive_dir" ]]; then
        local archive
        while IFS= read -r -d '' archive; do
            if [[ "$(basename "$archive")" == ${dir_name}-* ]]; then
                rm "$archive"
                echo -e "  ${YELLOW}🗑️  Removed archive: $(basename "$archive")${NC}"
            fi
        done < <(find "$archive_dir" -maxdepth 1 -type f -name "*.md" -print0 2>/dev/null)
    fi

    # Regenerate index
    regenerate_index "$dir"

    echo -e "  ${GREEN}✓ Restored $count file(s)${NC}"
}

# Regenerate index.md for a directory
regenerate_index() {
    local dir="$1"
    local index_file="$dir/index.md"
    local dir_name
    dir_name="$(basename "$dir")"
    local archive_dir="$(dirname "$dir")/archive"

    if [[ "$DRY_RUN" == true ]]; then
        echo -e "    ${CYAN}[DRY-RUN] Would regenerate index.md${NC}"
        return
    fi

    {
        echo "# $(tr '[:lower:]' '[:upper:]' <<< "${dir_name:0:1}")${dir_name:1} Index"
        echo ""
        echo "*Auto-generated index — do not edit manually*"
        echo ""

        # Active files
        local has_active=false
        local file
        while IFS= read -r -d '' file; do
            local basename_file
            basename_file="$(basename "$file")"
            [[ "$basename_file" == "index.md" ]] && continue
            if [[ "$has_active" == false ]]; then
                echo "## Active"
                echo ""
                has_active=true
            fi
            local title
            title="$(extract_title "$file")"
            local date_str
            date_str="$(extract_date "$file")"
            echo "- [[${basename_file%.md}]] — $title"
        done < <(find "$dir" -maxdepth 1 -type f -name "*.md" -print0 2>/dev/null | sort -z)

        if [[ "$has_active" == true ]]; then
            echo ""
        fi

        # Archive files
        local has_archive=false
        local archive
        while IFS= read -r -d '' archive; do
            if [[ "$has_archive" == false ]]; then
                echo "## Archives"
                echo ""
                has_archive=true
            fi
            local archive_name
            archive_name="$(basename "$archive" .md)"
            # Extract period from archive name (decisions-2026-Q2 → 2026 Q2)
            local period
            period="$(echo "$archive_name" | sed 's/^[^-]*-//' | tr '-' ' ')"
            echo "- [Archive: $period](archive/$(basename "$archive"))"
        done < <(find "$archive_dir" -maxdepth 1 -type f -name "${dir_name}-*.md" -print0 2>/dev/null | sort -z)

        if [[ "$has_archive" == false ]]; then
            echo ""
        fi
    } > "$index_file"

    echo -e "  ${GREEN}✓ Updated index.md${NC}"
}

# Run compaction on all supported directories
compact_all() {
    echo -e "${BLUE}📦 Compacting all backbone directories${NC}"
    echo ""

    local dirs=(
        "$PROJECT_ROOT/backbone/decisions"
        "$PROJECT_ROOT/backbone/memory/lessons"
        "$PROJECT_ROOT/backbone/memory/patterns"
        "$PROJECT_ROOT/backbone/prd"
        "$PROJECT_ROOT/backbone/planning"
        "$PROJECT_ROOT/backbone/releases"
    )

    local dir
    for dir in "${dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            compact_directory "$dir"
            echo ""
        fi
    done
}

# Main
main() {
    parse_args "$@"

    if [[ "$DRY_RUN" == true ]]; then
        echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║     DRY RUN — No files will be modified                  ║${NC}"
        echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
        echo ""
    fi

    if [[ "$COMPACT_ALL" == true ]]; then
        compact_all
    else
        local resolved_dir
        resolved_dir="$(resolve_dir "$TARGET_DIR")"
        if [[ -z "$resolved_dir" ]]; then
            echo -e "${RED}❌ Directory not found: $TARGET_DIR${NC}"
            exit 1
        fi
        if [[ ! -d "$resolved_dir" ]]; then
            echo -e "${RED}❌ Directory does not exist: $resolved_dir${NC}"
            exit 1
        fi
        compact_directory "$resolved_dir"
    fi

    echo ""
    echo -e "${GREEN}✅ Done${NC}"
    if [[ "$DRY_RUN" == true ]]; then
        echo -e "${CYAN}This was a dry run. No files were modified.${NC}"
    elif [[ "$RESTORE" == true ]]; then
        echo -e "${GREEN}Restored files from .backup/ directories${NC}"
    fi
}

main "$@"
