# bb-root.sh — Centralized path resolver for all backbone scripts
#
# Sets BB_ROOT, SCRIPT_DIR, and PROJECT_ROOT correctly whether running from
# ~/.backbone/scripts/ (centralized) or from a project-local scripts/ dir.
#
# Usage (in every backbone script):
#   source "${BASH_SOURCE[0]%/*}/../lib/bb-root.sh" 2>/dev/null \
#     || { SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#          PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
#          BB_ROOT="$PROJECT_ROOT"; }
#
# Design: D-BB-01 (git rev-parse over projects.json)
#          D-BB-03 (backward compatibility with standalone installations)

# Detect if we're in ~/.backbone/scripts/ (centralized install)
if [[ "$(uname)" == "Darwin" ]]; then
    _bb_script_realpath="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
else
    _bb_script_realpath="$(dirname "$(readlink -f "${BASH_SOURCE[1]}")" 2>/dev/null || cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
fi

if [[ "$_bb_script_realpath" == "$HOME/.backbone/scripts"* ]]; then
    # Centralized: running from ~/.backbone/scripts/
    BB_ROOT="$HOME/.backbone"
    SCRIPT_DIR="$BB_ROOT/scripts"

    # Override via --project-dir (REQ-BB-007)
    if [[ -n "${PROJECT_DIR:-}" ]]; then
        PROJECT_ROOT="$PROJECT_DIR"
    elif git rev-parse --show-toplevel &>/dev/null; then
        PROJECT_ROOT=$(git rev-parse --show-toplevel)
    else
        PROJECT_ROOT="$PWD"
    fi
else
    # Standalone: running from project-local scripts/
    SCRIPT_DIR="$_bb_script_realpath"
    PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
    BB_ROOT="$PROJECT_ROOT"
fi

unset _bb_script_realpath

# Source bb-tools.sh (SDK functions) if available
_bb_tools_file="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/bb-tools.sh"
if [[ -f "$_bb_tools_file" ]]; then
  source "$_bb_tools_file"
fi
unset _bb_tools_file
