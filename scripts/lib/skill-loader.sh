#!/bin/bash
# scripts/lib/skill-loader.sh — Auto-discover and load skills per command
#
# Scans the project's backbone/skills/ directory and loads skills
# appropriate to the command being run and the project's framework.
#
# Usage:
#   source scripts/lib/skill-loader.sh
#   get_skills_for_command "design-feature"   # lists skills to load
#   get_skills_for_command "implement-task"
#
# This is sourced by the Step 0 loader in each command's process.

if [ -z "${SKILL_LOADER_LOADED:-}" ]; then
SKILL_LOADER_LOADED=1

SKILLS_DIR="${SKILLS_DIR:-backbone/skills}"

# ── Discover available skills ──────────────────────────────────────────────
# Returns all SKILL.md paths relative to backbone/skills/

list_available_skills() {
    find "$SKILLS_DIR" -name "SKILL.md" -type f 2>/dev/null | \
        sed "s|$SKILLS_DIR/||; s|/SKILL\.md||" | sort -u || true
}

# ── Framework detection ────────────────────────────────────────────────────

detect_framework() {
    local knowledge_file="${1:-backbone/4-KNOWLEDGE.md}"
    if [ -f "$knowledge_file" ]; then
        grep -oiE 'quarkus|spring.?boot|laravel|kotlin|golang|python|javalin' "$knowledge_file" | head -1 | tr '[:upper:]' '[:lower:]'
    fi
}

# ── Command → skill category mapping ───────────────────────────────────────
# Each command has a set of keywords that match skill names.
# The loader scans available skills and loads those whose name contains
# any of the command's keywords.

declare -A COMMAND_SKILL_KEYWORDS

# design-feature skills: planning, design, requirements, architecture, risk analysis
COMMAND_SKILL_KEYWORDS["design-feature"]="spec-driven-development|create-prd|grill|planning|design-document|documentation-and-adrs|traceability|ears-requirements|source-driven-development|context-engineering|idea-refine|domain-driven-design|software-architectures|api-design|pre-mortem"

# amend-feature skills: similar to design-feature but focused on delta
COMMAND_SKILL_KEYWORDS["amend-feature"]="grill|ears-requirements|design-document|planning|traceability|source-driven-development|context-engineering"

# implement-task skills: coding, testing, quality, patterns, debugging
COMMAND_SKILL_KEYWORDS["implement-task"]="coding-standards|incremental-implementation|test-quality|code-simplification|code-review-and-quality|security-and-hardening|security-fixes|performance-optimization|source-driven-development|frontend-ui-engineering|context-engineering|mandatory-checks|ci-cd-and-automation|api-and-interface-design|debugging-and-error-recovery|test-scenarios|manage-adr"

# decision skills: documentation, ADRs, planning
COMMAND_SKILL_KEYWORDS["decision"]="documentation-and-adrs|planning|ears-requirements|source-driven-development"

# quick skills: coding standards, git, incremental
COMMAND_SKILL_KEYWORDS["quick"]="coding-standards|git-commit|incremental-implementation"

# close-feature skills: code review, quality, retro
COMMAND_SKILL_KEYWORDS["close-feature"]="code-review-and-quality|retro"

# register-issue skills: issue tracking, debugging, TDD
COMMAND_SKILL_KEYWORDS["register-issue"]="to-issues|issue-triage|idea-refine|debugging-and-error-recovery|test-driven-development"

# All remaining commands get git-commit as a minimum
COMMAND_SKILL_KEYWORDS["default"]="git-commit|coding-standards"

# ── Framework → cross-cutting skill mapping ───────────────────────────────

get_cross_cutting_skills() {
    local framework="$1"
    case "$framework" in
        quarkus|springboot|javalin)
            echo "databases/postgres-patterns|databases/database-migrations|docker/docker-patterns|testing/test-quality"
            ;;
        laravel)
            echo "databases/postgres-patterns|databases/database-migrations|backend/api-design"
            ;;
        golang|python|kotlin)
            echo "databases/postgres-patterns|testing/test-quality"
            ;;
        *)
            echo ""  # no cross-cutting skills
            ;;
    esac
}

# ── Main: Get skills for a command ─────────────────────────────────────────
# Scans available skills and returns those matching the command's keywords

get_skills_for_command() {
    local command_name="$1"
    local keywords="${COMMAND_SKILL_KEYWORDS[$command_name]:-${COMMAND_SKILL_KEYWORDS[default]}}"
    
    list_available_skills | grep -iE "$keywords" || true
}

# ── Generate view commands ─────────────────────────────────────────────────

generate_skill_views() {
    local command_name="$1"
    local project_dir="${2:-.}"
    
    # 1. Get general skills for this command
    local general_skills
    general_skills=$(SKILLS_DIR="$project_dir/backbone/skills" get_skills_for_command "$command_name")
    
    for skill in $general_skills; do
        echo "view $project_dir/backbone/skills/$skill/SKILL.md"
    done
    
    # 2. Get cross-cutting skills for the project's framework
    local framework
    framework=$(detect_framework "$project_dir/backbone/4-KNOWLEDGE.md")
    if [ -n "$framework" ]; then
        local cc_patterns
        cc_patterns=$(get_cross_cutting_skills "$framework")
        if [ -n "$cc_patterns" ]; then
            local cc_skills
            cc_skills=$(SKILLS_DIR="$project_dir/backbone/skills" list_available_skills | grep -iE "$cc_patterns" || true)
            for skill in $cc_skills; do
                echo "view $project_dir/backbone/skills/$skill/SKILL.md"
            done
        fi
    fi
}

fi # SKILL_LOADER_LOADED
