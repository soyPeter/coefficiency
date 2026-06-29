#!/bin/bash
# install-backbone.sh — Install backbone infrastructure to ~/.backbone/
#
# Copies scripts, skills, agents, commands, hooks, plugins, and templates
# from the generator project to ~/.backbone/ so all projects share one copy.
#
# Usage:
#   ./scripts/install-backbone.sh              # Install to ~/.backbone/
#   ./scripts/install-backbone.sh --dry-run    # Preview without copying
#   ./scripts/install-backbone.sh --force      # Overwrite existing without prompt
#   ./scripts/install-backbone.sh --bb-root /path  # Alternate target directory
#   ./scripts/install-backbone.sh --generate-templates  # Also generate templates
#
# Part of: CHNG-033 centralize-scripts-and-features
# REQ-BB-001 through REQ-BB-005

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
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

GENERATOR_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "$PROJECT_ROOT")
BB_ROOT="$HOME/.backbone"

DRY_RUN=0
FORCE=0
GENERATE_TEMPLATES=0
FILES_COPIED=0
DIRS_COPIED=0

usage() {
    cat << EOF
${BOLD}install-backbone.sh${NC} — Install backbone infrastructure to ~/.backbone/

${CYAN}Usage:${NC}
  ./scripts/install-backbone.sh [options]

${CYAN}Options:${NC}
  --dry-run              Preview copy operations without executing
  --force                Skip confirmation prompt, overwrite existing files
  --bb-root <path>       Install to alternate directory (default: ~/.backbone)
  --generate-templates   Also generate/update template files in ~/.backbone/templates/
  -h, --help            Show this help

${CYAN}What gets installed:${NC}
  ~/.backbone/
  ├── scripts/           → Generator scripts/*.sh + lib/ + hooks/
  ├── skills/            → Generator backbone/skills/
  ├── claude/
  │   ├── agents/        → Generator .claude/agents/
  │   ├── commands/      → Generator .claude/commands/
  │   └── hooks/         → Generator .claude/hooks/
  ├── opencode/
  │   ├── agents/        → Generator .opencode/agents/
  │   └── plugins/       → Generator .opencode/plugins/
  ├── templates/         → Generator templates/ (if --generate-templates)
  └── projects.json      → Preserved if exists (never overwritten)
EOF
}

section_header() {
    echo ""
    echo -e "${BLUE}── $1${NC}"
}

copy_tree() {
    local src="$1"
    local dest="$2"
    local label="$3"

    if [[ ! -d "$src" ]]; then
        echo -e "  ${YELLOW}⚠  Source not found: $src${NC}"
        return 0
    fi

    if [[ "$DRY_RUN" -eq 1 ]]; then
        local count
        count=$(find "$src" -type f | wc -l | tr -d ' ')
        echo -e "  ${CYAN}[DRY-RUN] Would copy $count files: $src → $dest${NC}"
        FILES_COPIED=$((FILES_COPIED + count))
        DIRS_COPIED=$((DIRS_COPIED + 1))
        return 0
    fi

    mkdir -p "$dest"
    rsync -a --delete "$src/" "$dest/" 2>/dev/null || {
        cp -R "$src/"* "$dest/" 2>/dev/null || true
        echo -e "  ${YELLOW}⚠  rsync failed for $label, used cp fallback${NC}"
    }
    local count
    count=$(find "$dest" -type f 2>/dev/null | wc -l | tr -d ' ')
    echo -e "  ${GREEN}✓ $label${NC} ($count files)"
    FILES_COPIED=$((FILES_COPIED + count))
    DIRS_COPIED=$((DIRS_COPIED + 1))
}

confirm_install() {
    if [[ "$FORCE" -eq 1 ]] || [[ "$DRY_RUN" -eq 1 ]]; then
        return 0
    fi

    if [[ ! -d "$BB_ROOT" ]]; then
        return 0
    fi

    local existing_count
    existing_count=$(find "$BB_ROOT" -type f 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$existing_count" -gt 0 ]]; then
        echo ""
        echo -e "${YELLOW}${BOLD}$BB_ROOT already exists with $existing_count files.${NC}"
        echo -ne "${YELLOW}Overwrite? [y/N] ${NC}"
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            echo "Aborted."
            exit 0
        fi
    fi
}

preserve_projects_json() {
    local dest="$BB_ROOT/projects.json"
    if [[ -f "$dest" ]] && [[ "$DRY_RUN" -eq 0 ]]; then
        cp "$dest" "$dest.bak"
        echo -e "  ${CYAN}Backed up: ${dest}.bak${NC}"
    fi
}

print_summary() {
    echo ""
    echo -e "${BLUE}══════════════════════════════════════════════════════${NC}"
    if [[ "$DRY_RUN" -eq 1 ]]; then
        echo -e "${CYAN}  DRY RUN — no files were actually copied${NC}"
    else
        echo -e "${GREEN}  Installation complete!${NC}"
    fi
    echo -e "  Target:    ${BOLD}$BB_ROOT${NC}"
    echo -e "  Directories: ${BOLD}$DIRS_COPIED${NC}"
    echo -e "  Files:       ${BOLD}$FILES_COPIED${NC}"
    echo -e "${BLUE}══════════════════════════════════════════════════════${NC}"

    if [[ "$DRY_RUN" -eq 0 ]]; then
        echo ""
        echo -e "${CYAN}Next steps:${NC}"
        echo -e "  1. Run ${BOLD}./scripts/install-backbone-hooks.sh${NC} to update per-project hook paths"
        echo -e "  2. Run ${BOLD}./scripts/update-backbone.sh --all-known${NC} to sync projects"
    fi
}

main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                DRY_RUN=1
                shift
                ;;
            --force)
                FORCE=1
                shift
                ;;
            --bb-root)
                BB_ROOT="$2"
                shift 2
                ;;
            --generate-templates)
                GENERATE_TEMPLATES=1
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

    echo -e "${BOLD}backbone — Install to ${BB_ROOT}${NC}"
    echo -e "Source: ${GENERATOR_ROOT}"

    confirm_install

    if [[ "$DRY_RUN" -eq 1 ]]; then
        echo ""
        echo -e "  ${CYAN}[DRY-RUN mode — no files will be modified]${NC}"
    fi

    preserve_projects_json

    # ── Scripts ────────────────────────────────────────────────────
    section_header "Scripts"
    copy_tree "$GENERATOR_ROOT/scripts/lib"   "$BB_ROOT/scripts/lib"   "scripts/lib/"
    copy_tree "$GENERATOR_ROOT/scripts/hooks" "$BB_ROOT/scripts/hooks" "scripts/hooks/"
    for ext in sh py; do
        for f in "$GENERATOR_ROOT/scripts"/*.$ext; do
            [[ -f "$f" ]] || continue
            local name
            name=$(basename "$f")
            if [[ "$DRY_RUN" -eq 1 ]]; then
                FILES_COPIED=$((FILES_COPIED + 1))
                echo -e "  ${CYAN}[DRY-RUN] Would copy: $name${NC}"
            else
                mkdir -p "$BB_ROOT/scripts"
                cp "$f" "$BB_ROOT/scripts/$name"
                echo -e "  ${GREEN}✓ $name${NC}"
                FILES_COPIED=$((FILES_COPIED + 1))
            fi
        done
    done
    DIRS_COPIED=$((DIRS_COPIED + 1))

    # ── Skills ─────────────────────────────────────────────────────
    section_header "Skills"
    copy_tree "$GENERATOR_ROOT/backbone/skills" "$BB_ROOT/skills" "skills/"

    # ── Claude Code ─────────────────────────────────────────────────
    section_header "Claude Code"
    copy_tree "$GENERATOR_ROOT/.claude/agents"   "$BB_ROOT/claude/agents"   "agents/"
    copy_tree "$GENERATOR_ROOT/.claude/commands" "$BB_ROOT/claude/commands" "commands/"
    copy_tree "$GENERATOR_ROOT/.claude/hooks"    "$BB_ROOT/claude/hooks"    "hooks/"

    # ── OpenCode ────────────────────────────────────────────────────
    section_header "OpenCode"
    copy_tree "$GENERATOR_ROOT/.opencode/agents"  "$BB_ROOT/opencode/agents"  "agents/"
    copy_tree "$GENERATOR_ROOT/.opencode/plugins" "$BB_ROOT/opencode/plugins" "plugins/"

    # ── Templates ───────────────────────────────────────────────────
    if [[ "$GENERATE_TEMPLATES" -eq 1 ]]; then
        section_header "Templates"
        copy_tree "$GENERATOR_ROOT/templates" "$BB_ROOT/templates" "templates/"
    fi

    # ── Install marker + print summary ──────────────────────────────
    if [[ "$DRY_RUN" -eq 0 ]]; then
        echo "$(date +%Y-%m-%d)" > "$BB_ROOT/.installed"
    fi

    print_summary
}

main "$@"
