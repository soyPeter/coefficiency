#!/bin/bash
# scripts/review-package.sh — Generate a review package for subagent handoffs
#
# Creates a temp file with git log + diff stat + full diff for a commit range,
# prints the file path. This keeps diffs out of the orchestrator's context.
#
# Usage:
#   ./scripts/review-package.sh BASE_SHA HEAD_SHA
#   ./scripts/review-package.sh HEAD~1 HEAD   # last commit
#
# Output: prints path to temp file containing the review package.
# The file is auto-cleaned on next boot but persists for the session.

set -euo pipefail

if [[ $# -lt 2 ]]; then
    echo "Usage: $0 BASE_SHA HEAD_SHA" >&2
    echo "  BASE_SHA  — Starting commit (e.g., HEAD~1 or merge-base)" >&2
    echo "  HEAD_SHA  — Ending commit (e.g., HEAD)" >&2
    exit 1
fi

BASE_SHA="$1"
HEAD_SHA="$2"

TMPDIR="${TMPDIR:-/tmp}"
PACKAGE_FILE="$TMPDIR/review-package-$(date +%s).md"

{
    echo "# Review Package: ${BASE_SHA}..${HEAD_SHA}"
    echo ""
    echo "## Commit Log"
    echo '```'
    git log --oneline "${BASE_SHA}..${HEAD_SHA}" 2>/dev/null || echo "(empty range)"
    echo '```'
    echo ""
    echo "## Diff Stat"
    echo '```'
    git diff --stat "${BASE_SHA}..${HEAD_SHA}" 2>/dev/null || echo "(no changes)"
    echo '```'
    echo ""
    echo "## Full Diff"
    echo '```diff'
    git diff -U10 "${BASE_SHA}..${HEAD_SHA}" 2>/dev/null || echo "(no changes)"
    echo '```'
} > "$PACKAGE_FILE"

echo "$PACKAGE_FILE"
