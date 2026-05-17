#!/usr/bin/env bash
#<!-- VERSION: 2026.04.25 -->
# Prompt Injection Scanner — Standalone CLI Tool
# Usage:
#   scripts/prompt-injection-scan.sh --diff origin/main   # CI mode: scan changed files
#   scripts/prompt-injection-scan.sh --file path/to/file   # Scan a single file
#   scripts/prompt-injection-scan.sh --dir agents/          # Scan all files in a directory
#   scripts/prompt-injection-scan.sh --stdin               # Read file list from stdin
#
# Exit codes:
#   0 = clean
#   1 = findings detected
#   2 = usage error

set -euo pipefail

# ─── Patterns ────────────────────────────────────────────────────────────────
# 22 patterns across 5 categories. Each is a POSIX extended regex.
# Keep alphabetized by category.

PATTERNS=(
  # Category 1: Instruction override
  'ignore[[:space:]]+(all[[:space:]]+)?(previous|prior|above|earlier|preceding)[[:space:]]+(instructions|prompts|rules|directives|context)'
  'disregard[[:space:]]+(all[[:space:]]+)?(previous|prior|above)[[:space:]]+(instructions|prompts|rules)'
  'forget[[:space:]]+(all[[:space:]]+)?(previous|prior|above)[[:space:]]+(instructions|prompts|rules|context)'
  'override[[:space:]]+(all[[:space:]]+)?(system|previous|safety)[[:space:]]+(instructions|prompts|rules|checks|filters|guards)'
  'override[[:space:]]+(system|safety|security)[[:space:]]'

  # Category 2: Role manipulation
  'you[[:space:]]+are[[:space:]]+now[[:space:]]+(a|an|my)[[:space:]]'
  'from[[:space:]]+now[[:space:]]+on[[:space:]]+(you|pretend|act|behave)'
  'pretend[[:space:]]+(you[[:space:]]+are|to[[:space:]]+be)[[:space:]]'
  'act[[:space:]]+as[[:space:]]+(a|an|if|my)[[:space:]]'
  'roleplay[[:space:]]+as[[:space:]]'
  'assume[[:space:]]+the[[:space:]]+role[[:space:]]+of[[:space:]]'

  # Category 3: System prompt extraction
  'output[[:space:]]+(your|the)[[:space:]]+(system[[:space:]]+)?(prompt|instructions)'
  'reveal[[:space:]]+(your|the)[[:space:]]+(system[[:space:]]+)?(prompt|instructions)'
  'show[[:space:]]+me[[:space:]]+(your|the)[[:space:]]+(system[[:space:]]+)?(prompt|instructions)'
  'print[[:space:]]+(your|the)[[:space:]]+(system[[:space:]]+)?(prompt|instructions)'
  'what[[:space:]]+(is|are)[[:space:]]+(your|the)[[:space:]]+(system[[:space:]]+)?(prompt|instructions)'
  'repeat[[:space:]]+(your|the|all)[[:space:]]+(system[[:space:]]+)?(prompt|instructions|rules)'

  # Category 4: Fake message boundaries
  '</?system>'
  '</?assistant>'
  '</?human>'
  '\[SYSTEM\]'
  '\[/SYSTEM\]'
  '\[INST\]'
  '\[/INST\]'
  '<<SYS>>'
  '<</SYS>>'

  # Category 5: Jailbreak / DAN patterns
  'do[[:space:]]+anything[[:space:]]+now'
  'DAN[[:space:]]+mode'
  'developer[[:space:]]+mode[[:space:]]+(enabled|output|activated)'
  'jailbreak'
  'bypass[[:space:]]+(safety|content|security)[[:space:]]+(filter|check|rule|guard)'
)

# ─── Allowlist ───────────────────────────────────────────────────────────────
# Files that legitimately discuss injection patterns (security docs, tests, hooks)
ALLOWLIST=(
  'scripts/prompt-injection-scan.sh'
  'scripts/secret-scan.sh'
  'scripts/base64-scan.sh'
  '.claude/hooks/pre-tool-use-injection-guard.sh'
  '.claude/hooks/post-tool-use-injection-scan.sh'
  'backbone/prd/20260425-gsd-harvest.md'
  'backbone/prd/20260429-gsd-integration.md'
  'SECURITY.md'
)

is_allowlisted() {
  local file="$1"
  for allowed in "${ALLOWLIST[@]}"; do
    if [[ "$file" == *"$allowed" ]]; then
      return 0
    fi
  done
  return 1
}

# ─── File Collection ─────────────────────────────────────────────────────────

collect_files() {
  local mode="$1"
  shift

  case "$mode" in
    --diff)
      local base="${1:-origin/main}"
      git diff --name-only --diff-filter=ACMR "$base"...HEAD 2>/dev/null \
        | grep -E '\.(md|cjs|js|json|yml|yaml|sh|ts|tsx|py|java|kt)$' || true
      ;;
    --file)
      if [[ -f "$1" ]]; then
        echo "$1"
      else
        echo "Error: file not found: $1" >&2
        exit 2
      fi
      ;;
    --dir)
      local dir="$1"
      if [[ ! -d "$dir" ]]; then
        echo "Error: directory not found: $dir" >&2
        exit 2
      fi
      find "$dir" -type f \( \
        -name '*.md' -o -name '*.cjs' -o -name '*.js' -o -name '*.ts' -o -name '*.tsx' \
        -o -name '*.json' -o -name '*.yml' -o -name '*.yaml' -o -name '*.sh' \
        -o -name '*.py' -o -name '*.java' -o -name '*.kt' \
      \) ! -path '*/node_modules/*' ! -path '*/.git/*' ! -path '*/dist/*' ! -path '*/build/*' 2>/dev/null || true
      ;;
    --stdin)
      cat
      ;;
    *)
      echo "Usage: $0 --diff [base] | --file <path> | --dir <path> | --stdin" >&2
      exit 2
      ;;
  esac
}

# ─── Scanner ─────────────────────────────────────────────────────────────────

scan_file() {
  local file="$1"
  local found=0

  if is_allowlisted "$file"; then
    return 0
  fi

  for pattern in "${PATTERNS[@]}"; do
    local matches
    matches=$(grep -inE -e "$pattern" "$file" 2>/dev/null || true)
    if [[ -n "$matches" ]]; then
      if [[ $found -eq 0 ]]; then
        echo "FAIL: $file"
        found=1
      fi
      echo "$matches" | while IFS= read -r line; do
        echo "  $line"
      done
    fi
  done

  # Check for invisible Unicode
  local unicode_matches
  unicode_matches=$(grep -n $'[\u200B\u200C\u200D\uFEFF\u2028\u2029]' "$file" 2>/dev/null || true)
  if [[ -n "$unicode_matches" ]]; then
    if [[ $found -eq 0 ]]; then
      echo "FAIL: $file"
      found=1
    fi
    echo "$unicode_matches" | while IFS= read -r line; do
      echo "  [INVISIBLE-UNICODE] $line"
    done
  fi

  return $found
}

# ─── Main ────────────────────────────────────────────────────────────────────

main() {
  if [[ $# -eq 0 ]]; then
    echo "Usage: $0 --diff [base] | --file <path> | --dir <path> | --stdin" >&2
    exit 2
  fi

  local mode="$1"
  shift

  local files
  files=$(collect_files "$mode" "$@")

  if [[ -z "$files" ]]; then
    echo "prompt-injection-scan: no files to scan"
    exit 0
  fi

  local total=0
  local failed=0

  while IFS= read -r file; do
    [[ -z "$file" ]] && continue
    total=$((total + 1))
    if ! scan_file "$file"; then
      failed=$((failed + 1))
    fi
  done <<< "$files"

  echo ""
  echo "prompt-injection-scan: scanned $total files, $failed with findings"

  if [[ $failed -gt 0 ]]; then
    exit 1
  fi
  exit 0
}

main "$@"
