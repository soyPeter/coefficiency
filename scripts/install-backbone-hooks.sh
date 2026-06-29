#!/bin/bash
# install-backbone-hooks.sh — Update per-project hook/plugin paths to ~/.backbone/
#
# Replaces $(git rev-parse --show-toplevel) references in .claude/settings.json
# and .opencode/opencode.json* with $HOME/.backbone/ paths so all projects
# share the centralized backbone installation.
#
# Usage:
#   ./scripts/install-backbone-hooks.sh                    # Update current project
#   ./scripts/install-backbone-hooks.sh --project-dir /path # Specific project
#   ./scripts/install-backbone-hooks.sh --all               # All registered projects
#   ./scripts/install-backbone-hooks.sh --dry-run           # Preview only
#
# Part of: CHNG-033 centralize-scripts-and-features
# Task 1.3

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
BOLD='\033[1m'
NC='\033[0m'

DRY_RUN=0
ALL_PROJECTS=0
REGISTRY_FILE="$HOME/.backbone/projects.json"

usage() {
    cat << EOF
${BOLD}install-backbone-hooks.sh${NC} — Wire projects to centralized ~/.backbone/

${CYAN}Usage:${NC}
  ./scripts/install-backbone-hooks.sh [options]

${CYAN}Options:${NC}
  --project-dir <path>  Target a specific project (default: cwd)
  --all                 Update all registered projects
  --dry-run             Preview changes without modifying files
  -h, --help            Show this help

${CYAN}What gets updated:${NC}
  .claude/settings.json    → Hook paths point to \$HOME/.backbone/
  .opencode/opencode.json* → Plugin paths point to \$HOME/.backbone/
EOF
}

replace_hook_paths() {
    local settings_file="$1"
    if [[ ! -f "$settings_file" ]]; then
        echo -e "  ${YELLOW}⚠  No .claude/settings.json found${NC}"
        return 0
    fi

    if ! grep -q 'git rev-parse.*scripts/hooks' "$settings_file" 2>/dev/null; then
        echo -e "  ${CYAN}ℹ  Already using centralized paths${NC}"
        return 0
    fi

    if [[ "$DRY_RUN" -eq 1 ]]; then
        local count
        count=$(grep -c 'git rev-parse.*scripts/hooks\|git rev-parse.*.claude/hooks' "$settings_file" 2>/dev/null || true)
        echo -e "  ${CYAN}[DRY-RUN] Would update $count hook paths in settings.json${NC}"
        return 0
    fi

    local tmp
    tmp=$(mktemp) || return 1

    sed \
        -e 's|bash $(git rev-parse --show-toplevel)/scripts/hooks/|bash $HOME/.backbone/scripts/hooks/|g' \
        -e 's|bash $(git rev-parse --show-toplevel)/\.claude/hooks/|bash $HOME/.backbone/claude/hooks/|g' \
        "$settings_file" > "$tmp"

    mv "$tmp" "$settings_file"
    echo -e "  ${GREEN}✓ Updated .claude/settings.json${NC}"
}

replace_opencode_paths() {
    local opencode_config=""
    for candidate in "$1/.opencode/opencode.json" "$1/.opencode/opencode.jsonc"; do
        if [[ -f "$candidate" ]]; then
            opencode_config="$candidate"
            break
        fi
    done

    if [[ -z "$opencode_config" ]]; then
        echo -e "  ${CYAN}ℹ  No .opencode config found${NC}"
        return 0
    fi

    if ! grep -q '\.opencode/plugins/' "$opencode_config" 2>/dev/null; then
        echo -e "  ${CYAN}ℹ  Opencode config already centralized${NC}"
        return 0
    fi

    if [[ "$DRY_RUN" -eq 1 ]]; then
        local count
        count=$(grep -c '\.opencode/plugins/' "$opencode_config" 2>/dev/null || true)
        echo -e "  ${CYAN}[DRY-RUN] Would update $count plugin paths in opencode config${NC}"
        return 0
    fi

    local tmp
    tmp=$(mktemp) || return 1

    sed \
        -e 's|".opencode/plugins/|"$HOME/.backbone/opencode/plugins/|g' \
        "$opencode_config" > "$tmp"

    mv "$tmp" "$opencode_config"
    echo -e "  ${GREEN}✓ Updated opencode config${NC}"
}

update_project() {
    local proj_dir="$1"
    local proj_name
    proj_name=$(basename "$proj_dir")

    echo ""
    echo -e "${BOLD}  ${proj_name}${NC}"

    replace_hook_paths "$proj_dir/.claude/settings.json"
    replace_opencode_paths "$proj_dir"
}

update_all() {
    if [[ ! -f "$REGISTRY_FILE" ]]; then
        echo -e "${RED}No projects registered at $REGISTRY_FILE${NC}"
        exit 1
    fi

    echo -e "${BOLD}Updating all registered projects...${NC}"

    local projects
    projects=$(python3 -c "
import json, sys
with open('$REGISTRY_FILE') as f:
    data = json.load(f)
for p in data.get('projects',[]):
    print(p.get('path',''))
" 2>/dev/null)

    if [[ -z "$projects" ]]; then
        echo -e "${YELLOW}No projects found in registry${NC}"
        exit 0
    fi

    while IFS= read -r path; do
        [[ -z "$path" ]] && continue
        update_project "$path"
    done <<< "$projects"
}

main() {
    local target_project=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --project-dir)
                target_project="$2"
                shift 2
                ;;
            --all)
                ALL_PROJECTS=1
                shift
                ;;
            --dry-run)
                DRY_RUN=1
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                echo -e "${RED}Unknown option: $1${NC}" >&2
                usage
                exit 1
                ;;
        esac
    done

    if [[ "$DRY_RUN" -eq 1 ]]; then
        echo -e "${CYAN}[DRY-RUN mode — no files will be modified]${NC}"
    fi

    if [[ "$ALL_PROJECTS" -eq 1 ]]; then
        update_all
    elif [[ -n "$target_project" ]]; then
        update_project "$target_project"
    else
        update_project "$PROJECT_ROOT"
    fi

    echo ""
    if [[ "$DRY_RUN" -eq 1 ]]; then
        echo -e "${CYAN}Dry run complete. Re-run without --dry-run to apply.${NC}"
    else
        echo -e "${GREEN}Done. Hook and plugin paths updated to ~/.backbone/.${NC}"
    fi
}

main "$@"
