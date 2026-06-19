<!-- VERSION: 2026.05.29 -->
<!-- PURPOSE: Agent execution checklist, review gates, Definition of Done -->
# 8. AI Agent Execution Workflow

*Standard operating procedure for AI agents when working on projects using this backbone.*

## Phase Execution Checklist

Before making changes, the agent MUST:

1. **Read `4-KNOWLEDGE.md`** to understand the tech stack and project constraints.
2. **Read `backbone/reference/conventions/<framework>.md`** to understand framework-specific syntax mappings.
   - *The framework name is defined in 4-KNOWLEDGE.md (e.g., quarkus-conventions.md, springboot-conventions.md)*
3. **Grill before PRD** — For feature work, use the `grill-me` skill to stress-test requirements before writing the PRD.
   - Load: `view backbone/skills/general/grill-me/SKILL.md`
   - After grilling, add `grilled: true` to the PRD frontmatter.
   - *Exempt: fix, bug, docs, refactor, chore, test tasks.*
4. **Read `1-PRD.md`** to verify a PRD exists for the feature/task. If none exists, create one using the `create-prd` skill before proceeding.
5. **Read `3-TASKS.md`** to identify the current objective.
   - Ensure [WIP] tasks follow granularity rules: size tag [XS/S/M/L], concrete WHAT+WHERE, no scope bloat.
6. **Acknowledge Required Skills** for the task/workspace.
7. **Worktree decision** — Evaluate whether to create a worktree:

   | Worktree? | Criteria | Agent Action |
   |-----------|----------|--------------|
   | **Mandatory** | `[WIP]` feature task, Level 1 change (domain model, API contracts, shared libs), changes to `services/libs/shared-*` | Auto-create or prompt user. Blocks commit on `dev`/`main` via Gate 4. |
   | **Recommended** | Multi-session task, 5+ files affected, high-risk refactor, cross-cutting change | Proactively recommend: "This touches N files across M layers — want a worktree?" |
   | **Optional** | `fix`/`docs`/`refactor`/`chore`/`test`/`perf`, single-session quick edits, exploratory spikes | Work on current branch is fine. |

   **Agents must proactively flag Level 1 worktree needs** — don't wait for the user to ask. The AI Cascade Effect means a wrong foundation change on `dev` poisons the entire branch.
8. **(Optional) Context7 Live Docs** — This project has Context7 configured as an MCP server for up-to-date library documentation. When writing code that uses framework or library APIs, use `resolve-library-id` + `query-docs` to verify current API signatures and prevent hallucinated calls. Requires `CONTEXT7_API_KEY` — see [`backbone/4-KNOWLEDGE.md`](backbone/4-KNOWLEDGE.md) for setup.

## Quality Management (QMS)

When you discover a defect, design flaw, or nonconformance during implementation, **automatically register an NCR** — no user prompting needed.

```bash
# Register linked to the active change folder
./scripts/qms-register-issue.sh \
  --title "Brief description of the issue" \
  --severity major \
  --category code \
  --change CHNG-XXX

# Or use the slash command (Claude Code):
# /backbone:qms
```

**NCR→CAPA pairing (mandatory):**
Every NCR **must** have a corresponding CAPA (Corrective and Preventive Action). This is not optional. When you register an NCR:
1. `scripts/qms-register-issue.sh` auto-creates a CAPA with the NCR ID as reference
2. The CAPA records the root cause, action plan, owner, and due date
3. You must update the CAPA with actual root cause and action plan after investigation
4. Close the CAPA when the corrective action is complete

**Why mandatory pairing?**
- An NCR without a CAPA is a complaint without a fix plan — it doesn't drive improvement
- CAPA forces root cause analysis before jumping to a fix
- The pairing enables trend analysis (which areas produce NCRs without closed CAPAs)
- Pre-commit Gate 10a warns if any open NCR lacks a linked CAPA

```bash
# NCR → CAPA is automatic, but you should update with details:
./scripts/qms-capa-close.sh --capa CAPA-XXX --verification "Fix verified: added validation, tests pass"
```

**Mechanical enforcement (automatic — no agent action needed):**
- **NCR registration auto-generates CAPA** — `qms-register-issue.sh` calls `qms-capa-create.sh` automatically
- Pre-tool-use QMS hook: warns about open NCRs when editing change folder files
- Post-tool-use auto-register: suggests NCR when a test/build command fails
- Pre-commit Gate 10: warns on `fix:` commits without linked NCRs
- Pre-commit Gate 10a: warns if any open NCR has no linked CAPA
- Archive Gate Z4: **blocks** archiving a change with open linked NCRs (`--force` to skip)
- Pre-release hook: **blocks** release if critical NCRs open without CAPA

**After archiving:** If NCRs were linked, `lessons-learned.md` is auto-generated in the archive folder. Fill in root cause, corrective actions, and prevention.

## Review Gates (Blocking)

Review gates enforce quality checkpoints between SDD phases. The `review-gate-check.sh` hook blocks Write/Edit when gates are not satisfied.

### Gate G→P: Grilling → PRD (Full: Blocking / Light: Advisory)

Before creating a PRD for feature work:
- [ ] Agent has used the `grill-me` skill to stress-test requirements
- [ ] Scope, boundaries, data model, and edge cases are clarified
- [ ] PRD frontmatter includes `grilled: true`

**Failure:** Agent attempts to write PRD without grill evidence → blocked with instructions to grill first.

**Exemptions:** Fix, bug, docs, refactor, chore, test tasks skip grilling.

### Gate R→D: Requirements → Design (Full/Standard: Blocking / Light: Advisory)

Before creating a design document:
- [ ] proposal.md exists in `backbone/artifacts/changes/CHNG-XXX/`
- [ ] PRD has `grilled: true` in frontmatter (feature work only)
- [ ] Requirements are in EARS format with unique IDs
- [ ] Acceptance criteria are defined for each requirement
- [ ] PRD is referenced from `3-TASKS.md`

**Failure:** Agent attempts to write design doc without approved PRD → blocked with instructions to create PRD first.

### Gate D→I: Design → Implementation (Full/Standard: Blocking / Light: Advisory)

Before writing implementation code:
- [ ] design.md exists in `backbone/artifacts/changes/CHNG-XXX/`
- [ ] C4 model covers Context, Container, and Component levels
- [ ] ADRs document all significant architectural decisions
- [ ] API contracts define request/response schemas
- [ ] Traceability links requirements to design sections
- [ ] Design doc is referenced from `3-TASKS.md`

**Failure:** Agent attempts to implement without design doc → blocked with instructions to create design doc first.

**Exemptions:** Fix, docs, refactor, chore, test tasks do not require design docs.

### Gate P→T: Planning → Tasks (Full: Blocking / Light: Advisory)

Before marking tasks as [WIP] in `3-TASKS.md`:
- [ ] tasks.md exists in `backbone/artifacts/changes/CHNG-XXX/` for the referenced changes
- [ ] Each task has a size tag: [XS], [S], [M], or [L] (XL is forbidden)
- [ ] Task describes concrete WHAT + WHERE (specific class/endpoint/file)
- [ ] Task uses concrete verbs: add, fix, remove, configure, validate, create, update, extract, refactor
- [ ] Task avoids vague verbs: implement, build, develop, do, make, setup
- [ ] Task avoids scope bloat: and, all, entire, everything, system, module, feature, epic
- [ ] Each task does ONE thing; title containing "and" signals two tasks

**Failure:** Task is too vague, too large, or missing planning doc → blocked with break-down instructions.

**Exemptions:** Fix, bug, docs, refactor, chore, test, perf, ci, build, style tasks skip planning doc and size requirements.

### Gate I→V: Implementation → Validation

Before marking implementation complete:
- [ ] All requirements have corresponding code
- [ ] All requirements have corresponding tests
- [ ] Traceability matrix is updated
- [ ] `verify-traceability.sh` passes
- [ ] Build and tests pass

**Failure:** Task marked complete but traceability gaps exist → blocked with gap report.

**Mode affects gate behavior:**
- **Full mode:** All gates are blocking — cannot proceed without satisfying the gate
- **Standard mode:** Gates are blocking for feature work, advisory for fix/chore/docs
- **Light mode:** All gates are advisory (warn only) — useful for quick iterations

Override per-command with `--light` or `--deep` flags.

## Skill Enforcement

**Before writing ANY code**, you MUST acknowledge the required skill for that layer.

Projects using **DDD / Hexagonal Architecture** have three layers. Each layer has distinct rules and a matching skill:

| Layer | Purpose | What Goes Here | Required Skill |
|-------|---------|----------------|----------------|
| `domain/` | Business logic | Entities, value objects, domain events, domain services | `java/java-core` |
| `app/` | Use cases | Application services, use cases, queries, ports (interfaces) | `java/java-cdi` (Quarkus) / `springboot/springboot-di` (Spring) |
| `infra/` | Infrastructure | **REST controllers** (`infra/io/rest/`), DTOs (`infra/data/dto/`), persistence (`infra/data/persistence/`), config (`infra/config/`), external clients | `quarkus/java-quarkus` / `springboot/springboot-patterns` |

**Layer rules (non-negotiable):**
- `domain/` **must be framework-free** — no Quarkus, Spring, Jakarta, or Lombok imports
- `app/` orchestrates use cases via dependency injection — no framework annotations, only ports (interfaces)
- `infra/` contains **all** framework code — REST controllers live in `infra/io/rest/`, not a separate top-level package

**How to acknowledge:**
1. The `pre-tool-use-skill-check.sh` hook will block Write/Edit operations until the skill for that layer is acknowledged
2. Type `acknowledge` when prompted, OR load the skill first with `view backbone/skills/<layer-skill>/SKILL.md`
3. Acknowledgments persist for the session in `.backbone/session/skills.json`

**Task-linked skills:** If working on a WIP task with required skills listed in `3-TASKS.md`, acknowledge those at session start using `./scripts/acknowledge-skills.sh`.

**Cross-agent fallback:** OpenCode, Cursor, and other agents without PreToolUse hooks should run `./scripts/acknowledge-skills.sh` at session start. This pre-populates all layer skills so pre-commit Gate 14 passes.

## Agent Skills & Daily Workflows

Agents should use the project's local skills located in `backbone/skills/` for consistency. To load a skill: `view backbone/skills/<category>/<skill-name>/SKILL.md`

### Core Skills (Common Across Projects)

1. **Git Commits (`git-commit` skill):**
   - All commits should follow the project's commit format (typically Conventional Commits)
   - Explain WHAT and WHY, not HOW
   - Reference issues when applicable

2. **Testing (`test-quality` skill):**
   - Use the project's preferred testing framework and assertion library
   - Follow the Arrange-Act-Assert (AAA) pattern
   - Name tests descriptively
   - Target appropriate coverage on core business logic

3. **Issue Triage (`issue-triage` skill):**
   - Categorize and prioritize GitHub issues
   - Follow project SLAs for labeling and response times

## Coding Standards Enforcement

When generating code, the agent should:

1. Follow the project's language-specific conventions and best practices
2. Respect architectural boundaries (e.g., hexagonal/clean layers)
3. Use the project's preferred dependency injection/mechanisms
4. Use the project's preferred data access/persistence patterns

## Blocking Enforcement (Smart Gates)

The following gates **block** Write/Edit operations and commits. They are not suggestions.

### Pre-Tool Gates (Block Write/Edit)

| Gate | Trigger | How to Pass |
|------|---------|-------------|
| **Skill Acknowledgment** | Writing to domain/app/api layer without acknowledging skill | Type `acknowledge` or load skill |
| **Layer Violation** | Framework imports in domain/, wrong annotations in app/, etc. | Fix the code or mark task as `refactor` in 3-TASKS.md |
| **WIP Check** | No [WIP] task marked in 3-TASKS.md | Mark a task as [WIP] before writing code |
| **Review Gate R→D** | Attempting to write design doc without PRD | Create PRD first using `create-prd` skill |
| **Review Gate D→I** | Attempting to implement without design doc | Create design doc first (exempt: fix/docs/refactor/test) |

**Escape Hatches:**
- To bypass layer violation: Mark task as `[WIP] refactor: ...` in 3-TASKS.md
- To bypass skill check: Load the skill with `view backbone/skills/<path>/SKILL.md`
- To bypass WIP check: `export CLAUDE_CODE_SKIP_WIP_CHECK=1` (emergency only)

### Pre-Commit Gates (Block `git commit`)

| Gate | Trigger | How to Pass |
|------|---------|-------------|
| **Commit Format** | Every commit | Use Conventional Commits: `type(scope): description (min 10 chars)` |
| **Build Gate** | Source files changed | `./gradlew build` or `npm run build` must pass. Docs-only commits skip build. |
| **Secret Scan** | Any staged file | No AWS keys, tokens, passwords in staged files. Use `SKIP_SECRETS=1` to bypass. |
| **Version Gate** | `backbone/` files changed (except 3-TASKS.md, 6-MEMORY.md) | Update `backbone/VERSION` to today's date |

**Valid commit types:** `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `perf`, `ci`, `build`

**Examples:**
- `feat(portal): add worktree status dashboard`
- `fix(quarkus): resolve NPE in health check endpoint`
- `docs(backbone): update 3-TASKS.md with M3 progress`
- `security(backbone): add prompt injection guard`

## Definition of Done (For Agents)

A task is not complete until:

1. **Skill acknowledged** — Required skill for the layer has been acknowledged
2. **Security validated** — No prompt injection patterns, no secrets in code
3. **QMS: defects registered** — If a defect or nonconformance was discovered, an NCR was registered via `/backbone:qms` or `./scripts/qms-register-issue.sh`
4. **Success criteria defined** — The task was transformed into verifiable goals before coding (Backbone Principle #4)
4. The code adheres to the project's architectural boundaries
5. **English naming** — All identifiers (classes, methods, variables, constants, files, packages, tables, endpoints) are in English only. No mixed-language identifiers.
6. Required tests are written using the project's testing standards
7. If it touches the DB/persistence layer, integration tests are written (if applicable)
8. The project compiles/passes build checks successfully
8. **Live Documentation Updated:**
   - [ ] Decisions: Added to [`backbone/5-DECISIONS.md`](backbone/5-DECISIONS.md) (if applicable)
   - [ ] Memory: If lesson learned, add to [`backbone/6-MEMORY.md`](backbone/6-MEMORY.md) (if applicable)
   - [ ] Active Tasks: [`backbone/3-TASKS.md`](backbone/3-TASKS.md) updated with [WIP] before, [x] after
9. **Project Commit Process:**
    - After all verification passes, follow the project's commit process
    - Create a commit using the project's commit format
    - Stage all relevant files and commit with a descriptive message

*Adjust these steps based on project-specific requirements.*
