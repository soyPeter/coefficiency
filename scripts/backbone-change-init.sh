#!/bin/bash
# scripts/backbone-change-init.sh — Scaffold a structured change folder
#
# Creates backbone/artifacts/changes/CHNG-XXX-<name>/ with proposal.md, design.md,
# tasks.md, and .gitkeep. Validates CHNG-ID uniqueness.
#
# Usage:
#   ./scripts/backbone-change-init.sh my-change-name
#   ./scripts/backbone-change-init.sh "My Change Name"
#   ./scripts/backbone-change-init.sh CHNG-001 my-change-name
#
# Without CHNG-XXX, auto-assigns next available ID. The change name is
# used as the folder slug. Spaces in the name are converted to hyphens
# and lowercased.

set -euo pipefail
if [[ -f "$HOME/.backbone/scripts/lib/bb-root.sh" ]]; then
    source "$HOME/.backbone/scripts/lib/bb-root.sh"
else
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
    BB_ROOT="$PROJECT_ROOT"
fi
CHANGES_DIR="$PROJECT_ROOT/backbone/artifacts/changes"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

show_help() {
    cat << 'EOF'
Usage: backbone-change-init.sh [--parent CHNG-XXX] [CHNG-XXX] <change-name>

Scaffold a structured change folder in backbone/artifacts/changes/.

Arguments:
  --parent CHNG-XXX Links as amendment to an existing change
  CHNG-XXX          Optional — auto-assigns next ID if omitted
  change-name       Short descriptive name (used as folder slug)

Examples:
  backbone-change-init.sh change-management               # auto: CHNG-001
  backbone-change-init.sh "Refactor Auth Module"          # auto: CHNG-002
  backbone-change-init.sh CHNG-010 my-change              # explicit ID
  backbone-change-init.sh --parent CHNG-005 tweak-scope   # amendment
EOF
}

slugify() {
    echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g; s/[^a-z0-9_-]//g'
}

next_chng_id() {
    local max_num=0
    local dir
    for dir in "$CHANGES_DIR"/CHNG-*/ "$CHANGES_DIR/archive"/CHNG-*/; do
        if [[ -d "$dir" ]]; then
            local basename
            basename="$(basename "$dir")"
            local num="${basename#CHNG-}"
            num="${num%%-*}"
            if [[ "$num" =~ ^[0-9]+$ ]]; then
                if (( 10#$num > max_num )); then
                    max_num=$((10#$num))
                fi
            fi
        fi
    done
    local next_num=$((max_num + 1))
    printf "CHNG-%03d" "$next_num"
}

validate_chng_id() {
    local id="$1"
    if ! [[ "$id" =~ ^CHNG-[0-9]{3}$ ]]; then
        echo -e "${RED}❌ Invalid change ID: $id${NC}" >&2
        echo -e "${YELLOW}Expected format: CHNG-XXX (e.g., CHNG-001)${NC}" >&2
        exit 1
    fi

    local dir
    for dir in "$CHANGES_DIR"/"$id"-*/; do
        if [[ -d "$dir" ]]; then
            echo -e "${RED}❌ Change ID $id already exists: $dir${NC}" >&2
            exit 1
        fi
    done

    for dir in "$CHANGES_DIR/archive"/"$id"-*/; do
        if [[ -d "$dir" ]]; then
            echo -e "${YELLOW}⚠️  Change ID $id found in archive: $dir${NC}" >&2
            echo -e "${YELLOW}   Use a new ID to avoid confusion.${NC}" >&2
            exit 1
        fi
    done
}

main() {
    if [[ $# -lt 1 ]]; then
        show_help
        exit 1
    fi

    local chng_id
    local change_name
    local parent_id=""

    # Parse --parent flag
    if [[ "$1" == "--parent" ]]; then
        parent_id="$2"
        if [[ ! "$parent_id" =~ ^CHNG-[0-9]{3}$ ]]; then
            echo -e "${RED}❌ Invalid parent ID: $parent_id${NC}" >&2
            echo -e "${YELLOW}Expected format: CHNG-XXX (e.g., CHNG-005)${NC}" >&2
            exit 1
        fi
        # Check parent exists
        local parent_found=0
        for d in "$CHANGES_DIR"/"$parent_id"-*/; do
            if [[ -d "$d" ]]; then parent_found=1; break; fi
        done
        if [[ "$parent_found" -eq 0 ]]; then
            echo -e "${RED}❌ Parent $parent_id not found in backbone/artifacts/changes/${NC}" >&2
            exit 1
        fi
        shift 2
    fi

    if [[ $# -lt 1 ]]; then
        echo -e "${RED}❌ Missing change name${NC}" >&2
        show_help
        exit 1
    fi

    if [[ "$1" =~ ^CHNG-[0-9]{3}$ ]]; then
        chng_id="$1"
        shift
        change_name="$*"
        validate_chng_id "$chng_id"
    else
        chng_id="$(next_chng_id)"
        change_name="$*"
    fi

    local slug
    slug="$(slugify "$change_name")"

    local change_dir="$CHANGES_DIR/$chng_id-$slug"
    mkdir -p "$change_dir"

    if [ -n "$parent_id" ]; then
        cat > "$change_dir/proposal.md" << PROPOSAL_EOF
# $chng_id: $change_name

parent: $parent_id

**What:** <!-- Delta description — what changed vs parent -->

**Why:** <!-- Why parent scope needed amendment -->

**Scope:** <!-- Additional files affected beyond parent -->

## Requirements

<!-- Delta EARS — use parent REQ-IDs with decimal notation:
     REQ-PARENT-001.1 = modified requirement from parent
     REQ-PARENT-0NN  = new requirement
-->

PROPOSAL_EOF
    else
        cat > "$change_dir/proposal.md" << PROPOSAL_EOF
# $chng_id: $change_name

**What:** <!-- One-line description of what this change does -->

**Why:** <!-- Business or technical justification -->

**Scope:** <!-- Files and directories affected -->

## Requirements

<!-- EARS syntax bullets:
- **REQ-XXX** When <trigger>, the system shall <response>.
- **REQ-XXX** While <state>, the system shall <response>.

### Acceptance Criteria
- **AC-REQ-XXX.N:** When <condition>, the system shall <expected behavior>.
-->

PROPOSAL_EOF
    else
        cat > "$change_dir/proposal.md" << PROPOSAL_EOF
# $chng_id: $change_name

**What:** <!-- One-line description of what this change does -->

**Why:** <!-- Business or technical justification -->

**Scope:** <!-- Files and directories affected -->

## Requirements

<!-- EARS syntax bullets:
- **REQ-XXX** When <trigger>, the system shall <response>.
- **REQ-XXX** While <state>, the system shall <response>.

### Acceptance Criteria
- **AC-REQ-XXX.N:** When <condition>, the system shall <expected behavior>.
-->

PROPOSAL_EOF
    fi

    # Write header with variable expansion, then append static C4 template
    echo "# $chng_id: Design — $change_name" > "$change_dir/design.md"
    cat >> "$change_dir/design.md" << 'DESIGN_EOF'

## Decisions

<!-- Key architectural or design decisions with tradeoffs -->

## Data Model

<!-- Any new data structures, schemas, or interfaces -->

## Interfaces

<!-- API endpoints, function signatures, or integration contracts -->

## C4 Model

### Context (Level 1)
<!-- Describe the system boundary, external actors, and key relationships.
     Replace placeholders below with your actual architecture. -->

```mermaid
flowchart LR
  %% Context diagram placeholders
  User[User Role] -->|interacts with| System[System Name]
  ExternalSystem[External System] -->|integrates with| System
  System -->|depends on| ExternalService[External Service]
```

```
[User Role] ──→ [System Name]
[External System] ──→ [System Name]
[System Name] ──→ [External Service]
```

### Container (Level 2)
<!-- Describe the high-level containers (apps, databases, services).
     Replace placeholders below with your actual architecture. -->

```mermaid
flowchart LR
  %% Container diagram placeholders
  WebApp[Web Application] -->|HTTP| API[API Gateway]
  API -->|queries| DB[(Database)]
  API -->|events| Queue[Message Queue]
```

```
[Web Application] ──HTTP──→ [API Gateway]
[API Gateway] ────→ [(Database)]
[API Gateway] ────→ [Message Queue]
```

### Component (Level 3)
<!-- Describe components inside a specific container.
     Replace placeholders below with your actual architecture. -->

```mermaid
flowchart LR
  %% Component diagram placeholders
  Controller[API Controller] -->|validates| Service[Service Layer]
  Service -->|maps| Repository[Repository]
  Repository -->|queries| DataSource[(Data Source)]
```

```
[API Controller] ──→ [Service Layer] ──→ [Repository] ──→ [(Data Source)]
```

## Files

<!-- Files to create or modify with brief description of each change -->

DESIGN_EOF

    if [ -n "$parent_id" ]; then
        cat > "$change_dir/tasks.md" << TASKS_EOF
# $chng_id: Tasks — Amendment to $parent_id

## Granularity Rules
- ONE file per task — never create multiple files in one task
- ONE method per task — never add logic to multiple methods
- ONE endpoint/route per task — never batch routes
- ONE query per task — never batch repository methods
- ONE test scenario per task — never test multiple modes in one task
- Size tags: [XS] single item, [S] method/query/test, [M] complex orchestration
- Concrete verbs only: add, fix, remove, configure, validate, create, update, extract, refactor
- NO vague verbs: implement, build, develop, do, make, setup
- NO "and" in task titles — if you use "and", split into multiple tasks
- NO [L] — if anything seems [L], split further
- **NO PLACEHOLDERS (REQ-GRP-002):** Every step must contain complete code, exact file paths, exact commands with expected output. No "TODO", "TBD", "add validation", "handle errors", "similar to" — write the actual content.
- **COMPLETE CODE (REQ-GRP-003):** Every implementation step must show the actual code to write, not describe it.

## Tasks

### Phase 1: <!-- name -->

## [ ] <!-- single file creation, single method, single endpoint, single query, or single test scenario -->
**Parent:** $parent_id
**Size:** [XS]

## [ ] <!-- another single unit of work -->
**Parent:** $parent_id
**Size:** [S]

<!-- Add more tasks as needed. Each task = ONE thing. No placeholders. Complete code. -->

TASKS_EOF
    else
        cat > "$change_dir/tasks.md" << TASKS_EOF
# $chng_id: Tasks

## Granularity Rules
- ONE file per task — never create multiple files in one task
- ONE method per task — never add logic to multiple methods
- ONE endpoint/route per task — never batch routes
- ONE query per task — never batch repository methods
- ONE test scenario per task — never test multiple modes in one task
- Size tags: [XS] single item, [S] method/query/test, [M] complex orchestration
- Concrete verbs only: add, fix, remove, configure, validate, create, update, extract, refactor
- NO vague verbs: implement, build, develop, do, make, setup
- NO "and" in task titles — if you use "and", split into multiple tasks
- NO [L] — if anything seems [L], split further
- **NO PLACEHOLDERS (REQ-GRP-002):** Every step must contain complete code, exact file paths, exact commands with expected output. No "TODO", "TBD", "add validation", "handle errors", "similar to" — write the actual content.
- **COMPLETE CODE (REQ-GRP-003):** Every implementation step must show the actual code to write, not describe it.

## Example Tasks (remove and replace)

\`\`\`
GOOD:  [XS] Add KillSwitchState enum to killswitch/model/
GOOD:  [XS] Add KillSwitchEntry record to killswitch/model/
GOOD:  [S]  Add KillSwitchCommand record with validation to killswitch/model/
GOOD:  [XS] Add POST /killswitch/halt endpoint to KillSwitchController
GOOD:  [XS] Add POST /killswitch/restart endpoint to KillSwitchController
GOOD:  [S]  Create KillSwitchRepository with insert() query
GOOD:  [S]  Create KillSwitchRepository with findActive() query
GOOD:  [S]  Test KillSwitch cache expiry (TIMED mode) in KillSwitchCacheTest
GOOD:  [S]  Test KillSwitch cache expiry (UNTIL_DATE mode) in KillSwitchCacheTest

BAD:   Create KillSwitchState enum and KillSwitchEntry record
       ^ "and" — split into 2 tasks
BAD:   Add controller with POST /halt and POST /restart
       ^ "and" — split into 1 class task + 2 endpoint tasks
BAD:   Implement caching for killswitch
       ^ vague verb "implement" — use concrete verb
\`\`\`

## Tasks

### Phase 1: <!-- name -->

## [ ] <!-- first task — ONE file or ONE method or ONE endpoint or ONE query or ONE test scenario -->
**Parent:** REQ-CHNG-XXX
**Size:** [XS]

## [ ] <!-- second task — another single unit of work -->
**Parent:** REQ-CHNG-XXX
**Size:** [S]

<!-- Add more tasks as needed. Each task = ONE thing. No "and". No vague verbs. -->

TASKS_EOF
    fi

    # ── Decision Log (REQ-DLOG-001) ─────────────────────────────────────
    cat > "$change_dir/decisions.md" << DECISION_EOF
# $chng_id: Decision Log

Record every meaningful decision made during implementation, including auto-decided choices.

## Format

| # | Topic | Decision | Rationale | Alternatives | Type |
|---|-------|----------|-----------|--------------|------|
| 1 | <!-- What was decided --> | <!-- The choice --> | <!-- Why --> | <!-- What else was considered --> | auto | human |

- **Type:** \`auto\` = two-way door, cheap to reverse | \`human\` = one-way door, expensive to unwind
- Record decisions as they happen, not at the end

## Decisions

| # | Topic | Decision | Rationale | Alternatives | Type |
|---|-------|----------|-----------|--------------|------|

DECISION_EOF

    # ── Ensure durable progress ledger directory ─────────────────────────
    mkdir -p "$PROJECT_ROOT/.backbone/ledger"

    touch "$change_dir/.gitkeep"

    # ── Update Changes Index ─────────────────────────────────────────────
    local index_file="$CHANGES_DIR/INDEX.md"
    if [ ! -f "$index_file" ]; then
        cat > "$index_file" << INDEX_EOF
# Changes Index

Auto-generated index of all changes (active and archived).
Active changes are in [\`backbone/artifacts/changes/CHNG-*/\`](backbone/artifacts/changes/CHNG-*/).
Archived changes are in [\`backbone/artifacts/changes/archive/CHNG-*\`](backbone/artifacts/changes/archive/CHNG-*).

| ID | Title | Status | Archived | Location |
|----|-------|--------|----------|----------|
INDEX_EOF
    fi

    local today
    today=$(date +%Y-%m-%d)
    # Add or update index entry (update if already exists, append if new)
    local active_line="| $chng_id | [$change_name]($chng_id-$slug/) | Active | — | [\`$chng_id-$slug/\`]($chng_id-$slug/) |"
    if grep -q "^| $chng_id |" "$index_file" 2>/dev/null; then
        sed -i '' "s/^| $chng_id |.*/$active_line/" "$index_file"
    else
        echo "$active_line" >> "$index_file"
    fi

    echo -e "${GREEN}✅ Created: $change_dir${NC}"
    echo ""
    echo "  Files:"
    echo "    proposal.md   — What/Why/Scope with EARS requirements"
    echo "    design.md     — How (decisions, data model, interfaces)"
    echo "    tasks.md      — Task breakdown with REQ traceability"
    echo "    decisions.md  — Decision log (auto/human, rationale, alternatives)"
    echo "    .gitkeep"
    echo ""
    echo -e "${CYAN}Next steps:${NC}"
    if [ -n "$parent_id" ]; then
        echo "  1. Write delta EARS in proposal.md (use parent REQ-IDs with decimal notation)"
        echo "  2. Document changed architecture decisions in design.md"
        echo "  3. Add delta tasks in tasks.md with [AMEND: $parent_id] markers"
        echo "  4. Mark tasks as [WIP] and implement"
    else
        echo "  1. Edit proposal.md with EARS requirements (**REQ-XXX** bullets)"
        echo "  2. Write design.md with implementation approach"
        echo "  3. Break work into granular tasks in tasks.md (no placeholders, complete code)"
        echo "  4. Record decisions in decisions.md as you go (auto/human type)"
        echo "  5. Mark tasks as [WIP] and start implementing"
    fi
    echo ""
    echo -e "${YELLOW}Tip: Use --parent CHNG-XXX to link as a delta. Omit CHNG-XXX to auto-assign ID.${NC}"
}

main "$@"
