# Slash Commands Reference

The Agentic Backbone provides **16 slash commands** for common AI-assisted workflows.
Use them in Claude Code by typing `/backbone:<command>` at the prompt.

> Commands are available in any project initialized with the backbone.
> Source files: `.claude/commands/backbone/*.md`

---

## Feature Development Flow

The backbone replaces the traditional SDD workflow (Grill → PRD → Design → Plan → Implement → Verify → Ship) with **5 sequential commands**. Each command loads the right skills, enforces gates, and creates artifacts.

```
Step 1: /backbone:design-feature <name>          <-- ONCE per feature
        └── Grill → EARS reqs → PRD → Architecture → Design Doc → Traceability → Plan
            G→P gate     R→D gate     D→I gate     P→T gate

Step 2: /backbone:implement-task [--task <id>]   <-- ONCE per task (N times)
        └── Loads layer skill → TDD cycle → REQ- tagging → Traceability update → Commit
            I→V gate

Step 3: /backbone:close-feature                   <-- ONCE when all tasks are done
        └── Audit REQ- IDs → Verify suite → Code review → Suggest /backbone:ship

Step 4: /backbone:ship                            <-- ONCE for release
        └── Tests → Build → Security → Changelog → Tag → Push
```

**If an agent tries to skip steps**, the review gates block them with a message telling them to run the appropriate command:

| Gate | Blocks | Redirects To |
|------|--------|-------------|
| G→P | Writing PRD without grill evidence | `/backbone:design-feature` |
| R→D | Writing design doc without PRD | `/backbone:design-feature` |
| D→I | Writing code without design doc | `/backbone:design-feature` |
| P→T | Marking tasks without planning doc | `/backbone:design-feature` |
| I→V | Closing tasks without traceability | `/backbone:implement-task` |

### Token Cost per Feature

| Command | Est. Cost | Run Count |
|---------|-----------|-----------|
| `design-feature` | ~$0.15–0.25 | Once |
| `implement-task` | ~$0.08–0.12 | Per task (2–3x typical) |
| `close-feature` | ~$0.05–0.08 | Once |
| **Total** | **~$0.30–$0.50** | Per feature |

---

## Quick Reference

| Command | What It Does | Best For |
|---------|--------------|----------|
| [`/backbone:design-feature`](#backbonedesign-feature) | End-to-end feature design: grill → EARS → PRD → architecture → design doc → plan | Starting any new feature |
| [`/backbone:implement-task`](#backboneimplement-task) | Guide ONE task with TDD, layer skills, traceability | After design-feature, for each implementation task |
| [`/backbone:close-feature`](#backboneclose-feature) | Audit REQ- IDs, verify suite, code review, suggest ship | After all tasks complete, before merge |
| [`/backbone:health`](#backbonehealth) | Full project diagnostic — template sync, tests, hooks, skills, secrets | Before major changes, troubleshooting |
| [`/backbone:quick`](#backbonequick) | Execute a small ad-hoc task without full planning | Fixing typos, updating a template, small refactors |
| [`/backbone:stats`](#backbonestats) | Project statistics — files, commits, templates, skills | Reporting, health checks |
| [`/backbone:debug`](#backbonedebug) | Structured debug session with persistent state | Investigating bugs, test failures, performance issues |
| [`/backbone:code-review`](#backbonecode-review) | Code review with severity-classified findings | Before committing, before PR |
| [`/backbone:verify`](#backboneverify) | Full verification pipeline — tests, build, sync, security | Pre-commit, CI pipeline |
| [`/backbone:progress`](#backboneprogress) | Task progress + recommended next action | Starting a session, after completing a task |
| [`/backbone:plan`](#backboneplan) | Create PRD → implementation plan → task breakdown | Starting a new feature |
| [`/backbone:map-codebase`](#backbonemap-codebase) | Architecture map — templates, scripts, skills | Onboarding, refactoring, finding gaps |
| [`/backbone:ship`](#backboneship) | Release checklist — tests → build → security → tag | Before tagging or deploying |
| [`/backbone:sync-skills`](#backbonesync-skills) | Validate SKILL.md files and regenerate manifest | After adding/editing skills |
| [`/backbone:push-clean`](#backbonepush-clean) | Export clean project copy without agent scaffolding | Before pushing to a production repo |
| [`/backbone:cost-track`](#backbonecost-track) | Heuristic token usage estimate | After significant work, before committing |

---

## Diagnostics

### `/backbone:health`

Run a comprehensive health check on the backbone generator.

**Checks performed:**

| # | Check | How |
|---|-------|-----|
| 1 | Template sync | `backbone/` vs `templates/backbone/` drift |
| 2 | Test suite | `bats tests/bash/`, `pytest tests/python/`, `npm test` |
| 3 | Hook validation | All hooks executable, parity verified |
| 4 | Skill lint | SKILL.md frontmatter, line count |
| 5 | Secret scan | Secrets in staged files |
| 6 | STATE.md sync | Up-to-date with 3-TASKS.md |

**Output:** Structured health report with PASS/FAIL for each check.

**Source:** `.claude/commands/backbone/health.md`

---

### `/backbone:quick`

Execute a small, well-defined task with minimal overhead. Skips the full PRD→Plan workflow.

| When to use | When NOT to use |
|-------------|-----------------|
| Fix a typo or broken link | New feature requiring a PRD |
| Update a single template file | Architectural changes |
| Add a small utility function | Multi-file refactoring |
| Fix a failing test | Changes affecting generated projects |

**Workflow:** Parse task → load required skills → worktrunk check → execute → run relevant tests → commit.

**Source:** `.claude/commands/backbone/quick.md`

---

### `/backbone:stats`

Display comprehensive project statistics.

**Metrics reported:**
- Project structure (files, directories)
- Git activity (commits, contributors, branches)
- Template coverage (frameworks, services)
- Skill inventory (count by category)
- Test results (pass/fail counts)

**When to use:** Health checks, before/after releases, stakeholder reporting.

**Source:** `.claude/commands/backbone/stats.md`

---

## Development

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

### `/backbone:code-review`

Review changed files for bugs, security vulnerabilities, and code quality.

**Depth levels:**

| Level | Duration | What It Checks |
|-------|----------|----------------|
| `quick` | ~2 min | Pattern matching, obvious issues |
| `standard` | ~5–15 min | Per-file analysis with language-specific checks |
| `deep` | ~15–30 min | Cross-file analysis, import graphs, layer violations |

**Arguments:** `--depth=quick|standard|deep` (default: standard), `--files=file1,file2,...`

**Output:** `REVIEW.md` in project root with severity-classified findings (blockers, warnings, suggestions).

**When to use:** Before committing significant changes, after completing a feature phase, before release.

**Source:** `.claude/commands/backbone/code-review.md`

---

### `/backbone:verify`

Run the complete verification pipeline.

| # | Step | What Runs |
|---|------|-----------|
| 1 | Tests | `bats tests/bash/`, `pytest tests/python/`, `cd dev-portal && npm test` |
| 2 | Build | `npm run build` (dev-portal) |
| 3 | Template sync | `scripts/verify-template-sync.sh` |
| 4 | Security scans | `secret-scan.sh --staged`, `base64-scan.sh` |
| 5 | Hook parity | All hooks registered in settings |
| 6 | Skills lint | Frontmatter, line count, framework tags |
| 7 | STATE.md | Verify current with 3-TASKS.md |

**Output:** `VERIFICATION.md` report with PASS/FAIL for each step.

**Source:** `.claude/commands/backbone/verify.md`

---

### `/backbone:implement-task`

Guide the implementation of a single task from 3-TASKS.md with the correct layer skills loaded.

**Arguments:** `/backbone:implement-task [--task <task-id>] [--layer domain|app|infra]`

**Auto-detects:**
- **Framework** from `backbone/4-KNOWLEDGE.md`
- **Layer** from task description (domain/app/infra keywords)
- **REQ- IDs** from the planning doc

**Skills loaded per layer:**

| Layer | Framework Skill | Also Loads |
|-------|----------------|------------|
| `domain/` | `java/java-core` | `test-quality`, `coding-standards`, `incremental-implementation`, `git-commit`, `traceability` |
| `app/` | Framework CDI/patterns skill | Same |
| `infra/` | Framework REST/patterns skill | `jpa-patterns` (if DB), `outbox-pattern` (if messaging) |

**Workflow:**
1. Read task context from planning + design docs
2. Load the right skills for the layer
3. TDD cycle: write test (red) → implement (green) → refactor
4. Tag code with REQ- ID comments
5. Update traceability matrix
6. Commit with REQ- IDs in message
7. Mark task [x] in 3-TASKS.md

**When to use:** After `/backbone:design-feature` created the plan. Run once per task.

**Source:** `.claude/commands/backbone/implement-task.md`

---

## Planning

### `/backbone:design-feature`

**End-to-end feature design pipeline.** Orchestrates the complete SDD workflow from concept to actionable tasks.

**Arguments:** `/backbone:design-feature <feature-name> [--framework <fw>] [--epic <M#>] [--skip-grill]`

**Pipeline steps:**
| # | Step | Skill Used | Artifact |
|---|------|-----------|----------|
| 1 | Grill | `general/grill-me` + `general/grill-with-docs` | Clarified scope, `grilled: true` |
| 2 | Requirements | `general/ears-requirements` | REQ- IDs in EARS format |
| 3 | PRD | `general/create-prd` | `backbone/prd/YYYYMMDD-feature.md` |
| 4 | Architecture | `cross-cutting/architecture/domain-driven-design` or `software-architectures` | Architecture decisions |
| 5 | API Design | `cross-cutting/backend/api-design` | API contract sketches |
| 6 | Design Doc | `general/design-document` | `backbone/design/YYYYMMDD-feature.md` |
| 7 | Traceability | `general/traceability` | `storage/traceability/feature.md` |
| 8 | Plan | `general/planning-and-task-breakdown` | `backbone/planning/YYYYMMDD-feature.md` + `3-TASKS.md` |

**Gates enforced:** G→P (grill→PRD), R→D (reqs→design), D→I (design→impl), P→T (plan→tasks)

**Flags:**
- `--skip-grill` — Skip grilling if already discussed
- `--framework <fw>` — Framework hint for architecture step
- `--epic <M#>` — Milestone reference (e.g., `M8`) for task tracking

**When to use:** Starting any new feature. This is the recommended entry point for all non-trivial work.

**Token cost:** ~$0.15–$0.25 (8 skill loads, human-in-the-loop at critical gates)

**Source:** `.claude/commands/backbone/design-feature.md`

---

### `/backbone:progress`

Show project progress and intelligently route to the next action.

**Output:**
- Milestone progress summary (M1–M8)
- Active/WIP tasks
- Blockers and warnings
- Recommended next action with rationale

**When to use:** Starting a new session ("What should I do next?"), after completing a task ("What's next?"), when lost in context.

**Source:** `.claude/commands/backbone/progress.md`

---

### `/backbone:plan`

Plan a new feature following the formal spec-driven development workflow.

**Arguments:** `/backbone:plan <feature-name> [--framework=<fw>] [--epic=<M#>]`

**Outputs:**
- `backbone/prd/YYYYMMDD-feature.md` — Product Requirements Document
- `backbone/planning/YYYYMMDD-feature.md` — Implementation Plan
- Entries in `backbone/3-TASKS.md` — Granular task breakdown

**When to use:** Starting a new feature, adding a new template type, implementing a new dev portal page.

**Source:** `.claude/commands/backbone/plan.md`

---

### `/backbone:map-codebase`

Generate a comprehensive inventory of the codebase.

**Analyzes:**

| Area | What It Finds |
|------|---------------|
| `templates/` | All project templates with framework coverage |
| `scripts/` | Automation scripts with test coverage |
| `backbone/skills/` | Skills inventory by category |
| `dev-portal/` | API routes and UI components |
| `.claude/` | Hooks, agents, commands |

**Detects:** Orphaned skills, missing tests, placeholder leaks, duplicate files, outdated conventions.

**When to use:** Onboarding, refactoring, finding coverage gaps.

**Source:** `.claude/commands/backbone/map-codebase.md`

---

## Release

### `/backbone:close-feature`

Close out a feature branch — audit requirements, verify suite, code review, suggest ship.

**Arguments:** `/backbone:close-feature [--feature <name>] [--skip-review]`

**Pipeline:**

| # | Step | What Happens |
|---|------|--------------|
| 1 | Collect REQ- IDs | Read PRD, extract all requirement IDs |
| 2 | Audit traceability | Check every REQ- ID has code + test |
| 3 | Gaps? | BLOCK if any REQ- ID is missing implementation or test |
| 4 | Verify suite | Run tests, build, template sync, security scan |
| 5 | Code review | Architecture, edge cases, naming, REQ- coverage |
| 6 | Report | Summary table + next-action suggestion |

**Output:**
```
✅ Feature close-out: <feature-name>
  Requirements: 12 total, 12 implemented, 11 tested
  Tests: 198 passing ✅ | Build: success ✅ | Sync: synced ✅
  Next: Run `/backbone:ship` to tag and release
```

**When to use:** After all feature tasks are [x], before merging.

**Source:** `.claude/commands/backbone/close-feature.md`

---

### `/backbone:ship`

Execute the full release checklist.

**Arguments:** `--dry-run`, `--skip-tests`, `--skip-security`

**Release gates:**

| # | Gate | What Happens |
|---|------|--------------|
| 1 | Tests | `npm test` + `pytest` + `bats` |
| 2 | Build | `npm run build` (dev-portal) |
| 3 | Security | `secret-scan.sh`, `prompt-injection-scan.sh` |
| 4 | Template sync | `verify-template-sync.sh` |
| 5 | Version bump | Update `backbone/VERSION` (CalVer) |
| 6 | Changelog | Auto-generated from conventional commits |
| 7 | Docs check | Decisions, memory, STATE.md |
| 8 | Commit + tag | `git tag -a YYYY.MM.DD` |
| 9 | Push | Push branch + tag to origin |

**Example output:**
```
🚀 Release Report: 2026.05.13
  ✅ Tests:       198 passing
  ✅ Build:       success
  ✅ Security:    clean
  ✅ Version:     2026.05.12 → 2026.05.13
  ✅ Tag:         2026.05.13 created
  ✅ Pushed:      origin
```

**Source:** `.claude/commands/backbone/ship.md`

---

### `/backbone:sync-skills`

Validate and synchronize the skills directory.

**Checks:**
1. Every SKILL.md has required frontmatter (name, description, framework)
2. No SKILL.md exceeds 300 lines
3. Descriptions use third person (not "I...")
4. Framework tags match directory structure
5. Generates skills manifest for dev-portal

**Fixes applied:** Adds missing frontmatter, reports oversized skills, suggests splitting into reference files.

**When to use:** After adding or editing a skill, before syncing to templates.

**Source:** `.claude/commands/backbone/sync-skills.md`

---

### `/backbone:push-clean`

Export a production-ready copy of the project — strips all AI agent scaffolding and pushes only the runtime code.

**Arguments:** `--remote URL`, `--branch NAME` (default: main), `--dry-run`

**What gets stripped:**

| Stripped | Kept |
|----------|------|
| `backbone/`, `.claude/` | `src/`, build files |
| `AGENTS.md`, `CLAUDE.md`, `COMMANDS.md` | `Dockerfile`, `docker-compose.yml` |
| `.backbone/`, `.worktrunk.toml` | `k8s/`, `argocd/` |
| `scripts/hooks/` | `scripts/` (utility only) |
| `templates/` | `tests/`, `docs/`, `frontend/`, `.github/workflows/` |

**Workflow:**
1. `rsync` files to a temp directory (with exclude patterns)
2. Run `secret-scan.py` on exported files
3. `git init` + `git add -A` + `git commit` in temp dir
4. `git bundle create /tmp/<project>-clean.bundle --all`
5. (Optional) `git push -u origin <branch>` to `--remote`

**Safety:** `--dry-run` to preview, source project never modified, secret scan enforced.

**When to use:** Before pushing to a production repo, handing off to a non-backbone team, creating a deployment artifact.

**Source:** `.claude/commands/backbone/push-clean.md`

---

## Cost Awareness

### `/backbone:cost-track`

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

**Source:** `.claude/commands/backbone/cost-track.md`

---
## Optional Integrations

### Context7 — Live Library Documentation

This project has Context7 configured as an MCP server in `.claude/settings.json` for up-to-date version-specific library docs. To activate it, each developer must obtain a free API key:

```bash
npx ctx7 setup --claude        # one-time: OAuth, generates a free key
export CONTEXT7_API_KEY=ctx7sk_...  # add to ~/.zshrc or .claude/settings.local.json
```

**Without the key**, the MCP server won't start — agents fall back to training data for library APIs (may be outdated). Setup takes ~2 minutes.

---

*Last updated: 2026-05-15*
