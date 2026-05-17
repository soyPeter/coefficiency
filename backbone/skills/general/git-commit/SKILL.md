<!-- FRAMEWORK: GENERAL -->
---
framework: general
name: git-commit
description: Generate conventional commit messages. Use when committing changes to ensure clear, descriptive history. Use for any code change — always commit with discipline.
---

# Git Commit Skill

Generate conventional commit messages that explain the *why*, not just the *what*. Commit history is documentation — treat it as such.

## When to Use

Always. Every code change flows through git.

## Core Principles

### Commit Early, Commit Often

Each successful increment gets its own commit. Don't accumulate large uncommitted changes.

```
Work pattern:
  Implement slice → Test → Verify → Commit → Next slice

Not this:
  Implement everything → Hope it works → Giant commit
```

### Atomic Commits

Each commit does one logical thing:

```
# Good: Each commit is self-contained
git log --oneline
a1b2c3d feat(portal): add task creation endpoint with validation
d4e5f6g feat(ui): add task creation form component
h7i8j9k feat(portal): connect form to API and add loading state
m1n2o3p test(portal): add task creation tests (unit + integration)

# Bad: Everything mixed together
git log --oneline
x1y2z3a feat(portal): add task feature, fix sidebar, update deps, refactor utils
```

### Descriptive Messages

Explain the *why*, not just the *what*:

```
# Good: Explains intent
feat(portal): add email validation to registration endpoint

Prevents invalid email formats from reaching the database.
Uses bean validation at the route handler level,
consistent with existing validation patterns.

# Bad: Describes what's obvious from the diff
update auth.ts
```

## Format

```
<type>(<scope>): <short description>

<optional body explaining why, not what>
```

## Types

| Type | Meaning | Example |
|------|---------|---------|
| `feat` | New feature | `feat(portal): add user authentication` |
| `fix` | Bug fix | `fix(templates): resolve gradle compatibility` |
| `refactor` | Code change that neither fixes a bug nor adds a feature | `refactor(core): extract validation logic` |
| `test` | Adding or updating tests | `test(portal): add registration tests` |
| `docs` | Documentation only | `docs(readme): add plugin development guide` |
| `chore` | Tooling, dependencies, config | `chore(ci): update GitHub Actions` |
| `perf` | Performance improvement | `perf(api): add connection pooling` |
| `ci` | CI/CD changes | `ci(actions): add parallel test jobs` |
| `build` | Build system changes | `build(gradle): upgrade to 8.12` |

## Scope

The scope identifies the part of the codebase affected:

| Scope | Meaning |
|-------|---------|
| `portal` | Dev Portal |
| `templates` | Project templates |
| `skills` | Skills directory |
| `scripts` | Build/utility scripts |
| `backbone` | Backbone core files |
| `hooks` | Git hooks |
| `core` | Core generator logic |

## Change Sizing

Target ~100 lines per commit/PR. Changes over ~1000 lines should be split.

```
~100 lines  → Easy to review, easy to revert
~300 lines  → Acceptable for a single logical change
~1000 lines → Too large, split it
```

## Pre-Commit Hygiene

Before every commit:

```bash
# 1. Check what you're about to commit
git diff --staged

# 2. Ensure no secrets
git diff --staged | grep -i "password\|secret\|api_key\|token"

# 3. Run tests
./gradlew test

# 4. Run linting/checks
./gradlew spotbugsMain checkstyleMain
```

## Change Summaries

After any modification, provide a structured summary:

```
CHANGES MADE:
- src/routes/tasks.ts: Added validation middleware to POST endpoint
- src/lib/validation.ts: Added TaskCreateSchema

THINGS I DIDN'T TOUCH (intentionally):
- src/routes/auth.ts: Has similar validation gap but out of scope

POTENTIAL CONCERNS:
- Added zod dependency (72KB) — already in package.json
```

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "I'll commit when the feature is done" | One giant commit is impossible to review, debug, or revert. |
| "The message doesn't matter" | Messages are documentation. Future you will need them. |
| "I'll squash it all later" | Squashing destroys the development narrative. |
| "I'll split this change later" | Large changes are harder to review, riskier to deploy. |

## Red Flags

- Large uncommitted changes accumulating
- Commit messages like "fix/update/misc"
- Formatting changes mixed with behavior changes
- Committing build artifacts or secrets
- Long-lived branches diverging from main

## Verification

For every commit:

- [ ] Commit does one logical thing
- [ ] Message explains the why, follows type conventions
- [ ] Tests pass before committing
- [ ] No secrets in the diff
- [ ] No formatting-only changes mixed with behavior changes
