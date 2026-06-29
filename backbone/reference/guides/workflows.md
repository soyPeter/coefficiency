# Common Workflows

Quick reference for everyday tasks using backbone commands.

---

## Create a New Project

```bash
# From the agentic-backbone generator
./scripts/init-project.sh my-app -f quarkus

# Options:
#   -f, --framework    quarkus, springboot, laravel, golang, python, kotlin
#   --frontend         Include React/Next.js frontend skills
#   --database         postgres, mysql, mongodb
#   --mode             light, standard, full (default)
./scripts/init-project.sh my-api -f springboot --database postgres
```

Scaffolds a complete project with backbone docs, `.claude/` agents + commands + hooks,
`.opencode/` plugins + commands, and framework-specific code scaffold.

---

## Update an Existing Project

```bash
# Update a single project
./scripts/update-backbone.sh --project-dir /path/to/project

# Update all registered projects
./scripts/update-backbone.sh --all-known

# Register a project for future updates
./scripts/update-backbone.sh --register /path/to/project
```

What it syncs: agents, commands, hooks, settings, skills, reference docs, scripts,
OpenCode plugins + commands, `.MODE`, root `AGENTS.md` and `CLAUDE.md`.
Preserves user content: `3-TASKS.md`, `4-KNOWLEDGE.md`, `5-DECISIONS.md`, `6-MEMORY.md`.

---

## Start a New Feature

```bash
# Claude Code
/backbone:design my-feature-name

# OpenCode
/backbone-design my-feature-name
```

What happens: scaffold CHNG folder → grill (one question at a time, 5 branches) → write proposal with EARS → design with ADRs → tasks with vertical slices → update 3-TASKS.md.

**Flags:** `--plan` (skip grill), `--skip-grill` (if already discussed), `--deep` (mandatory C4 + ADR)

**Worktree (recommended for features):** After design, create an isolated branch:

```bash
# Feature — branches from dev, merges to dev
./scripts/worktrunk.sh create feat/my-feature

# Hotfix — branches from main, auto-backports to dev after merge
./scripts/worktrunk.sh create hotfix/payment-error

cd ../<project>-feat-my-feature
# Launch agent session here for implementation
```

Branch naming controls the base:
- `feat/*`, `refactor/*`, `chore/*` → dev
- `hotfix/*`, `fix/*`, `security/*` → main (auto-backported to dev)

Use `--base` to override: `./scripts/worktrunk.sh create --base main feat/urgent-fix`

---

## Amend an Existing Feature

When a new change is a delta of an existing one (e.g., bug fix, scope tweak):

```bash
# Claude Code
/backbone:design --amend CHNG-027 fix-file-picker

# OpenCode
/backbone-design --amend CHNG-027 fix-file-picker

# Script (both agents)
./scripts/backbone-change-init.sh --parent CHNG-027 fix-file-picker
```

What happens: creates `CHNG-028-fix-file-picker/` with `parent: CHNG-027` in proposal.md. Write only delta requirements (REQ-027-001.1 = modified) and delta tasks with `[AMEND: CHNG-027]` markers.

**No grill needed** for small fixes — skip with `--skip-grill`. Full amendment flow also reads parent context, validates the target is not archived.

---

## Quick Fix (No New Change Folder)

For trivial fixes that don't need a separate change folder:

1. Find the [WIP] task in [`backbone/3-TASKS.md`](backbone/3-TASKS.md)
2. Edit the code
3. Add REQ- IDs in code comments if traceability exists

```bash
# Claude Code
/backbone:task --quick

# OpenCode
/backbone-task
```

Skips TDD, skill checks, planning gates. Commit directly.

---

## Execute a Task (Full TDD)

```bash
# Claude Code
/backbone:task

# OpenCode
/backbone-task
```

Reads `backbone/.MODE`:
- `full` (default): TDD (red → green → refactor) + mandatory code review
- `standard`: TDD cycle
- `light`: Skip TDD, commit directly

---

## Review Changes Before Commit

```bash
# Claude Code
/backbone:review --depth quick    # tests + git status
/backbone:review --depth standard # full verify suite
/backbone:review --depth deep     # + code review subagent

# OpenCode
/backbone-review                  # defaults to MODE depth
```

Reports written to `backbone/artifacts/reports/review-YYYY-MM-DD.md` and `backbone/artifacts/reports/verification-YYYY-MM-DD.md`.

---

## Close a Feature

```bash
# Claude Code
/backbone:close

# OpenCode
/backbone-close

# Script
# Verify all REQ-IDs have code + tests in traceability
# Mark all tasks [x] in 3-TASKS.md
# If in a worktree: cd to parent repo and merge
#   cd <parent-repo> && ./scripts/worktrunk.sh merge <branch-name>
#   (hotfixes auto-backport to dev after merging to main)
# Run ./scripts/backbone-change-archive.sh CHNG-NNN
```

If you created a worktree for this feature, the close command will detect it
and merge back to the appropriate base branch:
- `feat/*` → merged to `dev`
- `hotfix/*` → merged to `main`, then backported to `dev`

---

## Status

```bash
# Claude Code
/backbone:status

# Script
# Read backbone/3-TASKS.md for [WIP] tasks
# Check git status
```

---

## Decide (Record an ADR)

```bash
# Claude Code
/backbone:decide

# Script
cat >> backbone/5-DECISIONS.md << 'EOF'
### YYYY-MM-DD: Title
**Context:** ...
**Decision:** ...
**Alternatives:** ...
**Why:** ...
EOF
```

---

## Debug

```bash
# Claude Code
/backbone:debug

# Manual
# Scientific method: observe → hypothesize → experiment → validate
# Checkpoints saved to backbone/debug/{slug}.md
```

---

## QMS — Report a Nonconformance

```bash
# All agents
./scripts/qms-register-issue.sh --title "..." --severity major --category code

# Claude Code
/backbone:qms bug-description --severity major --category code
```

---

## Feature Comparison: Claude Code vs OpenCode

| Task | Claude Code | OpenCode |
|------|-------------|----------|
| Full design | `/backbone:design` | `/backbone-design` |
| Light design | `/backbone:design --plan` | `/backbone-design --plan` |
| Amendment | `/backbone:design --amend CHNG-XXX` | `/backbone-design --amend CHNG-XXX` |
| Execute task | `/backbone:task` | `/backbone-task` |
| Quick task | `/backbone:task --quick` | `/backbone-task --quick` |
| Loop task | `/backbone:task --loop 30m --goal "tests pass"` | `/backbone-task --loop 30m --goal "tests pass"` |
| Review | `/backbone:review` | `/backbone-review` |
| Deep review | `/backbone:review --depth deep` | `/backbone-review --depth deep` |
| Close feature | `/backbone:close` | `/backbone-close` |
| Ship release | `/backbone:close --ship` | `/backbone-ship` |
| Status | `/backbone:status` | `/backbone-status` |
| Debug | `/backbone:debug` | `/backbone-debug` |
| Decide (ADR) | `/backbone:decide` | `/backbone-decide` |
| Help | `/backbone:help` | `/backbone-help` |
| Map architecture | `/backbone:map` | `/backbone-map` |
| Reverse engineer | `/backbone:reverse-engineer` | `/backbone-reverse-engineer` |
| Cost track | `/backbone:cost` | `/backbone-cost` |
| QMS | `/backbone:qms` | `/backbone-qms` |
| Compact | `/backbone:compact` | `/backbone-compact` |
| Sync skills | `/backbone:sync` | `/backbone-sync` |
| Push clean | `/backbone:push-clean` | `/backbone-push-clean` |
| Progress | `/backbone:progress` | `/backbone-progress` |
| Stats | `/backbone:stats` | `/backbone-stats` |

All 33 Claude Code commands now have OpenCode equivalents in `.opencode/commands/`.
Deprecated commands (plan, verify, quick, health, etc.) redirect to their active replacements.
