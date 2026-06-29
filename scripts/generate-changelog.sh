#!/bin/bash
# scripts/generate-changelog.sh — Generate a changelog from conventional commits
#
# Reads git log from the last tag (or from beginning) to HEAD and produces
# a Keep a Changelog format entry grouped by type.
#
# Usage:
#   ./scripts/generate-changelog.sh               # last tag → HEAD
#   ./scripts/generate-changelog.sh v1.0.0         # specific tag → HEAD
#   ./scripts/generate-changelog.sh v1.0.0 v2.0.0  # range
#
# Output: prints changelog entry to stdout

set -euo pipefail

LAST_TAG=""
END_REF="HEAD"

if [ $# -ge 2 ]; then
    LAST_TAG="$1"
    END_REF="$2"
elif [ $# -eq 1 ]; then
    LAST_TAG="$1"
elif [ $# -eq 0 ]; then
    # Find the most recent tag
    LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
fi

if [ -z "$LAST_TAG" ]; then
    RANGE=""
    SINCE_LABEL="beginning"
else
    RANGE="${LAST_TAG}..${END_REF}"
    SINCE_LABEL="${LAST_TAG}"
fi

echo "# Changelog"
echo ""
echo "## [Unreleased] - $(date +%Y-%m-%d)"
echo ""
echo "### Added"
git log ${RANGE:+$RANGE} --oneline --grep="^feat" --format="- %s" 2>/dev/null || echo "- (none)"

echo ""
echo "### Fixed"
git log ${RANGE:+$RANGE} --oneline --grep="^fix" --format="- %s" 2>/dev/null || echo "- (none)"

echo ""
echo "### Changed"
git log ${RANGE:+$RANGE} --oneline --grep="^refactor\|^perf" --format="- %s" 2>/dev/null || echo "- (none)"

echo ""
echo "### Documentation"
git log ${RANGE:+$RANGE} --oneline --grep="^docs" --format="- %s" 2>/dev/null || echo "- (none)"

echo ""
echo "### Chore"
git log ${RANGE:+$RANGE} --oneline --grep="^chore\|^test\|^build\|^ci" --format="- %s" 2>/dev/null || echo "- (none)"

echo ""
echo "---"
echo "_Generated from commits since ${SINCE_LABEL}_"
