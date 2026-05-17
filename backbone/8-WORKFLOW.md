<!-- VERSION: 2026.04.29 -->
# 8. AI Agent Execution Workflow

*Standard operating procedure for AI agents when working on projects using this backbone.*

## Phase Execution Checklist

Before making changes, the agent MUST:

1. **Read `4-KNOWLEDGE.md`** to understand the tech stack and project constraints.
2. **Read `backbone/reference/conventions/jooby.md`** to understand framework-specific syntax mappings.
   - *The framework name is defined in 4-KNOWLEDGE.md (e.g., quarkus-conventions.md, springboot-conventions.md)*
3. **Grill before PRD** — For feature work, use the `grill-me` skill to stress-test requirements before writing the PRD.
   - Load: `view backbone/skills/general/grill-me/SKILL.md`
   - After grilling, add `grilled: true` to the PRD frontmatter.
   - *Exempt: fix, bug, docs, refactor, chore, test tasks.*
4. **Read `1-PRD.md`** to verify a PRD exists for the feature/task. If none exists, create one using the `create-prd` skill before proceeding.
5. **Read `3-TASKS.md`** to identify the current objective.
   - Ensure [WIP] tasks follow granularity rules: size tag [XS/S/M/L], concrete WHAT+WHERE, no scope bloat.
6. **Acknowledge Required Skills** for the task/workspace.
7. **(Optional) Context7 Live Docs** — This project has Context7 configured as an MCP server for up-to-date library documentation. When writing code that uses framework or library APIs, use `resolve-library-id` + `query-docs` to verify current API signatures and prevent hallucinated calls. Requires `CONTEXT7_API_KEY` — see `backbone/4-KNOWLEDGE.md` for setup.

## Review Gates (Blocking)

Review gates enforce quality checkpoints between SDD phases. The `review-gate-check.sh` hook blocks Write/Edit when gates are not satisfied.

### Gate G→P: Grilling → PRD

Before creating a PRD for feature work:
- [ ] Agent has used the `grill-me` skill to stress-test requirements
- [ ] Scope, boundaries, data model, and edge cases are clarified
- [ ] PRD frontmatter includes `grilled: true`

**Failure:** Agent attempts to write PRD without grill evidence → blocked with instructions to grill first.

**Exemptions:** Fix, bug, docs, refactor, chore, test tasks skip grilling.

### Gate R→D: Requirements → Design

Before creating a design document:
- [ ] PRD exists in `backbone/prd/`
- [ ] PRD has `grilled: true` in frontmatter (feature work only)
- [ ] Requirements are in EARS format with unique IDs
- [ ] Acceptance criteria are defined for each requirement
- [ ] PRD is referenced from `3-TASKS.md`

**Failure:** Agent attempts to write design doc without approved PRD → blocked with instructions to create PRD first.

### Gate D→I: Design → Implementation

Before writing implementation code:
- [ ] Design doc exists in `backbone/design/`
- [ ] C4 model covers Context, Container, and Component levels
- [ ] ADRs document all significant architectural decisions
- [ ] API contracts define request/response schemas
- [ ] Traceability links requirements to design sections
- [ ] Design doc is referenced from `3-TASKS.md`

**Failure:** Agent attempts to implement without design doc → blocked with instructions to create design doc first.

**Exemptions:** Fix, docs, refactor, chore, test tasks do not require design docs.

### Gate P→T: Planning → Tasks

Before marking tasks as [WIP] in `3-TASKS.md`:
- [ ] Planning doc exists in `backbone/planning/` for the referenced PRD
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
3. **Success criteria defined** — The task was transformed into verifiable goals before coding (Backbone Principle #4)
4. The code adheres to the project's architectural boundaries
5. **English naming** — All identifiers (classes, methods, variables, constants, files, packages, tables, endpoints) are in English only. No mixed-language identifiers.
6. Required tests are written using the project's testing standards
7. If it touches the DB/persistence layer, integration tests are written (if applicable)
8. The project compiles/passes build checks successfully
8. **Live Documentation Updated:**
   - [ ] Decisions: Added to `backbone/5-DECISIONS.md` (if applicable)
   - [ ] Memory: If lesson learned, add to `backbone/6-MEMORY.md` (if applicable)
   - [ ] Active Tasks: `backbone/3-TASKS.md` updated with [WIP] before, [x] after
9. **Project Commit Process:**
    - After all verification passes, follow the project's commit process
    - Create a commit using the project's commit format
    - Stage all relevant files and commit with a descriptive message

*Adjust these steps based on project-specific requirements.*
