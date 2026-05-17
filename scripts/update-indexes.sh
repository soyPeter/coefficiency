#!/bin/bash
# =============================================================================
# Update backbone indexes - run on session start
# =============================================================================
# This script updates index.md files in backbone subfolders
# Called by LLM on session start to ensure indexes are current
# =============================================================================

BACKBONE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

update_index() {
    local folder="$1"
    local title="$2"
    local pattern="$3"
    
    local index_file="$BACKBONE_DIR/$folder/index.md"
    
    echo "# $title Index" > "$index_file"
    echo "" >> "$index_file"
    echo "*Auto-generated - do not edit manually*" >> "$index_file"
    echo "" >> "$index_file"
    
    # Find all matching files
    local files=$(find "$BACKBONE_DIR/$folder" -maxdepth 1 -name "*.md" -not -name "index.md" -not -name ".DS_Store" | sort -r)
    
    if [ -n "$files" ]; then
        local last_cat=""
        for file in $files; do
            local basename=$(basename "$file" .md)
            local cat=$(echo "$basename" | cut -d'-' -f2)
            if [ "$cat" != "$last_cat" ]; then
                echo "## $pattern" >> "$index_file"
                last_cat="$cat"
            fi
            echo "- [[$basename]]" >> "$index_file"
        done
    fi
    
    echo "" >> "$index_file"
    echo "---" >> "$index_file"
    echo "*Run scripts/update-indexes.sh to regenerate*" >> "$index_file"
}

# Update indexes
update_index "prd" "PRD" "Products"
update_index "planning" "Planning" "Plans"
update_index "decisions" "Decisions" "Decisions"
update_index "memory" "Memory" "Memory"
update_index "knowledge" "Knowledge" "Knowledge"

echo "Updated backbone indexes"