<!-- FRAMEWORK: GENERAL -->
---
framework: general
name: planning-and-task-breakdown
description: Decomposes work into small, verifiable tasks with explicit acceptance criteria. Use when you have a spec and need implementable units.
---

# Planning and Task Breakdown

Decomposes work into small, verifiable tasks with explicit acceptance criteria.

## When to Use

- You have a spec and need to break it into implementable units
- A task feels too large or vague to start
- Work needs to be parallelized
- Implementation order isn't obvious

**Not for:** Single-file changes with obvious scope.

## Process

### Step 1: Enter Plan Mode

Read-only phase:
- Read the spec and relevant codebase
- Identify existing patterns and conventions
- Map dependencies between components
- Note risks and unknowns

**Do NOT write code during planning.**

### Step 2: Identify the Dependency Graph

Map what depends on what, implement bottom-up:

```
Database schema
    |
    +-- API models/types
    |       |
    |       +-- API endpoints
    |       |       |
    |       |       +-- Frontend API client
    |       |               |
    |       |               +-- UI components
    |       |
    |       +-- Validation logic
    |
    +-- Seed data / migrations
```

### Step 3: Slice Vertically

**Bad (horizontal):**
```
Task 1: Build entire database schema
Task 2: Build all API endpoints
Task 3: Build all UI components
```

**Good (vertical slices):**
```
Task 1: User can create an account (schema + API + UI)
Task 2: User can log in (auth + API + UI)
Task 3: User can create a task (task schema + API + UI)
```

### Step 4: Write Tasks

Each task:

```markdown
## Task [N]: [Short descriptive title]

**Description:** One paragraph explaining what this task accomplishes.

**Acceptance criteria:**
- [ ] [Specific, testable condition]
- [ ] [Specific, testable condition]

**Verification:**
- [ ] Tests pass: ./gradlew test --tests "FeatureNameTest"
- [ ] Build succeeds: ./gradlew build
- [ ] Manual check: [description]

**Dependencies:** [Task numbers, or "None"]

**Files likely touched:**
- src/path/to/file.java
- tests/path/to/test.java

**Estimated scope:** [XS/S/M/L]  (XL is forbidden -- break it down)
```

### Step 5: Order and Checkpoint

Arrange tasks so that:
1. Dependencies are satisfied (build foundation first)
2. Each task leaves the system in a working state
3. Checkpoints after every 2-3 tasks
4. High-risk tasks are early (fail fast)

## Task Sizing

| Size | Files | Scope | Example |
|------|-------|-------|---------|
| XS | 1 | Single function/config | Add validation rule |
| S | 1-2 | One component/endpoint | Add API endpoint |
| M | 3-5 | One feature slice | User registration flow |
| L | 5-8 | Multi-component | Search with filtering |
| XL | 8+ | **Too large — break down** | — |

**When to break down further:**
- Would take more than one focused session (2+ hours)
- Cannot describe acceptance criteria in 3 or fewer bullet points
- Touches two or more independent subsystems
- Title contains "and" (sign of two tasks)

## Writing Tasks for 3-TASKS.md

When you write tasks to [`backbone/3-TASKS.md`](backbone/3-TASKS.md), you MUST follow this format:

```markdown
- [ ] [S] feat: add email regex validator to UserRegistrationUseCase
- [ ] [M] feat: create OrderPlaced domain event with JSON serialization
- [ ] [XS] fix: remove unused import from JwtAuthenticationFilter
```

### Size Tags (REQUIRED)

| Size | Files | Scope | Example |
|------|-------|-------|---------|
| XS | 1 | Single function/config | Add validation rule |
| S | 1-2 | One component/endpoint | Add API endpoint |
| M | 3-5 | One feature slice | User registration flow |
| L | 5-8 | Multi-component | Search with filtering |
| XL | 8+ | **FORBIDDEN** | Break it down |

### Verb Rules

**Concrete (use these):** add, fix, remove, configure, validate, create, update, extract, refactor

**Vague (avoid these):** implement, build, develop, do, make, setup

### Scope Bloat Words (forbidden in task titles)

`and`, `all`, `entire`, `everything`, `system`, `module`, `feature`, `epic`

If a task title contains "and", that's two tasks.

### Mechanical Enforcement

- `pre-tool-use-task-granularity-check.sh` blocks [WIP] tasks that fail these rules
- Pre-commit Gate 12 validates staged 3-TASKS.md changes
- Override: `export CLAUDE_CODE_SKIP_GRANULARITY=1`

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "I'll figure it out as I go" | That's how you end up with a tangled mess. 10 min of planning saves hours. |
| "The tasks are obvious" | Write them down anyway. Explicit tasks surface hidden dependencies. |
| "Planning is overhead" | Planning is the task. Implementation without a plan is just typing. |

## Red Flags

- Starting implementation without a written task list
- Tasks without acceptance criteria
- No verification steps
- All tasks are XL-sized
- No checkpoints between tasks
