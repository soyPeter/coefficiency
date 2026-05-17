<!-- VERSION: 2026.05.13#5-commandpipeline,16commandstotal -->
# AI Agent Bootstrap

> This project was initialized using the **Agentic Backbone** generator.
> Backbone version: 2026.05.13#5-commandpipeline,16commandstotal

## Right Now — 30 Second Start

1. **Read this file** (you're doing it)
2. **Read `backbone/4-KNOWLEDGE.md`** — tech stack, constraints, build commands
3. **Read `backbone/8-WORKFLOW.md`** — Definition of Done, commit rules, test reqs
4. **Read `backbone/3-TASKS.md`** — see what's [WIP] and what to work on
5. **Load a skill** before coding (see Skill Lookup below)
6. **Type `acknowledge`** when the hook asks — or it blocks Write/Edit

## Specification-Driven Development (SDD)

This project uses blocking review gates. You **cannot skip** these steps:

| Gate | What You Need | Before You Can |
|------|---------------|----------------|
| **G → P** | Grill with `grill-me` skill, add `grilled: true` to PRD | Create a PRD |
| **R → D** | PRD in `backbone/prd/` with EARS requirements | Write a design doc |
| **D → I** | Design doc in `backbone/design/` | Write implementation code |
| **P → T** | Planning doc in `backbone/planning/` with task breakdown | Mark tasks [WIP] in `3-TASKS.md` |
| **I → V** | Traceability matrix in `storage/traceability/` | Mark task complete / commit |

**Exemptions:** `fix`, `docs`, `refactor`, `chore`, `test` tasks skip grilling, design doc, and planning doc requirements.

**How to start a feature:**
1. Create PRD using `backbone/templates/docs/prd.md`
2. Create design doc using `backbone/templates/docs/design-doc.md`
3. Implement with REQ- IDs in code comments
4. Run `./scripts/extract-traceability.sh` to auto-build traceability
5. Run `./scripts/verify-traceability.sh` before committing

**Blocked?** See `backbone/8-WORKFLOW.md` → "Review Gates (Blocking)" for full details.

## Reading Checklist (Mandatory)

| # | File | Why | When |
|---|------|-----|------|
| 1 | `AGENTS.md` (this file) | Bootstrap guide | Every session |
| 2 | `backbone/4-KNOWLEDGE.md` | Tech stack, NEVER DO list, build commands | Every session |
| 3 | `backbone/8-WORKFLOW.md` | Definition of Done, commit rules, test reqs | Every session |
| 4 | `backbone/3-TASKS.md` | Current WIP tasks, what to work on right now | Every session |
| 5 | `backbone/reference/conventions/jooby.md` | Framework-specific syntax mapping | If working on code |

*After reading once, trust session memory. Don't re-read unless you need a specific detail.*

## Skill Lookup — Load Before Coding

**Framework-specific:**
- jooby skills → `backbone/skills/jooby/` (list available skills with `ls`, then load the one matching your task)
- Testing → `backbone/skills/cross-cutting/testing/test-quality/SKILL.md`

**Always available:**
- Any code → `backbone/skills/general/coding-standards/SKILL.md`
- Git commits → `backbone/skills/general/git-commit/SKILL.md`
- Spec/PRD work → `backbone/skills/general/spec-driven-development/SKILL.md`

**Skill safety:** Verify first line says `<!-- FRAMEWORK: ... -->`. If missing, ask the user.

**How to load:** `view backbone/skills/<category>/<skill-name>/SKILL.md`

### Cross-Agent Skill Enforcement (S→C)

The skill gate is enforced at **pre-commit time** for ALL agents (Claude Code, OpenCode, Cursor, etc.).

**How to acknowledge:**

Option 1 — Session file:
```bash
mkdir -p .backbone/session
echo '{"java/java-core": true}' > .backbone/session/skills.json
git add .backbone/session/skills.json
```

Option 2 — Commit message:
```bash
git commit -m "feat(auth): add OAuth login" -m "Skills: java-core"
```

**Mechanical enforcement:**
- `pre-tool-use-skill-check.sh` blocks Write/Edit without acknowledgment (Claude Code)
- `pre-commit-skill-check.sh` blocks commits without acknowledgment (all agents)
- Pre-commit Gate 14 validates staged files
- Override: `export SKIP_SKILL_CHECK=1`

## Task Granularity Enforcement (Planning → Tasks)

Before marking a task as [WIP] in `3-TASKS.md`, you MUST decompose work into small, concrete units:

1. **Load the skill**: `view backbone/skills/general/planning-and-task-breakdown/SKILL.md`
2. **Create a planning doc** in `backbone/planning/` with vertical slice breakdown
3. **Write granular tasks**: each task does ONE thing with a size tag [XS/S/M/L]

**Task syntax rules:**
- Size tag REQUIRED: `[XS]`, `[S]`, `[M]`, or `[L]` (XL forbidden)
- Minimum 5 words describing WHAT + WHERE
- Concrete verbs only: add, fix, remove, configure, validate, create, update, extract, refactor
- NO vague verbs: implement, build, develop, do, make, setup
- NO scope bloat: and, all, entire, everything, system, module, feature, epic
- ONE thing per task; title containing "and" signals two tasks

**Mechanical enforcement:**
- `pre-tool-use-task-granularity-check.sh` blocks [WIP] tasks that fail syntax rules
- Pre-commit Gate 12 validates staged 3-TASKS.md changes
- Override: `export CLAUDE_CODE_SKIP_GRANULARITY=1`

**Exemptions:** fix, bug, docs, refactor, chore, test, perf, ci, build, style tasks skip planning doc and size requirements.

## Core Guardrails

- **Follow conventions** from `backbone/4-KNOWLEDGE.md` and framework conventions file
- **Respect boundaries** — don't leak framework imports into domain layer
- **Load skills first** — the `pre-tool-use-skill-check.sh` hook blocks Write/Edit until acknowledged
- **Cross-agent enforcement** — pre-commit Gate 14 blocks commits without skill acknowledgment (works with Claude Code, OpenCode, Cursor, etc.)
- **Never ignore hooks** — if a hook warns, fix it before proceeding

## Safe-Change Guardrails

Some changes are technically easy but operationally expensive. **Flag before acting.**

| Change | Rule |
|--------|------|
| Domain model changes | Changing entities, tables, or API contracts affects all layers. Discuss before modifying. |
| Framework version bumps | Upgrading jooby or build tools can break the build. Test thoroughly. |
| Test pipeline changes | Modifying test configuration or removing tests reduces safety. Run the full suite first. |
| Shared libraries | Changes to `services/libs/shared-*` affect all services. Coordinate with service owners. |
| `4-KNOWLEDGE.md` / `8-WORKFLOW.md` | These are project conventions. Discuss major changes with the team. |

**If unsure whether a change is safe, treat it as unsafe — mention it to the user before editing.**

## Behavioral Guardrails (Backbone Principles)

Derived from [Andrej Karpathy's observations](https://github.com/forrestchang/andrej-karpathy-skills) on LLM coding pitfalls. These principles bias toward **caution over speed**.

### 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- **State assumptions explicitly** — If uncertain, ask rather than guess.
- **Present multiple interpretations** — Don't pick silently when ambiguity exists.
- **Push back when warranted** — If a simpler approach exists, say so.
- **Stop when confused** — Name what's unclear and ask for clarification.

### 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

**The test:** Would a senior engineer say this is overcomplicated? If yes, simplify.

### 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it — don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that **YOUR** changes made unused.
- Don't remove pre-existing dead code unless asked.

**The test:** Every changed line should trace directly to the user's request.

### 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

### 5. The AI Cascade Effect (John Macias)

Derived from [The Three Layers Before Claude Code](https://thebrokentelephone.com/articles/three-layers-before-claude-code/). Errors at the **foundation level** compound exponentially across all subsequent AI prompts.

**The Hierarchy of Technical Impact:**

| Level | What | Visibility | Cost of Error |
|-------|------|------------|---------------|
| 1 — Foundation | Entities, business logic, integration contracts | Low | **Critical** |
| 2 — Behavior | Flows, states, edge cases | Medium | Medium |
| 3 — Aesthetics | Colors, copy, spacing | High | Low |

**What this means:**
- A wrong data model (Level 1) poisons every query, every test, every prompt that references it. The cost isn't the initial mistake — it's the 20 follow-up prompts explaining why the fix for the fix needs another fix.
- An ambiguous API contract (Level 1) means the client and service are built on different assumptions. Both look correct in isolation. Neither works together.
- A wrong hex color (Level 3) is a one-line change.

**The rule:**
- Before generating code, verify the foundation is solid. If the spec is ambiguous about entities or contracts, **stop and clarify** — don't generate 400 lines of confident code on a shaky foundation.
- When refactoring, change Level 1 first, then Level 2, then Level 3. Never the reverse.

## Subagent Workflow (Parallel Task Execution)

The backbone supports spawning specialized subagents for parallel task execution. This keeps the main agent's context clean while independent tasks run in isolation.

### Available Subagents

| Subagent | Fork | Purpose | When to Use |
|----------|------|---------|-------------|
| `backbone-explorer` | fresh (0) | Search codebase, find files/patterns | Need to locate something without reading entire files |
| `backbone-planner` | inherit (1) | Create implementation plans from PRDs | Breaking down a complex task before coding |
| `backbone-implementer` | inherit (1) | Implement ONE specific sub-task | Executing a single task from 3-TASKS.md |
| `backbone-validator` | inherit (1) | Run full verification suite | After implementation, before committing |
| `backbone-peer-reviewer` | inherit (1) | Review changes for quality/compliance | Before final commit, as quality gate |

### Orchestration Pattern

```
Main Agent
  ├── backbone-explorer → "find all TODOs in src/"
  ├── backbone-planner → "plan fix for auth bug"
  └── backbone-peer-reviewer → "validate plan: consistent, complete, testable?"
       └── backbone-implementer → "implement fix for auth bug"
            └── backbone-validator → "verify auth fix"
            └── backbone-peer-reviewer → "review implementation"
```

### Handoff Contracts (Structured Output)

Each agent must return output in a predictable structure. The parent agent validates the contract before spawning the next agent.

| From | To | Contract | Format |
|------|-----|----------|--------|
| `backbone-explorer` | Main Agent | `{files: [{path, line, context}]}` | Markdown list |
| `backbone-planner` | `backbone-peer-reviewer` | Plan with Skills, Files, Tests, Verification | Markdown sections |
| `backbone-peer-reviewer` | Main Agent | `{verdict: "APPROVE" \| "REQUEST_CHANGES", issues: []}` | Markdown table |
| `backbone-implementer` | `backbone-validator` | `{files_modified: [], files_created: [], test_results: {}, issues: []}` | Markdown sections |
| `backbone-validator` | Main Agent | `{gates: [{name, status, details}], overall: "PASS" \| "FAIL"}` | Markdown table |

### Rules
- **Spec before implementation** — planner output must be validated by peer reviewer before implementer starts
- **Subagents don't commit** — return changes to main agent for final commit
- **Subagents skip skill acknowledgment** — main agent acknowledges once, subagents inherit
- **Explorer starts fresh** — no inherited context, just search capabilities
- **Planner/Implementer inherit** — must know backbone conventions from 4-KNOWLEDGE.md
- **Sequential for conflicts** — if two implementers touch the same file, run sequentially
- **Batch validation** — run validator once after all implementers finish

### File Conflict Enforcement (Mechanical)

The `pre-tool-use-subagent-conflict-check.sh` hook enforces the "Sequential for conflicts" rule automatically. It blocks `Task` spawns when declared files overlap with a running subagent.

**Convention:** Subagents that write files MUST declare targets in the first line of the prompt:

```
FILES: [src/auth.ts, src/user.ts]

You are backbone-implementer...
```

- `FILES:` must be on its own line at the start of the prompt
- Format: bracket list with comma-separated paths
- No `FILES:` declaration = conflicts not detectable = allowed silently
- Registry auto-expires entries after 15 minutes
- Override: `export CLAUDE_CODE_SKIP_SUBAGENT_CONFLICT_CHECK=1`

### How to Spawn

```
Use the Task tool with subagent_type matching the agent name.
Provide a complete, self-contained prompt — subagents don't see your context.
```

## Live Documentation (Mandatory)

1. **Before starting:** Mark task `[WIP]` in `backbone/3-TASKS.md`
2. **After completing:** Mark `[x]` in `backbone/3-TASKS.md`
3. **Decisions:** Add to `backbone/5-DECISIONS.md`
4. **Lessons learned:** Add to `backbone/6-MEMORY.md`
5. **Commits:** Use conventional format `type(scope): description` (load git-commit skill)

## Commit Format

```
feat(portal): add user authentication
fix(hooks): resolve NPE in health check endpoint
docs(backbone): update 3-TASKS.md with M3 progress
```

Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `perf`, `ci`, `build`

## Session State

`backbone/SESSION.md` is auto-generated on session start. It tracks:
- Files you've read this session
- Skills you've acknowledged
- WIP tasks
- Completed tasks (synced to `3-TASKS.md` on commit)

## Token Efficiency & Cost Awareness

- **Read once, trust memory** — don't re-read `4-KNOWLEDGE.md` every message
- **Targeted edits** — use Edit tool, never rewrite entire files
- **15-minute chunks** — break tasks into small sub-tasks in `3-TASKS.md`
- **Batch operations** — process multiple files/skills together
- **Log costs per task** — after significant work, call `/backbone:cost-track` to record token proxies and estimated spend in `backbone/SESSION.md`

### Cost Tracking Command

Use `/backbone:cost-track` to log a heuristic cost estimate. It's not exact (Claude Code doesn't expose token counts), but it builds awareness:

```
Heuristic formula:
  base_tokens  = 15_000 × subagent_spawns
  file_tokens  = 500 × files_read
  tool_tokens  = 2_000 × tool_calls
  input_tokens ≈ base + file + tool
  output_tokens ≈ input × 0.25
  cost_usd     = (input/1M × $3) + (output/1M × $15)  # Sonnet 4.6
```

A typical multi-agent task with 3 subagents, 20 file reads, and 15 tool calls ≈ **$0.20-0.30**.
The command appends an entry to `backbone/SESSION.md` and updates a running session total.

> ⚠️ **Flag threshold:** If session total exceeds $5.00, the command warns you to review whether all subagent spawns were necessary.
