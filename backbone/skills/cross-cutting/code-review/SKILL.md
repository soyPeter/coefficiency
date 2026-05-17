<!-- FRAMEWORK: GENERAL -->
---
framework: general
name: code-review
description: Multi-dimensional code review with quality gates. Use before merging any change. Use when reviewing code written by yourself, another agent, or a human.
---

# Code Review and Quality

Multi-dimensional code review with quality gates. Every change gets reviewed before merge — no exceptions.

## When to Use

- Before merging any PR or change
- After completing implementation
- When another agent or model produced code you need to evaluate
- When refactoring existing code
- After any bug fix

## The Five-Axis Review

### 1. Correctness

Does the code do what it claims to do?

- Does it match the spec or task requirements?
- Are edge cases handled (null, empty, boundary values)?
- Are error paths handled (not just the happy path)?
- Does it pass all tests? Are tests testing the right things?
- Are there off-by-one errors, race conditions, or state inconsistencies?

### 2. Readability & Simplicity

Can another engineer understand this without explanation?

- Are names descriptive and consistent?
- Is the control flow straightforward?
- Is the code organized logically?
- **Could this be done in fewer lines?**
- **Are abstractions earning their complexity?**
- Would comments help clarify non-obvious intent?

### 3. Architecture

Does the change fit the system's design?

- Does it follow existing patterns or introduce a new one?
- Does it maintain clean module boundaries?
- Is there code duplication that should be shared?
- Are dependencies flowing in the right direction?

### 4. Security

Does the change introduce vulnerabilities?

- Is user input validated and sanitized?
- Are secrets kept out of code, logs, and version control?
- Is authentication/authorization checked where needed?
- Are SQL queries parameterized?
- Are dependencies from trusted sources?

### 5. Performance

Does the change introduce performance problems?

- Any N+1 query patterns?
- Any unbounded loops or unconstrained data fetching?
- Any synchronous operations that should be async?
- Any missing pagination on list endpoints?

## Change Sizing

```
~100 lines changed   → Good. Reviewable in one sitting.
~300 lines changed   → Acceptable for single logical change.
~1000 lines changed  → Too large. Split it.
```

**Splitting strategies:**

| Strategy | How | When |
|----------|-----|------|
| Stack | Submit small change, start next based on it | Sequential dependencies |
| By file group | Separate changes for different reviewers | Cross-cutting concerns |
| Vertical | Break into smaller full-stack slices | Feature work |

## Review Comment Severity

| Prefix | Meaning | Action |
|--------|---------|--------|
| *(no prefix)* | Required change | Must address before merge |
| **Critical:** | Blocks merge | Security vulnerability, data loss, broken functionality |
| **Nit:** | Minor, optional | Author may ignore |
| **Optional:** / **Consider:** | Suggestion | Worth considering but not required |
| **FYI** | Informational only | No action needed |

## Review Process

1. **Understand context** — what is this change trying to accomplish?
2. **Review tests first** — reveal intent and coverage
3. **Review implementation** with five axes
4. **Categorize findings** with severity labels
5. **Verify verification story** — what tests were run? Build pass? Manual verification?

## Dead Code Hygiene

After any refactoring or implementation, check for orphaned code:

```
DEAD CODE IDENTIFIED:
- formatLegacyDate() in src/utils/date.ts — replaced by formatDate()
- OldTaskCard component — replaced by TaskCard
→ Safe to remove these?
```

Don't leave dead code — it confuses future readers. But don't silently delete things you're not sure about.

## Review Speed

- **Respond within one business day** — maximum, not target
- **Ideal:** Respond shortly after review request arrives
- **Large changes:** Ask author to split them rather than reviewing one massive changeset

## Dependency Discipline

Before adding any dependency:
1. Does the existing stack solve this?
2. How large is the dependency? (Check bundle impact.)
3. Is it actively maintained?
4. Does it have known vulnerabilities? (`npm audit` / `mvn dependency:check`)
5. What's the license?

**Rule:** Prefer standard library and existing utilities over new dependencies.

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "It works, that's good enough" | Working code that's unreadable or architecturally wrong creates debt that compounds. |
| "I wrote it, so I know it's correct" | Authors are blind to their own assumptions. Every change benefits from another set of eyes. |
| "We'll clean it up later" | Later never comes. The review is the quality gate — use it. |
| "AI-generated code is probably fine" | AI code needs more scrutiny, not less. It's confident and plausible, even when wrong. |
| "The tests pass, so it's good" | Tests are necessary but not sufficient. They don't catch architecture or security problems. |

## Red Flags

- PRs merged without review
- Review only checking if tests pass
- "LGTM" without evidence of actual review
- Security-sensitive changes without security review
- Large PRs "too big to review" (split them)
- No regression tests with bug fix PRs
- Accepting "I'll fix it later" — it never happens

## Verification

After review:

- [ ] All Critical issues resolved
- [ ] All Important issues resolved or deferred with justification
- [ ] Tests pass
- [ ] Build succeeds
- [ ] Verification story documented
