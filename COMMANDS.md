# Slash Commands Reference

The Agentic Backbone provides **12 slash commands** for common AI-assisted workflows.
Use them in Claude Code by typing `/backbone:<command>` at the prompt.

> Commands are available in any project initialized with the backbone.
> Source files: `.claude/commands/backbone/*.md`

---

## Feature Development Flow

The backbone replaces the traditional SDD workflow (Grill → PRD → Design → Plan → Implement → Verify → Ship) with **4 sequential commands**. Each command loads the right skills, enforces gates, and creates artifacts.

```
Step 1: /backbone:design <name>              <-- ONCE per feature
        └── Grill → EARS reqs → Proposal → Architecture → Design Doc → Traceability → Tasks
            G→P gate     R→D gate     D→I gate     P→T gate
        Use --plan for lightweight, --amend CHNG-XXX to amend

Step 2: /backbone:task [--quick]             <-- ONCE per task (N times)
        └── Loads layer skill → TDD cycle → REQ- tagging → Traceability update → Commit → Review
            I→V gate

Step 3: /backbone:review [--depth quick|standard|deep]
        └── Tests → Build → Security → Traceability → Docs

Step 4: /backbone:close [--ship|--release]   <-- ONCE when all tasks are done
        └── Audit REQ- IDs → Review suite → Code review → Ship/Release
```

**If an agent tries to skip steps**, the review gates block them with a message telling them to run the appropriate command:

| Gate | Blocks | Redirects To |
|------|--------|-------------|
| G→P | Writing proposal without grill evidence | `/backbone:design` |
| R→D | Writing design doc without proposal | `/backbone:design` |
| D→I | Writing code without design doc | `/backbone:design` |
| P→T | Marking tasks without planning doc | `/backbone:design` |
| I→V | Closing tasks without traceability | `/backbone:task` |

### Token Cost per Feature

| Command | Est. Cost | Run Count |
|---------|-----------|-----------|
| `design` | ~$0.15–0.25 | Once |
| `task` | ~$0.08–0.12 | Per task (2–3x typical) |
| `review` | ~$0.03–0.08 | Per task + before close |
| `close` | ~$0.03–0.05 | Once |
| **Total** | **~$0.30–$0.50** | Per feature |

---

## Quick Reference

| Command | What It Does | Best For |
|---------|--------------|----------|
| [`/backbone:help`](#backbonehelp) | List all available commands | Finding the right command |
| [`/backbone:design`](#backbonedesign) | End-to-end feature design: grill → EARS → proposal → architecture → design doc → tasks | Starting any new feature |
| [`/backbone:task`](#backbonetask) | Guide ONE task with TDD, layer skills, traceability | After design, for each implementation task |
| [`/backbone:review`](#backbonereview) | Full verification pipeline — tests, build, sync, security, traceability | Pre-commit, before release |
| [`/backbone:close`](#backboneclose) | Close out a feature — audit REQ-IDs, verify, suggest ship/release | After all tasks complete, before merge |
| [`/backbone:status`](#backbonestatus) | Task progress + project statistics | Starting a session, after completing a task |
| [`/backbone:decide`](#backbonedecide) | Record important decision → ADR | Choosing libraries, architecture, conventions |
| [`/backbone:map`](#backbonemap) | Architecture map — framework detection, C4 diagrams | Onboarding, refactoring |
| [`/backbone:qms`](#backboneqms) | Quality management — register NCR/CAPA, quality checks | Defects, nonconformances (disabled in light mode) |
| [`/backbone:cost`](#backbonecost) | Heuristic token usage estimate | After significant work, before committing |
| [`/backbone:sync`](#backbonesync) | Validate and sync SKILL.md files | After adding/editing skills |
| [`/backbone:debug`](#backbonedebug) | Structured debug session with persistent state | Investigating bugs, test failures, performance issues |

---

## Commands

### `/backbone:help`

List all available backbone commands with descriptions and key flags.

**When to use:** When you forget a command name or want to see available options.

**Output:** Formatted table of all commands with one-line descriptions and key flags.

---

### `/backbone:design`

**End-to-end feature design pipeline.** Orchestrates the complete SDD workflow from concept to actionable tasks.

**Arguments:** `/backbone:design <feature-name> [--plan] [--amend CHNG-XXX] [--light] [--deep]`

**Pipeline steps:**
| # | Step | Skill Used | Artifact |
|---|------|-----------|----------|
| 1 | Grill | `general/grill-me` + `general/grill-with-docs` | Clarified scope, `grilled: true` |
| 2 | Requirements | `general/ears-requirements` | REQ- IDs in EARS format |
| 3 | Proposal | `general/create-prd` | `backbone/artifacts/changes/CHNG-XXX/proposal.md` |
| 4 | Design Doc | `general/design-document` | `backbone/artifacts/changes/CHNG-XXX/design.md` |
| 5 | Tasks | `general/planning-and-task-breakdown` | `backbone/artifacts/changes/CHNG-XXX/tasks.md` + `3-TASKS.md` |

**Flags:**
- `--plan` — Lightweight planning only: skips grilling, architecture, deep design. Creates proposal.md + tasks.md without full ceremony.
- `--amend CHNG-XXX` — Amend an existing feature: reads target CHNG-XXX, grills on what changed, scaffolds CHNG-NNN with parent pointer, writes delta reqs/design/tasks with [AMEND] markers.
- `--light` — Override mode to light: minimal grill, advisory hooks, no QMS.
- `--deep` — Override mode to full: deep grilling with alternatives analysis, blocking hooks, always-on QMS.

**Mode behavior:**
| Mode | Grill Depth | Hooks | QMS |
|------|-------------|-------|-----|
| light | Minimal | Advisory (warn only) | Disabled |
| standard | Normal | Mixed | On serious issues |
| full | Deep + alternatives | Blocking | Always |

**When to use:** Starting any new feature. This is the recommended entry point for all non-trivial work.

**Source:** `.claude/commands/backbone/design.md`

---

### `/backbone:task`

Guide the implementation of a single task from 3-TASKS.md with the correct layer skills loaded.

**Arguments:** `/backbone:task [--quick] [--light] [--deep]`

**Auto-detects:**
- **Framework** from [`backbone/4-KNOWLEDGE.md`](backbone/4-KNOWLEDGE.md)
- **Layer** from task description (domain/app/infra keywords)
- **REQ- IDs** from the proposal doc

**Skills loaded per layer:**

| Layer | Framework Skill | Also Loads |
|-------|----------------|------------|
| `domain/` | `java/java-core` | `test-quality`, `coding-standards`, `incremental-implementation`, `git-commit`, `traceability` |
| `app/` | Framework CDI/patterns skill | Same |
| `infra/` | Framework REST/patterns skill | `jpa-patterns` (if DB), `outbox-pattern` (if messaging) |

**Workflow:**
1. Read task context from proposal + design docs
2. Load the right skills for the layer
3. TDD cycle: write test (red) → implement (green) → refactor
4. Tag code with REQ- ID comments
5. Update traceability matrix
6. Commit with REQ- IDs in message
7. Run `/backbone:review` to verify
8. Mark task [x] in 3-TASKS.md

**Flags:**
- `--quick` — Lightweight: skips deep verification, runs fast checks only.
- `--light` — Override mode to light: skip QMS checks.
- `--deep` — Override mode to full: extra validation, cross-file analysis.

**When to use:** After `/backbone:design` created the tasks. Run once per task.

**Source:** `.claude/commands/backbone/task.md`

---

### `/backbone:review`

Run the complete verification pipeline.

**Arguments:** `/backbone:review [--depth quick|standard|deep]`

**Depth levels:**
| Level | Duration | What It Checks |
|-------|----------|----------------|
| `quick` | ~2 min | Pattern matching, obvious issues |
| `standard` | ~5–15 min | Per-file analysis with language-specific checks |
| `deep` | ~15–30 min | Cross-file analysis, import graphs, layer violations |

**Verification steps:**
| # | Step | What Runs |
|---|------|-----------|
| 1 | Tests | `bats tests/bash/`, `pytest tests/python/`, `npm test` |
| 2 | Build | `npm run build` (dev-portal) |
| 3 | Template sync | `scripts/verify-template-sync.sh` |
| 4 | Security scans | `secret-scan.sh --staged`, `base64-scan.sh` |
| 5 | Hook parity | All hooks registered in settings |
| 6 | Skills lint | Frontmatter, line count, framework tags |
| 7 | STATE.md | Verify current with 3-TASKS.md |
| 8 | Traceability | REQ- IDs have code + tests |

**Mode behavior:**
| Mode | Depth Used | QMS |
|------|------------|-----|
| light | quick | Disabled |
| standard | standard | On serious issues |
| full | deep | Always |

**When to use:** Before committing, before release, after completing a task phase.

**Output:** Structured report with PASS/FAIL for each step.

**Source:** `.claude/commands/backbone/review.md`

---

### `/backbone:close`

Close out a feature branch — audit requirements, verify suite, code review, suggest ship/release.

**Arguments:** `/backbone:close [--ship] [--release]`

**Pipeline:**
| # | Step | What Happens |
|---|------|--------------|
| 1 | Collect REQ- IDs | Read proposal, extract all requirement IDs |
| 2 | Audit traceability | Check every REQ- ID has code + test |
| 3 | Gaps? | BLOCK if any REQ- ID is missing implementation or test |
| 4 | Verify suite | Run tests, build, template sync, security scan |
| 5 | Code review | Architecture, edge cases, naming, REQ- coverage |
| 6 | Report | Summary table + next-action suggestion |

**Flags:**
- `--ship` — Run ship checklist after successful close: version bump, changelog, tag, push.
- `--release` — Like --ship but also creates GitHub release.

**Output:**
```
✅ Feature close-out: <feature-name>
  Requirements: 12 total, 12 implemented, 11 tested
  Tests: 198 passing ✅ | Build: success ✅ | Sync: synced ✅
  Next: Run `/backbone:close --ship` to tag and release
```

**When to use:** After all feature tasks are [x], before merging.

**Source:** `.claude/commands/backbone/close.md`

---

### `/backbone:status`

Show project status and statistics.

**Arguments:** `/backbone:status [--progress] [--stats]`

**Flags:**
- `--progress` (default if no flag) — Show WIP tasks, milestones, blockers, recommended next action.
- `--stats` — Show project statistics: files, commits, coverage, template health.

**When to use:** Starting a new session ("What should I do next?"), after completing a task ("What's next?").

**Source:** `.claude/commands/backbone/status.md`

---

### `/backbone:decide`

Record an important architectural or technical decision.

**Arguments:** `/backbone:decide [--adr]`

**Workflow:**
1. Capture decision context and options considered
2. Document rationale and consequences
3. Create ADR in `backbone/reference/patterns/adr/`
4. Update [`backbone/5-DECISIONS.md`](backbone/5-DECISIONS.md) index

**Flags:**
- `--adr` — Create a formal ADR (Architecture Decision Record) with title, status, context, decision, consequences.

**When to use:** Choosing libraries, architecture patterns, conventions, or any non-obvious technical choice.

**Source:** `.claude/commands/backbone/decide.md`

---

### `/backbone:map`

Generate architecture documentation for the project.

**Arguments:** `/backbone:map [--reverse]`

**Flags:**
- `--reverse` — Reverse-engineer existing project: detect framework, generate C4 diagrams, create architecture map with framework/language/build tool/database/architecture. Creates `backbone/artifacts/changes/CODEBASE-INVENTORY.md`.

**Without `--reverse`:** Analyze project structure and generate architecture inventory in `backbone/artifacts/changes/CODEBASE-INVENTORY.md`.

**Analyzes:**
| Area | What It Finds |
|------|---------------|
| `templates/` | All project templates with framework coverage |
| `scripts/` | Automation scripts with test coverage |
| `backbone/skills/` | Skills inventory by category |
| `dev-portal/` | API routes and UI components |
| `.claude/` | Hooks, agents, commands |

**When to use:** Onboarding, refactoring, finding coverage gaps, documenting existing projects.

**Source:** `.claude/commands/backbone/map.md`

---

### `/backbone:qms`

Quality management system — register nonconformances and CAPAs.

**Arguments:** `/backbone:qms [--compact]`

**Mode behavior:**
| Mode | QMS Availability |
|------|-----------------|
| light | **Disabled** — command not available |
| standard | Available — warns on serious issues |
| full | Available — blocking on critical NCRs |

**Workflow:**
1. Prompts for severity/category/title/change
2. Validates change folder exists
3. Creates NCR record
4. Suggests CAPA and next steps

**Flags:**
- `--compact` — Inline summary instead of full interactive mode.

**When to use:** When a defect or nonconformance is found during development.

**Source:** `.claude/commands/backbone/qms.md`

---

### `/backbone:cost`

Log a heuristic cost estimate for the current session or task.

**Heuristic formula:**
```
base_tokens  = 15,000 × subagent_spawns
file_tokens  = 500 × files_read
tool_tokens  = 2,000 × tool_calls
input_tokens ≈ base + file + tool
output_tokens ≈ input × 0.25
cost_usd     = (input/1M × $3) + (output/1M × $15)  # Sonnet 4.6
```

**Example:** A multi-agent task with 3 subagents, 20 file reads, and 15 tool calls ≈ **$0.20–0.30**.

**⚠️ Flag threshold:** If session total exceeds $5.00, the command warns you to review efficiency.

**When to use:** After completing a multi-step task with subagents, before committing as part of DoD.

**Do NOT use for:** Exact billing (this is heuristic), micromanaging every tool call.

**Source:** `.claude/commands/backbone/cost.md`

---

### `/backbone:sync`

Validate and synchronize the skills directory.

**Checks:**
1. Every SKILL.md has required frontmatter (name, description, framework)
2. No SKILL.md exceeds 300 lines
3. Descriptions use third person (not "I...")
4. Framework tags match directory structure
5. Generates skills manifest for dev-portal

**Fixes applied:** Adds missing frontmatter, reports oversized skills, suggests splitting into reference files.

**When to use:** After adding or editing a skill, before committing.

**Source:** `.claude/commands/backbone/sync.md`

---

### `/backbone:debug`

Debug issues using the scientific method with persistent session state.

**Subcommands:**
| Command | What It Does |
|---------|--------------|
| `list` | Show all active debug sessions |
| `status <slug>` | Print summary of a session without spawning an agent |
| `continue <slug>` | Resume an existing debug session |
| `--diagnose` | Find root cause only, skip applying the fix |

**Session persistence:** Each session creates `backbone/debug/{slug}.md` with frontmatter (status, trigger, dates), current hypothesis, evidence log, eliminated hypotheses, and resolution.

**When to use:** Application bugs, test failures, performance issues, intermittent failures.

**Source:** `.claude/commands/backbone/debug.md`

---

## Backbone Modes Reference

Commands adapt behavior based on the current mode (stored in `backbone/.MODE`):

| Mode | When to Use | Hooks | Design Depth | QMS | Commands Affected |
|------|-------------|-------|--------------|-----|-------------------|
| **light** | Quick tasks, fixes, small changes | Advisory (warn only) | Minimal | Disabled | design, task, review, qms |
| **standard** | Normal development | Mixed | Normal | On serious issues | All |
| **full** (default) | High-stakes, architectural changes | Blocking | Deep grilling + alternatives | Always | All |

Override per command: `--light` or `--deep` flags on design, task, review commands.

---

*Last updated: 2026-05-26*