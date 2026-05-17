#!/bin/bash
# generate-delta-spec.sh: Auto-generate delta spec from git changes
#
# Analyzes the current working tree or a specific commit range
# and generates a delta specification documenting what changed,
# why, and what requirements were affected.
#
# Usage:
#   ./scripts/generate-delta-spec.sh                    # Analyze unstaged changes
#   ./scripts/generate-delta-spec.sh --staged           # Analyze staged changes
#   ./scripts/generate-delta-spec.sh <commit>           # Analyze since <commit>
#   ./scripts/generate-delta-spec.sh <base>..<head>     # Analyze commit range

set -euo pipefail

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
MODE="${1:-unstaged}"
OUTPUT_FILE=""

# ── Helpers ────────────────────────────────────────────────────────────────

detect_changes() {
    local mode="$1"
    
    case "$mode" in
        --staged)
            git diff --cached --name-only 2>/dev/null || true
            ;;
        unstaged|""|--unstaged)
            # Tracked changes + untracked files
            {
                git diff --name-only 2>/dev/null || true
                git ls-files --others --exclude-standard 2>/dev/null || true
            } | sort -u
            ;;
        *..*)
            git diff --name-only "$mode" 2>/dev/null || true
            ;;
        *)
            # Single commit or branch — compare with it
            git diff --name-only "$mode"..HEAD 2>/dev/null || git diff --name-only "$mode" 2>/dev/null || true
            ;;
    esac
}

detect_change_type() {
    local file="$1"
    local mode="$2"
    
    case "$mode" in
        --staged)
            git diff --cached -- "$file" | head -5
            ;;
        *)
            git diff -- "$file" | head -5
            ;;
    esac
}

get_file_status() {
    local file="$1"
    
    if git ls-files --error-unmatch "$file" > /dev/null 2>&1; then
        if [ -f "$file" ]; then
            echo "modified"
        else
            echo "deleted"
        fi
    else
        echo "added"
    fi
}

# Find related requirements for a file
find_related_reqs() {
    local file="$1"
    local reqs=""
    
    # Search traceability files for references to this file
    if [ -d "$PROJECT_DIR/storage/traceability" ]; then
        for trace in "$PROJECT_DIR/storage/traceability/"*.yml; do
            [ -f "$trace" ] || continue
            if grep -q "$file" "$trace" 2>/dev/null; then
                # Extract feature name
                feature=$(basename "$trace" .yml)
                # Extract REQ- IDs that reference this file
                ids=$(grep -B 5 "$file" "$trace" | grep -oE 'REQ-[A-Z]+-[0-9]+' | sort -u | tr '\n' ' ')
                if [ -n "$ids" ]; then
                    reqs="$reqs $ids"
                fi
            fi
        done
    fi
    
    # Also search PRDs for REQ- IDs mentioned in the file's diff
    if [ -d "$PROJECT_DIR/backbone/prd" ]; then
        # Extract REQ- IDs from the file content
        file_reqs=$(grep -oE 'REQ-[A-Z]+-[0-9]+' "$file" 2>/dev/null | sort -u | tr '\n' ' ' || true)
        if [ -n "$file_reqs" ]; then
            reqs="$reqs $file_reqs"
        fi
    fi
    
    echo "$reqs" | tr ' ' '\n' | sort -u | tr '\n' ' ' | sed 's/^ *//;s/ *$//'
}

# ── Main ───────────────────────────────────────────────────────────────────

echo -e "${BLUE}📋 Generating delta specification...${NC}"
echo ""

# Determine output file
DATE_PREFIX=$(date +%Y-%m-%d)
DELTA_DIR="$PROJECT_DIR/backbone/delta"
mkdir -p "$DELTA_DIR"

# Find next sequence number
seq=1
while [ -f "$DELTA_DIR/${DATE_PREFIX}-${seq}-delta.md" ]; do
    seq=$((seq + 1))
done

OUTPUT_FILE="$DELTA_DIR/${DATE_PREFIX}-${seq}-delta.md"

# Detect changes
CHANGED_FILES=$(detect_changes "$MODE")

if [ -z "$CHANGED_FILES" ]; then
    echo -e "${YELLOW}⚠️  No changes detected${NC}"
    exit 0
fi

# Categorize changes
declare -a ADDED_FILES
declare -a MODIFIED_FILES
declare -a DELETED_FILES

code_changes=""
test_changes=""
doc_changes=""
config_changes=""
other_changes=""

affected_reqs=""

while IFS= read -r file; do
    [ -z "$file" ] && continue
    
    status=$(get_file_status "$file")
    reqs=$(find_related_reqs "$file")
    
    if [ -n "$reqs" ]; then
        affected_reqs="$affected_reqs $reqs"
    fi
    
    case "$status" in
        added)
            ADDED_FILES+=("$file")
            ;;
        deleted)
            DELETED_FILES+=("$file")
            ;;
        *)
            MODIFIED_FILES+=("$file")
            ;;
    esac
    
    # Categorize by path
    if [[ "$file" =~ ^(src|lib|apps)/ ]]; then
        code_changes="$code_changes\n- $file ($status)"
    elif [[ "$file" =~ ^tests?/ ]]; then
        test_changes="$test_changes\n- $file ($status)"
    elif [[ "$file" =~ ^(docs?|backbone/|README) ]]; then
        doc_changes="$doc_changes\n- $file ($status)"
    elif [[ "$file" =~ ^(config/|\.env|\.github/|scripts/hooks) ]]; then
        config_changes="$config_changes\n- $file ($status)"
    else
        other_changes="$other_changes\n- $file ($status)"
    fi
done <<< "$CHANGED_FILES"

# Deduplicate affected requirements
affected_reqs=$(echo "$affected_reqs" | tr ' ' '\n' | grep -v '^$' | sort -u | tr '\n' ' ' | sed 's/^ *//;s/ *$//' || true)

# Generate delta spec
cat > "$OUTPUT_FILE" << EOF
# Delta Specification — $(date +%Y-%m-%d)

## Context

**Base:** ${MODE}
**Generated:** $(date '+%Y-%m-%d %H:%M:%S')
**Author:** $(git config user.name 2>/dev/null || echo "Unknown")

## Summary

<!-- Describe the high-level change in 1-2 sentences -->

## Files Changed

### Added (${#ADDED_FILES[@]})
EOF

if [ ${#ADDED_FILES[@]} -gt 0 ]; then
    for f in "${ADDED_FILES[@]}"; do
        echo "- \`$f\`" >> "$OUTPUT_FILE"
    done
else
    echo "_None_" >> "$OUTPUT_FILE"
fi

cat >> "$OUTPUT_FILE" << EOF

### Modified (${#MODIFIED_FILES[@]})
EOF

if [ ${#MODIFIED_FILES[@]} -gt 0 ]; then
    for f in "${MODIFIED_FILES[@]}"; do
        echo "- \`$f\`" >> "$OUTPUT_FILE"
    done
else
    echo "_None_" >> "$OUTPUT_FILE"
fi

cat >> "$OUTPUT_FILE" << EOF

### Deleted (${#DELETED_FILES[@]})
EOF

if [ ${#DELETED_FILES[@]} -gt 0 ]; then
    for f in "${DELETED_FILES[@]}"; do
        echo "- \`$f\`" >> "$OUTPUT_FILE"
    done
else
    echo "_None_" >> "$OUTPUT_FILE"
fi

cat >> "$OUTPUT_FILE" << EOF

## Requirements Impact

EOF

if [ -n "$affected_reqs" ]; then
    echo "The following requirements are affected by this change:" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    for req in $affected_reqs; do
        echo "- **$req** — <!-- describe impact -->" >> "$OUTPUT_FILE"
    done
else
    echo "_No tracked requirements affected. Consider adding REQ- IDs to changed files._" >> "$OUTPUT_FILE"
fi

cat >> "$OUTPUT_FILE" << EOF

## New Requirements

<!-- Add new EARS requirements introduced by this change -->
<!-- Example: -->
<!-- - REQ-NEW-01: WHEN <event> THEN <system> SHALL <response> -->

## Breaking Changes

<!-- List any breaking changes and migration steps -->

## Rollback Plan

<!-- Describe how to revert this change if needed -->
EOF

echo -e "${GREEN}✅ Delta spec generated: $OUTPUT_FILE${NC}"
echo ""
echo "Next steps:"
echo "  1. Review and fill in the Context and Summary sections"
echo "  2. Document requirements impact and add new requirements"
echo "  3. Note any breaking changes"
echo "  4. Commit the delta spec with your changes"
