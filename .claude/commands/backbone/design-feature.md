---
name: backbone:design-feature
description: End-to-end feature design pipeline. Orchestrates grill → EARS reqs → PRD → architecture → API design → design doc → traceability → plan. Loads each skill, enforces gates, and creates all artifacts.
argument-hint: "<feature-name> [--framework <fw>] [--epic <M#>] [--skip-grill]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - Question
---
<objective>
Run the complete feature design pipeline from concept to actionable tasks.

**When to use:**
- Starting a new feature of any size
- Any task that needs a PRD (feature work, non-fix/docs)
- Before writing ANY production code for a new capability

**What it does:**
1. Loads the right skill for each step (grill, reqs, PRD, architecture, API design, design doc, planning)
2. Creates all artifacts in the correct backbone/ directories
3. Enforces G→P (grill→PRD) and R→D (requirements→design) gates
4. Sets up traceability from the start

**Flags:**
- `--skip-grill` — Skip grilling if already discussed this feature
- `--framework <fw>` — Framework hint (e.g., `quarkus`, `springboot`) for architecture step
- `--epic <M#>` — Milestone/epic reference (e.g., `M8`) for task tracking
</objective>

<process>
## Step 0: Parse & Verify

- Extract `<feature-name>` (required) from arguments
- Parse `--framework`, `--epic`, `--skip-grill`
- Normalize feature name: lowercase, hyphens for spaces (e.g., "Add User Auth" → "add-user-auth")
- Set date stamp: `YYYYMMDD=$(date +%Y%m%d)`
- Check if PRD already exists for this feature → if yes, propose reading instead

---

## Step 1: Grill — Gate G→P

**Only if `--skip-grill` not set.**

1. Load `view backbone/skills/general/grill-me/SKILL.md`
2. Ask the user about the feature using the grilling framework:
   - What problem does this solve? For whom?
   - What's in scope? What's explicitly out of scope?
   - What's the data model? Entities, relationships?
   - What are the API contracts? Endpoints, methods, payloads?
   - What are the edge cases? Error modes?
   - What are the acceptance criteria?
3. Record key decisions and clarifications
4. Load `view backbone/skills/general/grill-with-docs/SKILL.md` for domain-specific grilling

**Gate G→P** — Do not proceed without:

```
[ ] Grilled → clarified scope, boundaries, data model, edge cases
[ ] Decision summary recorded for PRD frontmatter
```

---

## Step 2: Requirements — EARS Format

1. Load `view backbone/skills/general/ears-requirements/SKILL.md`
2. Write requirements in EARS format using the grill output:
   - Each requirement gets a unique ID: `REQ-<FEATURE>-<NNN>`
   - Use Ubiquitous statements for always-true invariants
   - Use Event-Driven statements for trigger-response
   - Use State-Driven statements for state-dependent behavior
   - Use Unwanted Behavior statements for error/failure cases
   - Use Optional Feature statements for conditional capabilities

**Output:** Draft REQ- IDs and EARS statements (saved to PRD later)

---

## Step 3: PRD — Product Requirements Document

1. Load `view backbone/skills/general/create-prd/SKILL.md`
2. Create `backbone/prd/YYYYMMDD-feature-name.md` with:
   - Frontmatter: `grilled: true`, feature name, date
   - Problem statement (from grill)
   - Objectives and success metrics
   - User segments
   - Solution overview (high-level, no implementation details)
   - EARS requirements from Step 2
   - Out-of-scope items (from grill)
3. Verify PRD has:
   - `grilled: true` ✅
   - EARS requirements with REQ- IDs ✅
   - Acceptance criteria for each requirement ✅

**Gate R→D** — Do not proceed without:

```
[ ] PRD exists in backbone/prd/
[ ] grilled: true in frontmatter
[ ] Requirements in EARS format with unique REQ- IDs
[ ] Acceptance criteria defined for each requirement
```

---

## Step 4: Architecture — Decision & Pattern Selection

**Ask the user if architecture discussion is needed** (skip for simple features).

If yes:

1. Load `view backbone/skills/cross-cutting/architecture/domain-driven-design/SKILL.md`
   - Identify bounded contexts, aggregates, entities, value objects
   - Define domain events and services
2. Load `view backbone/skills/cross-cutting/architecture/software-architectures/SKILL.md`
   - Select architecture pattern (hexagonal, CQRS, event-driven, etc.)
   - Document the decision with rationale
3. Record ADR in `backbone/decisions/` if significant (optional, ask user)

**Output:** Architecture notes for the design doc

---

## Step 5: API Design — Contracts

**Ask the user if API design is needed** (skip for internal-only features).

If yes:

1. Load `view backbone/skills/cross-cutting/backend/api-design/SKILL.md`
2. Define endpoints, request/response schemas, error responses
3. Document API contracts for the design doc

**Output:** API contract sketches for the design doc

---

## Step 6: Design Doc — Detailed Design

1. Load `view backbone/skills/general/design-document/SKILL.md`
2. Create `backbone/design/YYYYMMDD-feature-name.md` with:
   - C4 model (Context, Container, Component diagrams — text/ascii)
   - Data model: entities, relationships, database schema
   - API contracts (from Step 5)
   - ADRs (if architecture decisions were recorded)
   - Sequence diagrams for key flows
   - Error handling strategy
   - Security considerations
   - Testing strategy

**Gate D→I** — Do not proceed without:

```
[ ] Design doc exists in backbone/design/
[ ] C4 model covers Context, Container, Component levels
[ ] ADRs document significant architectural decisions
[ ] API contracts define request/response schemas
[ ] Traceability links requirements to design sections
```

---

## Step 7: Traceability — Initialize Matrix

1. Load `view backbone/skills/general/traceability/SKILL.md`
2. Initialize traceability at `storage/traceability/feature-name.md`:
   - Map each REQ-ID to design doc sections
   - Leave implementation and test columns blank (filled during coding)
3. Run `./scripts/verify-traceability.sh` if available

---

## Step 8: Plan — Task Breakdown

1. Load `view backbone/skills/general/planning-and-task-breakdown/SKILL.md`
2. Create `backbone/planning/YYYYMMDD-feature-name.md` with:
   - Vertical slice breakdown
   - Each task ONE thing, size-tagged [XS/S/M/L]
   - Concrete verbs: add, fix, create, update, extract, refactor
   - No vague verbs: implement, build, develop, do, make, setup
3. Add entries to `backbone/3-TASKS.md` under the appropriate milestone
4. Mark the first task as `[WIP]`

---

## Step 9: Report

Summarize what was created:

```
✅ Design pipeline complete: <feature-name>

Artifacts:
  - PRD:      backbone/prd/YYYYMMDD-feature-name.md
  - Design:   backbone/design/YYYYMMDD-feature-name.md
  - Planning: backbone/planning/YYYYMMDD-feature-name.md
  - Trace:    storage/traceability/feature-name.md
  - Tasks:    backbone/3-TASKS.md (N new tasks)

Requirements: REQ-<FEATURE>-001 to REQ-<FEATURE>-NNN
Architecture: [DDD / Hexagonal / etc.]
API endpoints: N defined

Next: Run `/backbone:inspect` to start implementing task #1
```
</process>

<critical_rules>
- ALWAYS load each skill before using it (view, then apply)
- NEVER skip the grill step unless --skip-grill is explicit
- NEVER write code during this command — it's design-only
- Ask user before diverging from the defined process
- If user says "too heavy", offer --skip-grill and skip architecture/API steps
</critical_rules>

<success_criteria>
- [ ] PRD created with EARS requirements and REQ- IDs
- [ ] Design doc created with C4 model and architecture decisions
- [ ] Traceability matrix initialized
- [ ] Planning doc created with vertical slice tasks
- [ ] 3-TASKS.md updated with granular tasks, first marked [WIP]
- [ ] All gates satisfied (G→P, R→D, D→I)
</success_criteria>
