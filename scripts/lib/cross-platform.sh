#!/bin/bash
# =============================================================================
# scripts/lib/cross-platform.sh — Cross-platform shell utilities
# =============================================================================
# Source this file in other scripts:
#   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#   source "$SCRIPT_DIR/lib/cross-platform.sh"
# =============================================================================

# Detect OS type
os_type() {
    case "$OSTYPE" in
        darwin*) echo "macos" ;;
        linux*)  echo "linux" ;;
        *)       echo "unknown" ;;
    esac
}

# Cross-platform sed -i wrapper
# Usage: sed_i 's/old/new/g' file.txt
sed_i() {
    local pattern="$1"
    local file="$2"
    if [ ! -f "$file" ]; then
        echo "Error: File not found: $file" >&2
        return 1
    fi
    if [ "$(os_type)" = "macos" ]; then
        sed -i '' "$pattern" "$file"
    else
        sed -i "$pattern" "$file"
    fi
}

# Check required dependencies
# Usage: check_deps git bash sed
# Optional deps are checked with warning only
check_deps() {
    local missing=()
    local optional_missing=()
    for dep in "$@"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            case "$dep" in
                python3|openssl)
                    optional_missing+=("$dep")
                    ;;
                *)
                    missing+=("$dep")
                    ;;
            esac
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        echo "Error: Required dependencies missing: ${missing[*]}" >&2
        return 1
    fi

    if [ ${#optional_missing[@]} -gt 0 ]; then
        echo "Warning: Optional dependencies missing: ${optional_missing[*]}" >&2
        echo "         Some features may use fallback methods." >&2
    fi
}

# Generate a random lowercase alphabetic service name
# Fallback chain: python3 → openssl rand → /dev/urandom → date
generate_random_service_name() {
    local length="${1:-8}"
    if command -v python3 >/dev/null 2>&1; then
        python3 -c "import random, string; print(''.join(random.choices(string.ascii_lowercase, k=$length)))"
    elif command -v openssl >/dev/null 2>&1; then
        openssl rand -base64 32 | tr -dc 'a-z' | head -c "$length"
    elif [ -r /dev/urandom ]; then
        LC_ALL=C tr -dc 'a-z' < /dev/urandom | head -c "$length"
    else
        # Ultimate fallback: use date + process id
        printf '%s%x' "svc" "$(date +%s%N | tail -c 7)"
    fi
}

# Validate that no template placeholders remain in a file
# Usage: validate_placeholders file1 file2 ...
validate_placeholders() {
    local leaked=0
    for file in "$@"; do
        if [ ! -f "$file" ]; then
            continue
        fi
        local matches
        # Check for placeholders that SHOULD be replaced.
        # Exclude __SERVICES_LIST__ and __SERVICES_CONFIG__ — these are intentionally
        # left in settings.gradle.kts for later service additions.
        matches=$(grep -nE '__(FRAMEWORK|BUILD_TOOL|PACKAGE|PROJECT_NAME)__' "$file" 2>/dev/null || true)
        if [ -n "$matches" ]; then
            echo "Error: Unreplaced placeholders found in $file:" >&2
            echo "$matches" | sed 's/^/  /' >&2
            leaked=1
        fi
    done
    return "$leaked"
}

# Print colored output helpers (safe for both macOS and Linux)
# Usage: color_red; echo "Error message"; color_reset
color_red()    { printf '\033[0;31m'; }
color_green()  { printf '\033[0;32m'; }
color_yellow() { printf '\033[1;33m'; }
color_blue()   { printf '\033[0;34m'; }
color_cyan()   { printf '\033[0;36m'; }
color_reset()  { printf '\033[0m'; }
