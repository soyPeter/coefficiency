#!/bin/bash
# scripts/generate-feature-docs.sh — Generate release notes, memory entries, and
# feature docs from a change folder.
#
# Called by /backbone:close before archiving.
#
# Usage:
#   ./scripts/generate-feature-docs.sh CHNG-XXX
#   ./scripts/generate-feature-docs.sh CHNG-XXX --project-dir /path
#   ./scripts/generate-feature-docs.sh CHNG-XXX --dry-run
#   ./scripts/generate-feature-docs.sh CHNG-XXX --release-notes-only

set -euo pipefail
if [[ -f "$HOME/.backbone/scripts/lib/bb-root.sh" ]]; then
    source "$HOME/.backbone/scripts/lib/bb-root.sh"
else
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
    BB_ROOT="$PROJECT_ROOT"
fi
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

DRY_RUN=0
RELEASE_ONLY=0
CHNG_ID=""
PROJECT_DIR=""

usage() {
    cat << 'EOF'
Usage: generate-feature-docs.sh [options] CHNG-XXX

Generate release notes, memory entry, and feature docs from a change folder.

Arguments:
  CHNG-XXX              Change ID (required)

Options:
  --project-dir PATH    Project directory (auto-detect from cwd)
  --release-notes-only  Only generate release notes (skip memory + feature doc)
  --dry-run             Show what would be generated without writing
  -h, --help            Show this help
EOF
    exit 1
}

# Parse args
while [[ $# -gt 0 ]]; do
    case "$1" in
        --project-dir) PROJECT_DIR="$2"; shift 2 ;;
        --dry-run) DRY_RUN=1; shift ;;
        --release-notes-only) RELEASE_ONLY=1; shift ;;
        -h|--help) usage ;;
        CHNG-*) CHNG_ID="$1"; shift ;;
        *) echo "Unknown: $1"; usage ;;
    esac
done

if [ -z "$CHNG_ID" ]; then
    echo -e "${RED}Error: CHNG-XXX argument is required${NC}"
    usage
fi

# Determine project root
if [ -n "$PROJECT_DIR" ]; then
    PROJECT_ROOT="$PROJECT_DIR"
fi

# Find the change folder
CHANGES_DIR="$PROJECT_ROOT/backbone/artifacts/changes"
CHANGE_FOLDER=""
for dir in "$CHANGES_DIR"/"$CHNG_ID"-*/; do
    if [ -d "$dir" ]; then
        CHANGE_FOLDER="$dir"
        break
    fi
done

if [ -z "$CHANGE_FOLDER" ]; then
    echo -e "${RED}Error: Change folder not found for $CHNG_ID in $CHANGES_DIR${NC}"
    exit 1
fi

PROPOSAL="$CHANGE_FOLDER/proposal.md"
DESIGN="$CHANGE_FOLDER/design.md"

if [ ! -f "$PROPOSAL" ]; then
    echo -e "${RED}Error: $PROPOSAL not found${NC}"
    exit 1
fi

if [ ! -f "$DESIGN" ]; then
    echo -e "${YELLOW}Warning: $DESIGN not found — design details will be empty${NC}"
fi

echo -e "${CYAN}=== Generating docs for $CHNG_ID ===${NC}"
echo "  Change folder: $CHANGE_FOLDER"
echo "  Project root: $PROJECT_ROOT"
echo "  Dry run: $([ "$DRY_RUN" = 1 ] && echo 'yes' || echo 'no')"
echo ""

# ── Extract metadata from proposal.md ──

# Feature title: first H1 line, strip "# CHNG-XXX: " prefix
FEATURE_TITLE=$(sed -n '/^# CHNG-/p' "$PROPOSAL" | head -1 | sed 's/^# CHNG-[0-9]*: //')

# What/Why/Scope
FEATURE_WHAT=$(grep -E '^\*\*What:\*\*' "$PROPOSAL" | sed 's/\*\*What:\*\* //')
FEATURE_WHY=$(grep -E '^\*\*Why:\*\*' "$PROPOSAL" | sed 's/\*\*Why:\*\* //')
FEATURE_SCOPE=$(grep -E '^\*\*Scope:\*\*' "$PROPOSAL" | sed 's/\*\*Scope:\*\* //')

# Extract REQ- IDs
REQ_IDS=$(grep -E '^\-\s+\*\*REQ-' "$PROPOSAL" | sed 's/- \*\*\(REQ-[^ ]*\)\*\*.*/\1/')

# Extract key decisions from design.md (D-numbered entries with descriptions)
DESIGN_DECISIONS=""
if [ -f "$DESIGN" ]; then
    DESIGN_DECISIONS=$(awk '
    BEGIN { in_decisions=0; in_d=0; d_text=""; d_num=0 }
    /^## Decisions/ { in_decisions=1; next }
    /^## / && !/^## Decisions/ { in_decisions=0 }
    in_decisions {
        if ($0 ~ /^\*\*D[0-9]+:/) {
            if (d_num > 0) print d_text
            d_num++
            d_text="* " $0
            in_d=1
        } else if (in_d && $0 ~ /^[A-Z]/) {
            if (length(d_text) > 200) { in_d=0; next }
            d_text = d_text " " $0
        } else {
            in_d=0
        }
    }
    END { if (d_num > 0) print d_text }
    ' "$DESIGN")
    if [ -z "$DESIGN_DECISIONS" ]; then
        DESIGN_DECISIONS=$(grep -E '^\*\*D[0-9]+:' "$DESIGN" | sed 's/^\*\*\(D[0-9]\+\):\*\*/  - \1:/' | head -10)
    fi
fi

# Extract files manifest from design.md
DESIGN_FILES=""
if [ -f "$DESIGN" ]; then
    DESIGN_FILES=$(sed -n '/^## Files/,/^## /p' "$DESIGN" | grep -E '^\|' | grep -v '^|---' | tail -n +2)
fi

# ── Get git log for commits mentioning this CHNG-ID ──

GIT_LOG=""
if git -C "$PROJECT_ROOT" rev-parse --git-dir >/dev/null 2>&1; then
    GIT_LOG=$(git -C "$PROJECT_ROOT" log --oneline --grep="$CHNG_ID" 2>/dev/null | head -20)
fi

# ── Generate Release Notes ──

RELEASE_DATE=$(date +%Y-%m-%d)
RELEASE_DIR="$PROJECT_ROOT/backbone/artifacts/releases"
RELEASE_FILE="$RELEASE_DIR/$CHNG_ID-$RELEASE_DATE.md"

mkdir -p "$RELEASE_DIR"

generate_release_notes() {
    local file="$1"
    {
        echo "# $CHNG_ID: $FEATURE_TITLE"
        echo "**Date:** $RELEASE_DATE"
        echo ""
        if [ -n "$FEATURE_WHAT" ]; then
            echo "## Purpose"
            echo "$FEATURE_WHAT"
            echo ""
        fi
        if [ -n "$FEATURE_WHY" ]; then
            echo "## Motivation"
            echo "$FEATURE_WHY"
            echo ""
        fi
        if [ -n "$REQ_IDS" ]; then
            echo "## Requirements Implemented"
            echo "$REQ_IDS" | while read -r req; do
                echo "- $req"
            done
            echo ""
        fi
        if [ -n "$DESIGN_DECISIONS" ]; then
            echo "## Key Decisions"
            echo "$DESIGN_DECISIONS"
            echo ""
        fi
        if [ -n "$GIT_LOG" ]; then
            echo "## Git Changelog"
            echo '```'
            echo "$GIT_LOG"
            echo '```'
            echo ""
        fi
    } > "$file"
}

echo -e "  ${CYAN}1/4: Generating release notes...${NC}"
if [ "$DRY_RUN" = 1 ]; then
    generate_release_notes /dev/stdout
    echo -e "  ${YELLOW}  → Would write: $RELEASE_FILE${NC}"
else
    generate_release_notes "$RELEASE_FILE"
    echo -e "  ${GREEN}  ✓ $RELEASE_FILE${NC}"
fi
echo ""

if [ "$RELEASE_ONLY" = 1 ]; then
    echo -e "${GREEN}=== Release notes only (--release-notes-only) ===${NC}"
    exit 0
fi

# ── Append to Memory (6-MEMORY.md) ──

MEMORY_FILE="$PROJECT_ROOT/backbone/6-MEMORY.md"

generate_memory_entry() {
    local entry=""
    entry+="### $CHNG_ID: $FEATURE_TITLE ($RELEASE_DATE)"
    entry+=$'\n'
    if [ -n "$FEATURE_WHAT" ]; then
        entry+="- $FEATURE_WHAT"
        entry+=$'\n'
    fi
    if [ -n "$DESIGN_DECISIONS" ]; then
        while read -r line; do
            entry+="  $line"
            entry+=$'\n'
        done <<< "$DESIGN_DECISIONS"
    fi
    entry+=$'\n'
    echo "$entry"
}

echo -e "  ${CYAN}2/4: Appending to 6-MEMORY.md...${NC}"
MEMORY_ENTRY=$(generate_memory_entry)
if [ "$DRY_RUN" = 1 ]; then
    echo "$MEMORY_ENTRY"
    echo -e "  ${YELLOW}  → Would append to: $MEMORY_FILE${NC}"
else
    echo "$MEMORY_ENTRY" >> "$MEMORY_FILE"
    echo -e "  ${GREEN}  ✓ Appended to $MEMORY_FILE${NC}"
fi
echo ""

# ── Generate Feature Doc (docs/features/) ──

FEATURE_SLUG=$(echo "$CHNG_ID" | tr '[:upper:]' '[:lower:]')-$(echo "$FEATURE_TITLE" | sed 's/^CHNG-[0-9]*: //' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//')
FEATURE_DOC_DIR="$PROJECT_ROOT/docs/features"
FEATURE_DOC_FILE="$FEATURE_DOC_DIR/$FEATURE_SLUG.md"

mkdir -p "$FEATURE_DOC_DIR"

generate_feature_doc() {
    local file="$1"
    {
        echo "# Feature: $FEATURE_TITLE"
        echo ""
        echo "**$CHNG_ID** | **Closed:** $RELEASE_DATE"
        echo ""
        if [ -n "$FEATURE_WHAT" ]; then
            echo "## Purpose / Problem Solved"
            echo "$FEATURE_WHAT"
            echo ""
        fi
        if [ -n "$FEATURE_WHY" ]; then
            echo "## Motivation"
            echo "$FEATURE_WHY"
            echo ""
        fi
        echo "## How It Works"
        if [ -f "$DESIGN" ]; then
            echo "See the [design document](../../backbone/artifacts/changes/$CHNG_ID-*/design.md) for full architecture details."
        else
            echo "See the [$CHNG_ID change folder](../backbone/artifacts/changes/$CHNG_ID-*/) for architecture details."
        fi
        echo ""
        if [ -n "$DESIGN_DECISIONS" ]; then
            echo "## Key Decisions"
            echo "$DESIGN_DECISIONS"
            echo ""
        fi
        if [ -n "$FEATURE_SCOPE" ]; then
            echo "## Affected Areas"
            echo "$FEATURE_SCOPE"
            echo ""
        fi
        if [ -n "$DESIGN_FILES" ]; then
            echo "## Files Touched"
            echo "$DESIGN_FILES"
            echo ""
        fi
    } > "$file"
}

echo -e "  ${CYAN}3/4: Generating feature doc...${NC}"
if [ "$DRY_RUN" = 1 ]; then
    generate_feature_doc /dev/stdout
    echo -e "  ${YELLOW}  → Would write: $FEATURE_DOC_FILE${NC}"
else
    generate_feature_doc "$FEATURE_DOC_FILE"
    echo -e "  ${GREEN}  ✓ $FEATURE_DOC_FILE${NC}"
fi
echo ""

# ── Update docs/README.md index ──

DOCS_README="$PROJECT_ROOT/docs/README.md"

generate_docs_index() {
    local file="$1"
    if [ ! -f "$file" ]; then
        {
            echo "# Documentation"
            echo ""
            echo "Project documentation, guides, and feature references."
            echo ""
            echo "## Features"
            echo ""
        } > "$file"
    fi

    # Check if entry already exists
    if grep -q "($FEATURE_DOC_FILE)" "$file" 2>/dev/null; then
        return 0
    fi

    # Append entry before closing content
    local entry="- [$FEATURE_TITLE]($FEATURE_DOC_FILE) — $CHNG_ID ($RELEASE_DATE)"
    # Insert before last empty line or at end
    if [ -f "$file" ]; then
        # Find Features section and add entry
        local tmp_file="${file}.tmp"
        awk -v entry="$entry" '
        /^## Features/ { print; found=1; next }
        found && /^$/ { print entry; print; found=0; next }
        found && /^## / { print entry; print; found=0; print; next }
        { print }
        END { if (found) { print entry } }
        ' "$file" > "$tmp_file"
        mv "$tmp_file" "$file"
    fi
}

echo -e "  ${CYAN}4/4: Updating docs/README.md index...${NC}"
if [ "$DRY_RUN" = 1 ]; then
    echo -e "  ${YELLOW}  → Would update: $DOCS_README${NC}"
    echo "  Entry: - [$FEATURE_TITLE](docs/features/$FEATURE_SLUG.md) — $CHNG_ID ($RELEASE_DATE)"
else
    generate_docs_index "$DOCS_README"
    echo -e "  ${GREEN}  ✓ Updated $DOCS_README${NC}"
fi
echo ""

echo -e "${GREEN}=== Documentation generated for $CHNG_ID ===${NC}"
