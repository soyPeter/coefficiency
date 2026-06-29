# bb-tools.sh — Centralized workflow SDK for backbone commands
#
# Provides: bb_resolve_model, bb_generate_slug, bb_state_load,
#           bb_state_save, bb_config_get, bb_config_set, bb_topological_sort
#
# Usage:
#   source "${BASH_SOURCE[0]%/*}/bb-root.sh"
#   source "${BASH_SOURCE[0]%/*}/bb-tools.sh"
#
# Design: D54 (bb-tools.sh as sourceable library, not standalone CLI)

# ─── Helper: require bb-root.sh vars ───────────────────────────────────
_bb_require_root() {
  if [[ -z "${BB_ROOT:-}" ]]; then
    echo "bb-tools.sh ERROR: bb-root.sh must be sourced first" >&2
    return 1
  fi
  if [[ ! -f "$BB_ROOT/backbone/VERSION" ]]; then
    local _bb_fb
    _bb_fb=$(git rev-parse --show-toplevel 2>/dev/null || true)
    if [[ -n "$_bb_fb" && -d "$_bb_fb/backbone" ]]; then
      BB_ROOT="$_bb_fb"
    fi
  fi
}

# ─── bb_resolve_model ─────────────────────────────────────────────────
# Resolve model name from: $BB_MODEL env > backbone/.model > config default
bb_resolve_model() {
  _bb_require_root || return 1

  if [[ -n "${BB_MODEL:-}" ]]; then
    echo "$BB_MODEL"
    return 0
  fi

  local model_file="$BB_ROOT/backbone/.model"
  if [[ -f "$model_file" ]]; then
    head -1 "$model_file" | tr -d '[:space:]'
    return 0
  fi

  bb_config_get "model" 2>/dev/null && return 0
  echo "claude-sonnet-4-20250514"
}

# ─── bb_generate_slug ─────────────────────────────────────────────────
# Convert a human-readable title to a filesystem-safe slug
# Usage: bb_generate_slug "User auth fails on Safari"
#   -> "user-auth-fails-on-safari"
bb_generate_slug() {
  local title="$*"
  if [[ -z "$title" ]]; then
    echo "bb_generate_slug ERROR: title argument required" >&2
    return 1
  fi

  echo "$title" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-//; s/-$//' \
    | tr -s '-'
}

# ─── bb_state_load ────────────────────────────────────────────────────
# Load STATE.md into BB_STATE_* environment variables
# Sets: BB_STATE_PHASE, BB_STATE_WAVE, BB_STATE_TASK, BB_STATE_START, BB_STATE_UPDATED
bb_state_load() {
  _bb_require_root || return 1

  local state_file="$BB_ROOT/backbone/STATE.md"
  if [[ ! -f "$state_file" ]]; then
    BB_STATE_PHASE=""
    BB_STATE_WAVE=""
    BB_STATE_TASK=""
    BB_STATE_START=""
    BB_STATE_UPDATED=""
    return 0
  fi

  while IFS=': ' read -r key value; do
    case "$key" in
      current_phase) BB_STATE_PHASE="$value" ;;
      current_wave)  BB_STATE_WAVE="$value" ;;
      active_task)   BB_STATE_TASK="$value" ;;
      session_start) BB_STATE_START="$value" ;;
      last_updated)  BB_STATE_UPDATED="$value" ;;
    esac
  done < <(grep -E '^[a-z_]+:' "$state_file" 2>/dev/null || true)
}

# ─── bb_state_save ────────────────────────────────────────────────────
# Update STATE.md with key=value pairs
# Usage: bb_state_save "current_phase=implementation" "current_wave=2"
bb_state_save() {
  _bb_require_root || return 1

  local state_dir="$BB_ROOT/backbone"
  local state_file="$state_dir/STATE.md"

  mkdir -p "$state_dir"

  local now
  now="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%S)Z"

  if [[ ! -f "$state_file" ]]; then
    cat > "$state_file" << STATEEOF
# Backbone Session State
# Auto-managed by bb-tools.sh — do not edit manually

current_phase:
current_wave:
active_task:
session_start: $now
last_updated: $now
STATEEOF
  fi

  for pair in "$@"; do
    local key="${pair%%=*}"
    local val="${pair#*=}"
    if grep -qE "^$key:" "$state_file" 2>/dev/null; then
      sed_i "s/^$key:.*/$key: $val/" "$state_file"
    else
      echo "$key: $val" >> "$state_file"
    fi
  done

  sed_i "s/^last_updated:.*/last_updated: $now/" "$state_file"
}

# ─── bb_config_get ────────────────────────────────────────────────────
# Read a config value from backbone/.sdk-config
bb_config_get() {
  _bb_require_root || return 1

  local key="$1"
  local config_file="$BB_ROOT/backbone/.sdk-config"

  if [[ ! -f "$config_file" ]]; then
    return 1
  fi

  grep -E "^${key}=" "$config_file" 2>/dev/null | tail -1 | cut -d= -f2- || return 1
}

# ─── bb_config_set ────────────────────────────────────────────────────
# Write a config value to backbone/.sdk-config
bb_config_set() {
  _bb_require_root || return 1

  local key="$1"
  local val="$2"
  local config_file="$BB_ROOT/backbone/.sdk-config"

  mkdir -p "$BB_ROOT/backbone"

  if [[ ! -f "$config_file" ]]; then
    cat > "$config_file" << CONFIGEOF
# Backbone SDK Configuration
# Auto-generated — edit values as needed
model=claude-sonnet-4-20250514
default_subagents=3
parallel_max=4
CONFIGEOF
  fi

  if grep -qE "^${key}=" "$config_file" 2>/dev/null; then
    sed_i "s|^${key}=.*|${key}=${val}|" "$config_file"
  else
    echo "${key}=${val}" >> "$config_file"
  fi
}

# ─── sed_i (cross-platform inline sed) ─────────────────────────────────
# Reuse from cross-platform.sh if available, otherwise minimal inline
sed_i() {
  if command -v sed &>/dev/null; then
    if [[ "$(uname)" == "Darwin" ]]; then
      sed -i '' "$@"
    else
      sed -i "$@"
    fi
  fi
}

# ─── bb_topological_sort ──────────────────────────────────────────────
# Analyze tasks.md files in a change folder and assign wave numbers
# Reads Depends-on: fields to build dependency DAG
# Usage: bb_topological_sort <chng-folder-path>
# Output: tab-separated: task_id \t wave_number \t title
bb_topological_sort() {
  _bb_require_root || return 1

  local chng_dir="$1"
  if [[ -z "$chng_dir" || ! -d "$chng_dir" ]]; then
    echo "bb_topological_sort ERROR: valid change directory required" >&2
    return 1
  fi

  local tasks_file="$chng_dir/tasks.md"
  if [[ ! -f "$tasks_file" ]]; then
    echo "bb_topological_sort ERROR: no tasks.md found in $chng_dir" >&2
    return 1
  fi

  # Parse task entries: extract ID, title, and Depends-on
  # Format:
  # - [ ] [S] Add foo() to bar (REQ-XXX)
  #   **Depends-on:** REQ-YYY

  local tmpdir
  tmpdir="$(mktemp -d 2>/dev/null || mktemp -d -t bbsort)"
  local tasks_tmp="$tmpdir/tasks.txt"
  local deps_tmp="$tmpdir/deps.txt"

  # Extract task IDs and their titles
  grep -nE '^\s*-\s*\[' "$tasks_file" > "$tmpdir/task_lines.txt" 2>/dev/null || true

  # Build task list and adjacency
  while IFS= read -r line; do
    local line_num="${line%%:*}"
    local rest="${line#*:}"

    # Extract task ID from first [ ] line's parenthetical or heading context
    local task_id=""
    local title=""
    if echo "$rest" | grep -qE 'CHNG-[0-9]+-T[0-9]+'; then
      task_id=$(echo "$rest" | grep -oE 'CHNG-[0-9]+-T[0-9]+' | head -1)
    fi

    title=$(echo "$rest" | sed 's/.*\] //; s/ ([A-Z-]*)$//; s/^[[:space:]]*//')

    if [[ -z "$title" ]]; then
      continue
    fi

    echo -e "${task_id:-T$line_num}\t$title" >> "$tasks_tmp"

    # Find Depends-on within 5 lines after this task
    local after_start=$((line_num + 1))
    local after_end=$((line_num + 5))
    local dep_lines
    dep_lines=$(sed -n "${after_start},${after_end}p" "$tasks_file" 2>/dev/null || true)
    local dep
    dep=$(echo "$dep_lines" | grep -oE 'Depends-on: [A-Z0-9_-]+' | head -1 | cut -d' ' -f2- || true)
    if [[ -n "$dep" && "$dep" != "none" ]]; then
      local task_ref="${task_id:-T$line_num}"
      echo -e "$task_ref\t$dep" >> "$deps_tmp"
    fi
  done < "$tmpdir/task_lines.txt"

  if [[ ! -f "$tasks_tmp" ]]; then
    rm -rf "$tmpdir"
    echo "bb_topological_sort: no tasks found" >&2
    return 0
  fi

  # Kahn's algorithm for topological sort
  # Assign wave 1 to tasks with no deps, wave N to tasks whose deps are in waves < N
  local wave_assign="$tmpdir/waves.txt"
  local all_ids
  all_ids=$(cut -f1 "$tasks_tmp" 2>/dev/null || true)

  # First pass: wave 1 = no dependencies
  while IFS=$'\t' read -r tid ttl; do
    local has_dep=""
    if [[ -f "$deps_tmp" ]]; then
      has_dep=$(grep -E "^${tid}\t" "$deps_tmp" 2>/dev/null || true)
    fi
    if [[ -z "$has_dep" ]]; then
      echo -e "$tid\t1\t$ttl" >> "$wave_assign"
    fi
  done < "$tasks_tmp"

  # Second pass: remaining tasks get wave = max(dep wave) + 1
  local remaining
  remaining=$(grep -v -f <(cut -f1 "$wave_assign" 2>/dev/null || true) "$tasks_tmp" 2>/dev/null || true)
  if [[ -n "$remaining" ]]; then
    echo "$remaining" | while IFS=$'\t' read -r tid ttl; do
      local dep_id
      dep_id=$(grep -E "^${tid}\t" "$deps_tmp" 2>/dev/null | cut -f2 || true)
      local dep_wave=0
      if [[ -n "$dep_id" ]]; then
        dep_wave=$(grep -E "^${dep_id}\t" "$wave_assign" 2>/dev/null | cut -f2 || echo "0")
      fi
      local wave=$((dep_wave + 1))
      echo -e "$tid\t$wave\t$ttl" >> "$wave_assign"
    done
  fi

  # Sort by wave then task ID
  sort -t$'\t' -k2,2n -k1,1 "$wave_assign" 2>/dev/null || cat "$wave_assign"

  rm -rf "$tmpdir"
}
