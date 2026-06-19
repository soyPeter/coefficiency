<!-- VERSION: 2026.05.29 -->
<!-- PURPOSE: Skills catalog, slash commands reference, specialized agents -->
# 9. AI Agent Skills (Standard Capabilities)

*This file defines the skills and operating procedures for AI Agents.*
*Active framework and tech stack are defined in [[`backbone/4-KNOWLEDGE.md`](backbone/4-KNOWLEDGE.md)](backbone/4-KNOWLEDGE.md).*

---

## Required Skills for Development

**ALL development tasks MUST load these skills before coding:**

```bash
view backbone/skills/general/coding-standards/SKILL.md
view backbone/skills/cross-cutting/code-quality/SKILL.md
view backbone/skills/cross-cutting/testing/test-quality/SKILL.md
```

These skills are loaded automatically when you start a development session. See [`backbone/3-TASKS.md`](backbone/3-TASKS.md) for task tracking.

---

<!-- SECTION:general -->
## Core Skills (Standard Operating Procedures)

### Skill 1: Git Commit Messages (`git-commit`)
**Goal:** Generate conventional, informative commit messages.

All commits MUST use Conventional Commits format:
```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:** `feat`, `fix`, `refactor`, `test`, `docs`, `perf`, `build`, `chore`

### Skill 2: Issue Triage (`issue-triage`)
**Goal:** Categorize and prioritize GitHub issues.

- Use labels appropriately
- Set priorities
- Add relevant metadata

### Skill 3: New Service (`new-service`)
**Goal:** Create new services following project conventions.

- Follow the service template structure
- Use the `new-service.sh` script

### Skill 4: Coding Standards (`coding-standards`)
**Goal:** Follow project coding conventions.

- Use framework-specific patterns
- Maintain consistent naming

### Skill 5: Build & Gradle (`build-gradle`)
**Goal:** Manage Gradle build configuration.

- Use version catalog
- Follow multi-project conventions

<!-- SECTION_END:general -->

---

## Mode System

backbone projects operate in one of three modes that adjust workflow strictness:

| Aspect | Light | Standard | Full |
|--------|-------|----------|------|
| Prompt length | Short & direct | Normal | Very detailed |
| Review gates | Advisory (warn) | Mixed | Blocking |
| QMS / NCR creation | Never | Serious issues only | Always |
| Documentation | TASKS only | Normal | Full bidirectional |
| Design depth | Lightweight | Normal | Deep + alternatives |
| `--deep` override | Can force full | Available | Default |

Mode is stored in `backbone/.MODE` and read by commands at runtime.
Use `--light` or `--deep` flags on design, task, review commands to override temporarily.

---

<!-- SECTION:commands -->
## Slash Commands

The following slash commands are available in Claude Code. Use them by typing `/backbone:<command>`.

### Command Reference

| Command | Description | When to Use |
|---------|-------------|-------------|
| `/backbone:help` | List all available commands | Getting started, command reference |
| `/backbone:design` | Full feature design — grill → EARS → proposal → design → tasks | Starting new features. Use `--plan` for lightweight, `--amend CHNG-XXX` to extend existing |
| `/backbone:task` | Execute ONE task with TDD cycle | Each [WIP] task. Use `--quick` for atomic commits without TDD |
| `/backbone:review` | Run verification suite | Pre-commit, CI. Use `--depth quick` for fast check, `--depth deep` for full audit |
| `/backbone:close` | Close feature when all tasks [x] | Feature completion. Use `--ship` to tag and push release |
| `/backbone:status` | Show project progress and stats | Status updates. Use `--progress` or `--stats` for specific views |
| `/backbone:decide` | Record important architectural decision | Choosing libraries, patterns. Use `--adr` to create formal ADR |
| `/backbone:map` | Generate architecture map | Onboarding, refactoring. Use `--reverse` for reverse-engineering existing code |
| `/backbone:qms` | Quality management — register NCR, compact stale entries | Issue tracking. Disabled in Light mode |
| `/backbone:compact` | Scan stale decisions and memory entries | Before feature close, periodic maintenance. Use `--dry-run` to preview |
| `/backbone:cost` | Log heuristic cost estimate to SESSION.md | After significant work |
| `/backbone:uat` | Conversational user acceptance testing | Post-implementation. Use `--resume` to continue interrupted session |
| `/backbone:sync` | Sync skills from generator to project | After backbone updates |
| `/backbone:push-clean` | Export clean project copy without AI scaffolding | Preparing production repo / handoff |
| `/backbone:debug` | Start structured debug session | Bug investigation (unchanged) |

### Command Details

**`/backbone:design`**
- Full feature design pipeline: grill → EARS reqs → proposal → design → tasks
- Runs `backbone-change-init.sh` to scaffold `backbone/artifacts/changes/CHNG-XXX/`
- Enforces all review gates (G→P, R→D, D→I) within the pipeline
- Writes proposal.md with frontmatter, problem statement, EARS requirements
- Writes design.md with C4 model, ADRs, API contracts, sequence diagrams
- Writes tasks.md with vertical slice breakdown, size tags, concrete verbs
- Initializes traceability matrix in `backbone/artifacts/traceability/`
- Flags: `--plan` (lightweight, skip grill + C4), `--amend CHNG-XXX` (delta from existing feature), `--skip-grill`, `--framework <fw>`, `--epic <M#>`, `--type <type>` (override domain classifier: api|layout|backend|config|workflow)
- Domain-aware grilling: auto-classifies feature type and selects focused question strategy (REQ-GRL-005)
- Mode-aware: light=mode skips grill, full=mode requires C4 + ADR

**`/backbone:task`**
- Guides ONE task with TDD cycle: red → green → refactor
- Reads proposal.md for REQ-IDs, design.md for architecture context
- Loads layer-specific skill (domain/app/infra) for conventions
- Tags code with REQ-ID comments for traceability
- Updates traceability matrix after every task
- Always writes tests first (unless using `--quick`)
- Flags: `--quick` (atomic, no TDD, commit directly), `--changelog <msg>`, `--parallel` (wave-based parallel execution), `--wave N` (execute single wave), `--interactive` (sequential with user checkpoints)
- Mode-aware: light=skip TDD + skill loading, full=mandatory code review after

**`/backbone:review`**
- Runs verification suite to validate project health
- Tests, lint, build, docs, security scan, template sync
- **Validates requirement traceability** — reads active change folder's proposal.md, extracts all REQ-IDs, checks traceability matrix for code + test coverage, reports gaps as a table
- Runs `verify-traceability.sh` and `extract-traceability.sh`
- Flags: `--depth quick` (tests + git status), `--depth standard` (full verify), `--depth deep` (verify + code review subagent + architecture audit)
- Mode-aware: default depth is quick in light, standard in normal, deep in full

**`/backbone:close`**
- Audits all REQ-IDs have code + tests (traceability gap report)
- Runs full verification suite (tests, build, security, template sync)
- Code review (layer violations, edge cases, REQ-ID coverage)
- Produces requirements coverage % summary table
- Flags: `--ship` or `--release` (version bump, tag, changelog), `--no-tag`
- Mode-aware: light=mark [x] only, full=REQ-ID audit + close report

**`/backbone:status`**
- Shows project progress from 3-TASKS.md
- Provides statistics (files, commits, coverage, issues)
- Flags: `--progress` (task completion view), `--stats` (project analytics), `--wide`

**`/backbone:decide`**
- Records an important decision with full context, alternatives, rationale
- Collects: context, options considered (min 2), chosen option, rationale, consequences
- Scaffolds a CHNG folder for traceability through the change lifecycle
- Creates an ADR file in `backbone/reference/patterns/adr/NNN-name.md`
- Updates `5-DECISIONS.md` decision log with a summary entry
- Flags: `--adr` (create formal ADR), `--supersedes D5,D8`
- Use when choosing libraries, architecture, conventions, or any expensive-to-reverse decision

**`/backbone:map`**
- Generates architecture map of the project
- Analyzes project structure, generates `CODEBASE-INVENTORY.md`
- Flags: `--reverse` (reverse-engineer existing project — detects framework, language, build tool, database, architecture pattern, generates C4 Context + Container diagrams, creates draft 4-KNOWLEDGE.md / 5-DECISIONS.md / 6-MEMORY.md)
- `--reverse --apply` writes reverse-engineer drafts to live backbone/ files

**`/backbone:qms`**
- Registers quality issues (NCR) with severity, category, title
- Validates input and runs `qms-register-issue.sh`
- Suggests CAPA creation for critical/major NCRs
- Flags: `--compact` (scans 5-DECISIONS.md for entries without status field, scans 6-MEMORY.md for entries without archive marker, presents candidates for review, applies superseded/archived markers)
- Disabled in Light mode
- `--compact --dry-run` previews without modifications

**`/backbone:compact`**
- Scans [`backbone/5-DECISIONS.md`](backbone/5-DECISIONS.md) and [`backbone/6-MEMORY.md`](backbone/6-MEMORY.md) for stale entries
- Decisions without `**Status:**` line → candidates for superseded marking
- Memory entries without `**[Archived:` prefix → candidates for archival
- Supports `--dry-run` to preview without modifications
- Interactive: asks for each candidate before applying changes
- Use before feature close or periodically to keep context lean

**`/backbone:push-clean`**
- Export a clean project copy for production deployment or handoff
- Strips backbone/, .claude/, AGENTS.md, templates/, hooks/ and pushes only runtime code
- Delegates to `scripts/push-clean.sh` for all file operations
- Creates tempdir → rsync with exclusions → secret scan → git init → commit → git bundle → (optional) git push
- Flags: `--remote URL`, `--branch NAME` (default: main), `--dry-run`

**`/backbone:debug`**
- Initializes debug session with scientific method
- Creates checkpoint in `backbone/debug/{slug}.md`
- Guides through hypothesis → experiment → validation

**`/backbone:cost`**
- Logs heuristic cost estimate to SESSION.md
- Tracks tokens, tool calls, files read for awareness
- Use after significant work

**`/backbone:sync`**
- Syncs skills from generator to project
- Use after generator updates to pull latest skills

**`/backbone:help`**
- Lists all available slash commands with one-liners
- Runs `ls .claude/commands/backbone/` to enumerate

**`/backbone:uat`**
- Conversational UAT — presents test scenarios one at a time for pass/fail assessment
- On failure: auto-diagnoses root cause, generates fix plans, offers gaps-only execution
- Creates session file at `backbone/artifacts/changes/CHNG-XXX/uat.md`
- Flags: `--resume` (continue interrupted session)

---

## Specialized Agents

The following agents are available for specific tasks. They are configured in `.claude/agents/`.

### Agent Reference

| Agent | Purpose | Trigger |
|-------|---------|---------|
| `backbone-developer` | General backbone development assistant | General development |
| `backbone-explorer` | Search codebase, find files/patterns | Need to locate something without reading entire files |
| `backbone-planner` | Create implementation plans from PRDs | Breaking down a complex task before coding |
| `backbone-implementer` | Implement ONE specific sub-task | Executing a single task from 3-TASKS.md |
| `backbone-reviewer` | Unified review: code, architecture, security, tests, templates | Before implementation (plan) and before commit (code) |
| `backbone-verifier` | Automated gates + adversarial audit | After implementation, before committing |
| `backbone-debugger` | Scientific debugging with checkpoint protocol | `/backbone:debug` or complex bugs |

### Agent Details

**`backbone-developer`**
- Default agent with comprehensive backbone knowledge
- Applies hexagonal architecture, framework conventions, worktrunk workflow
- Knows: Quarkus, Spring Boot, Laravel, Go, Python, Kotlin, Astro

**`backbone-explorer`**
- Search-only agent (fork=0, fresh context)
- Uses Grep and Glob, never edits files
- Returns structured file list with line numbers and context

**`backbone-planner`**
- Reads 4-KNOWLEDGE.md, 8-WORKFLOW.md, and framework conventions
- Produces structured plans with Skills, Files, Tests, Verification sections
- Plans are validated by backbone-reviewer before implementation

**`backbone-implementer`**
- Implements ONE specific sub-task with minimal changes
- Acknowledges required skills before writing code
- Uses Edit tool (not Write) unless creating new files
- Declares FILES: in prompt first line for conflict detection

**`backbone-reviewer`**
- Unified review agent replacing 5 previous agents (peer-reviewer, code-reviewer, architecture-checker, test-auditor, template-checker, security-auditor)
- Reviews plans before implementation and code after implementation
- Writes review report to `backbone/artifacts/reports/review-YYYY-MM-DD.md`

**`backbone-verifier`**
- Unified verification agent replacing validator + verifier + prd-checker
- Runs automated gates (build, tests, template sync, secret scan, hook parity, traceability)
- Performs adversarial audit (PRD validation, code review, template check, security scan)
- Writes verification report to `backbone/artifacts/reports/verification-YYYY-MM-DD.md`

**`backbone-debugger`**
- Uses scientific method: observe → hypothesize → experiment → validate
- Creates persistent debug checkpoints in `backbone/debug/{slug}.md`
- Handles complex, multi-session investigations with continue/resume support

---

## Database Skills

Skills for database work live in `backbone/skills/cross-cutting/databases/`.

| Skill | Description |
|-------|-------------|
| `postgres-patterns` | PostgreSQL patterns — query optimization, schema design, indexing |
| `query-optimization` | EXPLAIN analysis, indexes, performance tuning |
| `schema-design` | Table design, data types, constraints, advanced features |
| `database-migrations` | Schema changes, data migrations, rollbacks |

### Usage
```bash
view backbone/skills/cross-cutting/databases/postgres-patterns/SKILL.md
```
<!-- SECTION_END:database -->

---

## Framework Skills

Skills for your active framework live in `backbone/skills/<framework>/`.

Load the relevant skill with:
```bash
view backbone/skills/<framework>/<skill-name>/SKILL.md
```

See `backbone/4-KNOWLEDGE.md` for your project's active framework and tech stack.

---

## Security Skills

Skills for security work live in `backbone/skills/cross-cutting/security/`.

| Skill | Description |
|-------|-------------|
| `security-review` | Comprehensive security checklist and patterns |
| `prompt-injection-guard` | Prompt injection detection and prevention |
| `secret-scanning` | Secret detection in code and commits |

### Usage
```bash
view backbone/skills/cross-cutting/security/security-review/SKILL.md
```

---

## Skill Safety Check

Before loading ANY skill:
1. Read the first line of `SKILL.md`
2. Verify it says `<!-- FRAMEWORK: <YOUR_FRAMEWORK> -->` or `<!-- FRAMEWORK: GENERAL -->`
3. If missing or mismatched with your active framework, ask the user before loading

---

## Slash Commands Reference

Slash commands are AI-assisted workflows triggered via Claude Code. Grouped by workflow phase:

### 🎯 Planning & Discovery
| Command | Use Case |
|---------|----------|
| `/backbone:design` | **Full feature design** — runs `backbone-change-init.sh`, grills user (G→P), writes EARS reqs to proposal.md, writes ADRs to design.md, breaks into tasks.md, enforces all gates. Use `--plan` for lightweight, `--amend CHNG-XXX` for delta. Use for any new feature. |
| `/backbone:design --plan` | **Lightweight planning** — quick requirement gathering, writes proposal.md and tasks.md. Skips grilling, architecture, gates. Use for small features where full ceremony is overkill. |
| `/backbone:decide` | **Record important decision** — collects context, alternatives, rationale, consequences. Scaffolds CHNG folder, creates ADR in `backbone/reference/patterns/adr/`, updates `5-DECISIONS.md`. Use `--adr` to create formal ADR. |
| `/backbone:map` | **Architecture map** — analyze project structure, generate `CODEBASE-INVENTORY.md`. Use `--reverse` for reverse-engineering existing projects (detects framework/language/build tool/database, generates C4 diagrams, creates draft backbone metadata). |
| `/backbone:status` | **Project status** — reads 3-TASKS.md, shows milestones, WIP tasks, blockers. Use `--stats` for project analytics (files, commits, coverage). |

### 🛠️ Implementation
| Command | Use Case |
|---------|----------|
| `/backbone:task` | **Guide ONE task with TDD** — reads proposal.md (REQ-IDs) + design.md, loads correct layer skill, runs red→green→refactor, tags code with REQ-IDs, updates traceability, commits, runs review. Use `--quick` for atomic commits without TDD. Use for each [WIP] task. |
| `/backbone:close` | **Close feature** — audits all REQ-IDs have code + tests, runs verification, code review. Use `--ship` for version bump + tag + changelog. Use when all tasks [x]. |
| `/backbone:qms` | **Register quality issue (NCR)** — prompts for severity, category, title, and optional change link. Validates input, runs `qms-register-issue.sh`, prints next steps. Use `--compact` to scan for stale decisions/memory entries. Disabled in Light mode. |

### 🔬 Debugging
| Command | Use Case |
|---------|----------|
| `/backbone:debug` | **Structured debug** — observe → hypothesize → experiment → validate with checkpoints. Use for systematic debugging. |
| `/backbone:review --depth quick` | **Health check** — git, build, tests, services, QMS, backups. Use when something feels wrong. |

### ✅ Quality & Release
| Command | Use Case |
|---------|----------|
| `/backbone:review` | **Full verification with REQ-ID traceability** — tests, lint, build, docs, security scan, traceability (validates every REQ-ID in active change folder has code + tests), layer rules. Use `--depth deep` for code review subagent + architecture audit. Use before commit or release. |
| `/backbone:close --ship` | **Ship checklist** — QMS check (critical NCRs closed), tests pass, build passes, docs updated, version bumped, changelog appended. Prints go/no-go. |

### 🔧 Utilities
| Command | Use Case |
|---------|----------|
| `/backbone:cost` | **Track costs** — log heuristic token estimate to SESSION.md. Use after significant work. |
| `/backbone:push-clean` | **Export clean project copy** — strips AI scaffolding, pushes only runtime code to production repo. Use for deployment or handoff. |
| `/backbone:sync` | **Sync skills** — pull latest skills from generator. Use after generator updates. |
| `/backbone:help` | **List commands** — show all available slash commands with one-liners.

---

## Subagent Orchestration

The backbone supports parallel task execution with specialized subagents:

| Subagent | Purpose |
|----------|---------|
| `backbone-explorer` | Search codebase, find files/patterns (fork=0, fresh context) |
| `backbone-planner` | Create implementation plans from PRDs (fork=1) |
| `backbone-implementer` | Implement ONE specific sub-task (fork=1) |
| `backbone-reviewer` | Review plans and code: quality, security, architecture, tests (fork=1) |
| `backbone-verifier` | Run automated gates + adversarial audit (fork=1) |

**Handoff:** Each agent returns structured output (typed contracts). Main agent validates handoff before spawning next agent.

---

*To add framework-specific skill entries, update this file and add the corresponding skills under `backbone/skills/<framework>/`.*
