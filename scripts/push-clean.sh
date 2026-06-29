#!/bin/bash
# scripts/push-clean.sh
# Export a clean copy of the project — strips all AI agent scaffolding,
# leaving only runtime code. Creates a fresh git repo in a temp directory
# and optionally pushes to a remote.
#
# Usage:
#   bash scripts/push-clean.sh [--remote URL] [--branch NAME] [--dry-run]
#
# Examples:
#   bash scripts/push-clean.sh --dry-run
#   bash scripts/push-clean.sh --remote git@github.com:org/my-app.git
#   bash scripts/push-clean.sh --remote git@github.com:org/my-app.git --branch production

set -euo pipefail

if [[ -f "$HOME/.backbone/scripts/lib/bb-root.sh" ]]; then
    source "$HOME/.backbone/scripts/lib/bb-root.sh"
else
    PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    BB_ROOT="$PROJECT_ROOT"
fi

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_NAME="$(basename "$PROJECT_ROOT")"

REMOTE=""
BRANCH="main"
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --remote) REMOTE="$2"; shift 2 ;;
        --branch) BRANCH="$2"; shift 2 ;;
        --dry-run) DRY_RUN=true; shift ;;
        -h|--help)
            echo "Usage: $0 [--remote URL] [--branch NAME] [--dry-run]"
            echo ""
            echo "Export a clean project copy without AI agent scaffolding."
            echo ""
            echo "Options:"
            echo "  --remote URL     Push to this git remote after export"
            echo "  --branch NAME    Target branch (default: main)"
            echo "  --dry-run        Show what would be done without executing"
            echo "  -h, --help       Show this help"
            exit 0
            ;;
        *) echo "Unknown: $1"; exit 1 ;;
    esac
done

# ── Pre-flight checks ──────────────────────────────────────────────────────

if [ "$DRY_RUN" = false ]; then
    # Must have rsync
    if ! command -v rsync &> /dev/null; then
        echo -e "${RED}❌ rsync is required but not installed${NC}"
        exit 1
    fi

    # Source git must be clean
    if ! git -C "$PROJECT_ROOT" diff --quiet HEAD 2>/dev/null; then
        echo -e "${RED}❌ Source has uncommitted changes. Commit or stash first.${NC}"
        exit 1
    fi
fi

# ── Exclude patterns — files/dirs that ARE stripped ────────────────────────

EXCLUDES=(
    "--exclude=backbone/"
    "--exclude=.claude/"
    "--exclude=AGENTS.md"
    "--exclude=CLAUDE.md"
    "--exclude=COMMANDS.md"
    "--exclude=.backbone/"
    "--exclude=.worktrunk.toml"
    "--exclude=scripts/hooks/"
    "--exclude=templates/"
    "--exclude=.DS_Store"
    "--exclude=.git/"
)

# ── Build file list (for summary) ──────────────────────────────────────────

echo -e "${BLUE}=== push-clean: Export clean project copy ===${NC}"
echo ""
echo -e "  Project: ${YELLOW}$PROJECT_NAME${NC}"
echo -e "  Remote:  ${YELLOW}${REMOTE:-"(none)"}${NC}"
echo -e "  Branch:  ${YELLOW}$BRANCH${NC}"
echo ""

echo -e "${BLUE}Files that WILL be excluded:${NC}"
for ex in "${EXCLUDES[@]}"; do
    echo "  ❌ ${ex#--exclude=}"
done
echo ""

# Preview what would be included
echo -e "${BLUE}File count summary (dry run):${NC}"
EXCLUDE_ARGS=()
for ex in "${EXCLUDES[@]}"; do
    EXCLUDE_ARGS+=("$ex")
done
EXCLUDE_ARGS+=("--exclude=*/node_modules/*")
EXCLUDE_ARGS+=("--exclude=*/.git/*")

# Count
TOTAL_FILES=$(find "$PROJECT_ROOT" -type f -not -path '*/.git/*' -not -path '*/node_modules/*' 2>/dev/null | wc -l | tr -d ' ')

echo "  Total source files:  $TOTAL_FILES"
echo ""

if [ "$DRY_RUN" = true ]; then
    echo -e "${GREEN}=== Dry run complete. Use --remote URL to execute. ===${NC}"
    exit 0
fi

# ── Create temp directory ──────────────────────────────────────────────────

TEMP_DIR=$(mktemp -d)
TARGET_DIR="$TEMP_DIR/$PROJECT_NAME"
mkdir -p "$TARGET_DIR"

echo -e "${BLUE}Copying files to temp directory...${NC}"

rsync -a --quiet "${EXCLUDE_ARGS[@]}" "$PROJECT_ROOT/" "$TARGET_DIR/"

# ── Secret scan on exported copy ───────────────────────────────────────────

echo -e "${BLUE}Running secret scan on exported files...${NC}"
SCAN_SCRIPT="$PROJECT_ROOT/scripts/secret-scan.py"
if [ -f "$SCAN_SCRIPT" ]; then
    if python3 "$SCAN_SCRIPT" --dir "$TARGET_DIR" 2>/dev/null; then
        echo -e "  ${GREEN}✅ Secret scan passed${NC}"
    else
        echo -e "  ${RED}❌ Secrets detected in export! Aborting.${NC}"
        echo "  Export left at: $TARGET_DIR"
        exit 1
    fi
else
    echo -e "  ${YELLOW}⚠️  Secret scan script not found — skipping${NC}"
fi

# ── Initialize git repo ────────────────────────────────────────────────────

echo -e "${BLUE}Initializing fresh git repository...${NC}"

cd "$TARGET_DIR"

git init -q
git checkout -b "$BRANCH" 2>/dev/null || git branch -m "$BRANCH"
git add -A

# Count files being committed
COMMIT_COUNT=$(git ls-files | wc -l | tr -d ' ')
git commit -q -m "Initial clean import — $(date +%Y-%m-%d)"

COMMIT_HASH=$(git rev-parse --short HEAD)
echo -e "  ${GREEN}✅ Git repo initialized${NC}"
echo -e "  Branch:  ${YELLOW}$BRANCH${NC}"
echo -e "  Commit:  ${YELLOW}$COMMIT_HASH${NC}"
echo -e "  Files:   ${YELLOW}$COMMIT_COUNT${NC}"

# ── Create git bundle ──────────────────────────────────────────────────────

BUNDLE_PATH="/tmp/${PROJECT_NAME}-clean.bundle"
echo -e "${BLUE}Creating git bundle...${NC}"
git bundle create "$BUNDLE_PATH" --all --quiet
echo -e "  ${GREEN}✅ Bundle: $BUNDLE_PATH${NC}"

# ── Push to remote ─────────────────────────────────────────────────────────

if [ -n "$REMOTE" ]; then
    echo -e "${BLUE}Pushing to remote...${NC}"
    git remote add origin "$REMOTE"
    if git push -u origin "$BRANCH" 2>&1; then
        echo -e "  ${GREEN}✅ Pushed to $REMOTE ($BRANCH)${NC}"
    else
        echo -e "  ${RED}❌ Push failed. Export left at: $TARGET_DIR${NC}"
        echo "  You can push manually from that directory."
        exit 1
    fi
fi

# ── Report ─────────────────────────────────────────────────────────────────

echo ""
echo -e "${GREEN}=== Export Complete ===${NC}"
echo ""
echo "  Project:    $PROJECT_NAME"
echo "  Branch:     $BRANCH"
echo "  Commit:     $COMMIT_HASH"
echo "  Files:      $COMMIT_COUNT"
echo "  Bundle:     ${PROJECT_NAME}-clean.bundle"
if [ -n "$REMOTE" ]; then
    echo "  Remote:     $REMOTE"
fi
echo "  Temp dir:   $TARGET_DIR"
echo ""
echo -e "  ${YELLOW}To push to a different remote later:${NC}"
echo "    cd $TARGET_DIR"
echo "    git remote add origin <url>"
echo "    git push -u origin $BRANCH"
echo ""

exit 0
