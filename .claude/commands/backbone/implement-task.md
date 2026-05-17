---
name: backbone:implement-task
description: Guide implementation of ONE task from 3-TASKS.md. Reads the design doc context, loads the correct layer skill, runs TDD cycle, updates traceability, and marks the task done.
argument-hint: "[--task <task-id>] [--layer domain|app|infra]"
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
Guide the implementation of a single task from 3-TASKS.md.

**When to use:**
- After `/backbone:design-feature` has created the plan and tasks
- You have a [WIP] task in 3-TASKS.md ready to implement
- You need the right skills loaded, traceability updated, and a TDD cycle

**Auto-detects:**
- Framework from `backbone/4-KNOWLEDGE.md`
- Layer from the task description (domain/app/infra keywords)
- REQ- IDs from the planning doc
- Implementation phase from the task text

**Flags:**
- `--task <task-id>` — Specify a task by ID or text match (otherwise picks first [WIP])
- `--layer domain|app|infra` — Override layer detection (default: auto-detect)
</objective>

<process>
## Step 0: Parse Arguments

- Extract `--task` (optional) — find task by substring match
- Extract `--layer` (optional) — override layer detection
- Detect framework from `backbone/4-KNOWLEDGE.md`

## Step 1: Read Context

Read these files for context (do NOT re-read if already in session memory):
- `backbone/3-TASKS.md` — Find the [WIP] task
- Planning doc for this feature (from task reference)
- Design doc for this feature (from planning doc reference)

Layer detection priority:
1. `--layer` flag if provided
2. Task text contains `domain/` → domain layer
3. Task text contains `app/` or `use case` or `service` → app layer
4. Task text contains `infra/` or `controller` or `repository` or `REST` → infra layer
5. Task text contains `test` or `Test` → test layer (only loads `test-quality`)
6. Fallback: ask user

## Step 2: Load Required Skills

Always loaded:
- `general/coding-standards/SKILL.md` — Naming, structure, English-only
- `cross-cutting/testing/test-quality/SKILL.md` — Prove-It pattern, AAA, test pyramid
- `general/incremental-implementation/SKILL.md` — Thin vertical slices, one thing
- `general/git-commit/SKILL.md` — Conventional commits with REQ- IDs
- `general/traceability/SKILL.md` — Update traceability matrix

Layer-specific skills:
- `domain/` → `java/java-core/SKILL.md` (framework-free domain logic)
- `app/` → framework CDI or patterns skill:
  - quarkus: `quarkus/java-quarkus/SKILL.md` + `java/java-cdi/SKILL.md`
  - springboot: `springboot/springboot-patterns/SKILL.md`
  - javalin: no CDI skill needed (manual DI)
  - laravel: `laravel/laravel-patterns/SKILL.md`
- `infra/` → framework-specific skill + optional extras:
  - If REST: framework REST patterns skill
  - If DB: `java/jpa-patterns/SKILL.md` or `cross-cutting/databases/postgres-patterns/SKILL.md`
  - If Docker/K8s: `cross-cutting/docker/docker-patterns/SKILL.md`
  - If messaging: `cross-cutting/messaging/outbox-pattern/SKILL.md`

## Step 3: Read Design Doc Section

- Find the section in the design doc relevant to this task
- Extract: data model changes, API contracts, sequence flows
- Confirm understanding with user (brief — one question)

## Step 4: TDD Cycle (One Vertical Slice)

For each thin slice of the task:

1. **Write test first** (using `test-quality` patterns: Arrange-Act-Assert)
   - Tag test with REQ- ID: `// REQ-AUTH-003`
   - Run the test — confirm it fails (red)
2. **Write implementation**
   - Add REQ- ID comment: `// REQ-AUTH-003`
   - Follow layer rules: no framework imports in domain, etc.
3. **Run the test** — confirm it passes (green)
4. **Refactor** if needed (clean)

## Step 5: Update Traceability

- Read `storage/traceability/<feature>.md`
- Fill in: `REQ-ID | Code File | Test File | Status`
- Mark covered REQ- IDs as `done`

## Step 6: Commit

- `git add` changed files
- Commit with conventional message including REQ- IDs:
  ```
  feat(auth): add user login endpoint
  
  Implements REQ-AUTH-003, REQ-AUTH-004
  ```

## Step 7: Mark Task Complete

- Mark task as `[x]` in `backbone/3-TASKS.md`
- If more tasks remain: suggest the next [WIP] task and offer to continue

</process>

<critical_rules>
- ALWAYS write tests first (TDD) unless user explicitly says skip
- ALWAYS tag code with REQ- ID comments
- ALWAYS update traceability after every task
- NEVER skip the layer skill — it defines the patterns for that layer
- NEVER mix layers in one task — if a task touches both domain and infra, split it
- NEVER implement outside the task scope — stay in the vertical slice
</critical_rules>

<success_criteria>
- [ ] Test written and passing (red → green)
- [ ] Code follows layer rules and framework conventions
- [ ] REQ- IDs tagged in code and commit message
- [ ] Traceability updated: REQ- → code file → test file → done
- [ ] Task marked [x] in 3-TASKS.md
- [ ] Conventional commit with REQ- references
</success_criteria>
