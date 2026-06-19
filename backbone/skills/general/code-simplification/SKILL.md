<!-- FRAMEWORK: GENERAL -->
---
framework: general
name: code-simplification
description: Simplifies code for clarity without changing behavior, with both manual and automated modes. Use when code works but is harder to read, maintain, or extend than it should be, or when reviewing a diff for cleanup opportunities.
---

# Code Simplification

Simplify code by reducing complexity while preserving exact behavior. The goal is code easier to read, understand, modify, and debug.

## When to Use

- After a feature works but implementation is heavier than needed
- During code review when complexity issues flagged
- Encountering deeply nested logic, long functions, unclear names
- Refactoring code written under time pressure
- After merging changes with duplication

**Not for:** Code already clean; code you don't understand yet; performance-critical code.

## The Five Principles

### 1. Preserve Behavior Exactly

All inputs, outputs, side effects, error behavior must remain identical. If unsure a simplification preserves behavior, don't make it.

### 2. Follow Project Conventions

Simplification means consistency with the codebase, not imposing external preferences.

### 3. Prefer Clarity Over Cleverness

Explicit code is better than compact code requiring a mental pause.

### 4. Maintain Balance

Watch for over-simplification:
- Inlining too aggressively
- Combining unrelated logic
- Removing necessary abstraction
- Optimizing for line count

### 5. Scope to What Changed

Default to simplifying recently modified code. Avoid drive-by refactors.

## The Simplification Process

### Step 1: Understand Before Touching (Chesterton's Fence)

Before changing anything, understand why it exists:
- What is this code's responsibility?
- What calls it? What does it call?
- What are edge cases and error paths?
- Why might it have been written this way?
- Check git blame for original context

### Step 2: Identify Opportunities

**Structural complexity:**

| Pattern | Signal | Simplification |
|---------|--------|----------------|
| Deep nesting (3+ levels) | Hard to follow | Extract guard clauses or helpers |
| Long functions (50+ lines) | Multiple responsibilities | Split into focused functions |
| Nested ternaries | Requires mental stack | Replace with if/else or lookup |
| Boolean parameter flags | Confusing call sites | Options objects or separate functions |
| Repeated conditionals | Same if check in multiple places | Extract predicate function |

**Naming:**

| Pattern | Signal | Fix |
|---------|--------|-----|
| Generic names | `data`, `result`, `temp` | Rename to describe content |
| Abbreviated names | `usr`, `cfg`, `btn` | Use full words |
| Misleading names | `get` that also mutates | Rename to reflect behavior |
| Comments explaining "what" | `// increment counter` | Delete — code is clear enough |
| Comments explaining "why" | `// Retry because API is flaky` | Keep — they carry intent |

**Redundancy:**

| Pattern | Signal | Fix |
|---------|--------|-----|
| Duplicated logic | Same 5+ lines in multiple places | Extract shared function |
| Dead code | Unreachable branches, unused variables | Remove (after confirming dead) |
| Unnecessary abstractions | Wrapper adding no value | Inline the wrapper |
| Over-engineered patterns | Factory-for-a-factory | Replace with simple direct approach |

### Step 3: Apply Changes Incrementally

Make one simplification at a time. Run tests after each.

**Submit refactoring separately from feature or bug fix changes.**

**The Rule of 500:** If refactoring touches >500 lines, use automation (codemods, AST transforms) rather than hand editing.

### Step 4: Verify the Result

Compare before and after:
- Is the simplified version genuinely easier to understand?
- Did you introduce any new patterns inconsistent with the codebase?
- Is the diff clean and reviewable?
- Would a teammate approve this change?

## Verification

- [ ] All existing tests pass without modification
- [ ] Build succeeds with no new warnings
- [ ] Linter/formatter passes
- [ ] Each simplification is incremental and reviewable
- [ ] Diff is clean — no unrelated changes
- [ ] Simplified code follows project conventions
- [ ] No error handling removed or weakened
- [ ] No dead code left behind

## Phase 2 — Automated (Diff Review)

When reviewing a diff (after changes), use the automated parallel-agent pattern instead of manual analysis.

### How Automated Mode Works

Launch 4 independent review agents via the Task tool, all in a single message so they run concurrently. Pass each agent the diff and one of the four angles below. Each returns its findings with `file`, `line`, a one-line `summary`, and the concrete cost (what is duplicated, wasted, or harder to maintain).

### Angle 1 — Reuse

Look for copy-pasted blocks that should be unified, missed abstractions (existing helper ought to be used but isn't), and repeated conditionals or expressions that signal a missing variable or function. Focus on what the author could have reused but didn't.

### Angle 2 — Simplification

Look for unnecessarily complex constructs: deep nesting that guard clauses or early returns would flatten, ternaries chained beyond two terms, boolean parameter flags that force reader to check the call site, over-abstracted indirection (factory-for-a-factory), and dead or unreachable code.

### Angle 3 — Efficiency

Look for wasted work: recomputing the same value in a loop, re-parsing or re-fetching data already available, N+1 query patterns, redundant sorting or filtering, and unnecessary allocations or copies in hot paths.

### Angle 4 — Altitude

Look for code in the wrong layer (business logic leaking into a controller, UI formatting in a service), misplaced responsibilities (a function doing two unrelated things), and files or functions that have outgrown their original purpose. Question whether each change belongs where it landed.

### Apply Phase

Wait for all four agents to complete, dedup findings that point at the same line or mechanism, and fix each remaining one directly. Skip any finding whose fix would change intended behavior, require changes well outside the reviewed diff, or that you judge to be a false positive — note the skip rather than arguing with it. Finish with a brief summary of what was fixed and what was skipped (or confirm the code was already clean).

## Red Flags

- Simplification requires test modification (behavior changed)
- "Simplified" code is harder to follow
- Removing error handling because "it makes code cleaner"
- Simplifying code you don't fully understand
- Batching many simplifications into one large commit
- Refactoring outside scope without being asked
