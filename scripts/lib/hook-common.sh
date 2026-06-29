#!/bin/bash
# =============================================================================
# scripts/lib/hook-common.sh — Shared functions for hook scripts
#
# Sources common patterns used across pre-tool-use, pre-commit, session-start
# and other hooks. Reduces duplication and ensures consistent behavior.
#
# Usage:
#   source "$(dirname "$0")/../lib/hook-common.sh"
#   FRAMEWORK=$(detect_framework "$PROJECT_DIR")
#   log_warn "Something is off"
# =============================================================================

# NOTE: No 'set -e' here — library meant to be sourced by hooks.
# Each function returns error codes that callers handle.

if [ -z "${HOOK_COMMON_LOADED:-}" ]; then
HOOK_COMMON_LOADED=1

# ── Color Output ────────────────────────────────────────────────────────────

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_warn()    { echo -e "${YELLOW}$*${NC}"; }
log_error()   { echo -e "${RED}$*${NC}"; }
log_success() { echo -e "${GREEN}$*${NC}"; }
log_info()    { echo -e "${BLUE}$*${NC}"; }

# ── Framework Detection ─────────────────────────────────────────────────────
# Detects framework from backbone/4-KNOWLEDGE.md
# Returns: lowercase framework name (quarkus, springboot, laravel, kotlin, golang, python)
# or empty string if not detected

detect_framework() {
    local project_dir="${1:-.}"
    local knowledge_file="$project_dir/backbone/4-KNOWLEDGE.md"
    local framework=""

    if [ -f "$knowledge_file" ]; then
        framework=$(grep -oiE 'quarkus|spring.?boot|laravel|kotlin|golang|python' "$knowledge_file" | head -1 || true)
    fi
    echo "$framework" | tr '[:upper:]' '[:lower:]'
}

# ── Framework+Language to Conventions File ──────────────────────────────────
# Maps framework name to conventions file path

framework_to_conventions() {
    local framework="$1"
    case "$(echo "$framework" | tr '[:upper:]' '[:lower:]')" in
        quarkus)     echo "backbone/reference/conventions/quarkus.md" ;;
        springboot)  echo "backbone/reference/conventions/springboot.md" ;;
        laravel)     echo "backbone/reference/conventions/laravel.md" ;;
        kotlin)      echo "backbone/reference/conventions/kotlin.md" ;;
        golang)      echo "backbone/reference/conventions/golang.md" ;;
        python)      echo "backbone/reference/conventions/python.md" ;;
        php)         echo "backbone/reference/conventions/php.md" ;;
        jooby)       echo "backbone/reference/conventions/jooby.md" ;;
        javalin)     echo "backbone/reference/conventions/javalin-desktop.md" ;;
        *)           echo "" ;;
    esac
}

# ── Stdin JSON Parsing (Claude Code hooks) ──────────────────────────────────
# Parses Claude Code PreToolUse/PostToolUse stdin JSON
# Returns the value for a given key path

read_claude_stdin() {
    cat
}

parse_tool_name() {
    local input="${1:-$(cat)}"
    echo "$input" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_name',''))" 2>/dev/null || true
}

parse_file_path() {
    local input="${1:-$(cat)}"
    echo "$input" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))" 2>/dev/null || true
}

parse_tool_input() {
    local input="${1:-$(cat)}"
    local key="$2"
    echo "$input" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('$key',''))" 2>/dev/null || true
}

# ── Exempt Task Type Detection ──────────────────────────────────────────────
# Returns 0 if the text looks like an exempt task type (fix/docs/refactor/etc.)

is_exempt_task() {
    local text="$1"
    echo "$text" | grep -qiE '(fix|bug|docs|refactor|clean|chore|test|perf|ci|build|style)' && return 0
    return 1
}

# ── ISO Date Validation ─────────────────────────────────────────────────────
# Returns 0 if date string is valid ISO 8601 format (YYYY-MM-DD)

validate_iso_date() {
    local date_str="$1"
    if echo "$date_str" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'; then
        local year="${date_str:0:4}"
        local month="${date_str:5:2}"
        local day="${date_str:8:2}"
        # Basic range check (not validating calendar days per month)
        [ "$year" -ge 2020 ] 2>/dev/null && \
        [ "$month" -ge 1 ] 2>/dev/null && [ "$month" -le 12 ] 2>/dev/null && \
        [ "$day" -ge 1 ] 2>/dev/null && [ "$day" -le 31 ] 2>/dev/null && return 0
    fi
    return 1
}

# ── Layer Detection ─────────────────────────────────────────────────────────
# Detects the architectural layer from a file path

detect_layer() {
    local file_path="$1"
    case "$file_path" in
        */domain/*|*/model/*|*/entity/*|*/vo/*|*/valueobject/*) echo "domain" ;;
        */app/*|*/application/*|*/usecase/*) echo "app" ;;
        */infra/*|*/infrastructure/*) echo "infra" ;;
        */api/*|*/controller/*|*/resource/*|*/rest/*|*/web/*|*/endpoint/*) echo "api" ;;
        *) echo "" ;;
    esac
}

# ── File Type Checks ────────────────────────────────────────────────────────

is_code_file() {
    local file="$1"
    [[ "$file" =~ \.(java|kt|go|py|js|ts|tsx|astro|rs|rb|php|c|cpp|h|hpp)$ ]]
}

is_doc_file() {
    local file="$1"
    [[ "$file" == *.md ]] || [[ "$file" == *README* ]]
}

fi # HOOK_COMMON_LOADED
