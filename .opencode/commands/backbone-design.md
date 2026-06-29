---
description: Full feature design pipeline — grill → EARS → proposal → design → tasks. Supports --amend for delta changes.
agent: plan
required-skills:
  - general/grill-me
  - general/grill-with-docs
  - general/ears-requirements
  - general/create-prd
  - general/design-document
  - general/traceability
  - general/planning-and-task-breakdown
  - general/spec-driven-development
---

> **skill loading:** Read this command's `required-skills` frontmatter above. For each entry, check if `backbone/skills/<path>/SKILL.md` exists — if yes, `view` it; otherwise use `skill tool "<basename>"` as fallback.

Run the feature design pipeline for the requested feature: $ARGUMENTS

If the first argument is `--amend`, the second is a CHNG-ID (e.g., CHNG-027),
and the rest is the amendment name. This runs the Amendment Flow.

If the first argument is `--type`, the second is a feature type (api|layout|backend|config|workflow)
to override automatic classification.

Read `backbone/.MODE` to determine depth:
- `full` (default): Full 5-branch grill, C4 diagrams, mandatory ADR
- `standard`: 5-branch grill, template C4, ADR if significant
- `light`: Skip grill, quick proposal + tasks only

## Amendment Flow (--amend CHNG-XXX)

1. Validate target `backbone/artifacts/changes/CHNG-XXX-*/` exists
2. Read parent proposal, design, tasks for context
3. Run `./scripts/backbone-change-init.sh --parent CHNG-XXX <name>` to scaffold delta
4. Write delta EARS (use decimal notation: REQ-PARENT-001.1)
5. Write delta design (only changed decisions, link to parent for rest)
6. Write delta tasks with `[AMEND: CHNG-XXX]` markers
7. Update [[`backbone/3-TASKS.md`](backbone/3-TASKS.md)](backbone/3-TASKS.md)

## Full Design Flow (no --amend flag)

1. Run `./scripts/backbone-change-init.sh "$ARGUMENTS"` to scaffold
2. **Classify feature type** (REQ-GRL-005):
   - If `--type` was passed, use that value directly
   - Otherwise, classify from the feature description using keyword heuristics:
     - `api`, `endpoint`, `route`, `rest`, `graphql` → **api**
     - `ui`, `component`, `page`, `view`, `frontend`, `layout` → **layout**
     - `backend`, `service`, `handler`, `worker`, `cron`, `job` → **backend**
     - `config`, `setting`, `env`, `property`, `yaml` → **config**
     - `workflow`, `pipeline`, `process`, `orchestrat`, `choreography` → **workflow**
     - Default: **backend**

3. **Domain-aware questioning** — Select question strategy based on type:

   **api type** — Focus on contracts, status codes, error bodies, auth, versioning:
   - "What endpoints are in scope?"
   - "What HTTP methods and status codes?"
   - "What error response format?"
   - "Auth or rate limiting requirements?"
   - "Request/response schema contracts?"

   **layout type** — Focus on density, responsiveness, interactions, states:
   - "What layout density — information-dense or spacious?"
   - "Breakpoints and responsive behavior?"
   - "Loading, empty, error, and edge-case states?"
   - "User interactions (click, hover, drag, keyboard)?"
   - "Design system components to reuse?"

   **backend type** — Focus on service boundaries, domain logic, async, state:
   - "Service boundaries — new service or existing module?"
   - "Synchronous vs async processing?"
   - "Idempotency and retry requirements?"
   - "State management — persistent, cached, or ephemeral?"
   - "Observability — logs, metrics, traces?"

   **config type** — Focus on scope, format, validation, migration:
   - "Configuration scope — global, per-environment, per-tenant?"
   - "Format — YAML, TOML, JSON, env vars, database?"
   - "Validation — schema, defaults, constraints?"
   - "Migration path from old config?"
   - "Secrets vs non-sensitive values?"

   **workflow type** — Focus on steps, transitions, failure modes, observability:
   - "Step sequence — linear, branching, parallel?"
   - "State transitions and persistence?"
   - "Failure handling — retry, compensate, dead-letter?"
   - "Timeout and SLA requirements?"
   - "Observability — what to trace?"

   **Scope guardrail:** "Phase boundary from proposal is FIXED. Discussion clarifies HOW to implement, not WHETHER to add more. If user suggests new capabilities: 'That's its own change. I'll note it for later.'"

5. Read [`backbone/skills/general/grill-me/SKILL.md`](backbone/skills/general/grill-me/SKILL.md) and grill the user one question at a time, walking the decision tree: Scope → Boundaries → Data & State → API → Implementation Order
6. For full mode: also read [`backbone/skills/general/grill-with-docs/SKILL.md`](backbone/skills/general/grill-with-docs/SKILL.md) and check domain glossary
7. Write EARS requirements with REQ- IDs
8. Edit proposal.md in the change folder (include Grilling section with all 5 branches, 2+ Q/A pairs each)
9. Edit design.md (architecture decisions, data model, API contracts, C4)
10. **Write tasks.md — Granularity Refinement:**

    **Step 1 — Scan for "and" violations:** Every task title containing "and" signals multiple things. Flag all. Examples:
    - "Create Foo enum and Bar record" → 2 tasks (one per file)
    - "Add guard clause in Class.methodA() and Class.methodB()" → 2 tasks (one per method)
    - "Create controller with GET /foo, POST /bar" → 3+ tasks (class + one per endpoint)

    **Step 2 — One file per task:** Split tasks creating multiple files.

    **Step 3 — One method per task:** Split tasks adding logic to multiple methods.

    **Step 4 — One endpoint per task:** Controller tasks with N routes → N+1 tasks (class + each endpoint).

    **Step 5 — One query per task:** Repository tasks with N queries → N+1 tasks.

    **Step 6 — One test scenario per task:** Test tasks covering multiple scenarios → split per scenario.

    **Step 7 — Verify size tags:** After splitting, reassign: [XS] single item, [S] method/query/test, [M] complex (rare), [L] forbidden — split further.

    **Final check:** No task title contains "and", "or", comma-separated lists, or vague verbs (implement, build, develop, do, make, setup).

11. Update `backbone/3-TASKS.md` and mark first task [WIP]

## Worktree (recommended for features)

After design, suggest creating an isolated worktree:
```bash
./scripts/worktrunk.sh create feat/<feature-slug>
cd ../<project>-feat-<feature-slug>
```
Implementation happens in isolation. Merge back via `/backbone-close`.

## Gates
- G→P: All 5 branches grilled one at a time with recommendations
- R→D: proposal.md has EARS + Grilling section
- D→I: design.md with architecture + API contracts
- P→T: tasks.md with vertical slice breakdown
