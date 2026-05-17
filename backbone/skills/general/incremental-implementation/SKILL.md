<!-- FRAMEWORK: GENERAL -->
---
framework: general
name: incremental-implementation
description: Delivers changes incrementally using thin vertical slices. Use when implementing any feature that touches more than one file.
---

# Incremental Implementation

Build in thin vertical slices — implement one piece, test it, verify it, then expand. Each increment leaves the system in a working, testable state.

## When to Use

- Implementing any multi-file change
- Building a new feature from task breakdown
- Refactoring existing code
- Any time tempted to write more than ~100 lines before testing

## The Increment Cycle

```
Implement → Test → Verify → Commit → Next slice
```

## Slicing Strategies

### Vertical Slices (Preferred)

Build one complete path through the stack:

```
Slice 1: Create a task (DB + API + basic UI)
    → Tests pass, user can create a task

Slice 2: List tasks (query + API + UI)
    → Tests pass, user can see their tasks

Slice 3: Edit a task (update + API + UI)
    → Tests pass, user can modify tasks
```

### Contract-First Slicing

When backend and frontend develop in parallel:

```
Slice 0: Define API contract (types, interfaces, OpenAPI spec)
Slice 1a: Implement backend against contract + API tests
Slice 1b: Implement frontend against mock data matching contract
Slice 2: Integrate and test end-to-end
```

### Risk-First Slicing

Tackle the riskiest piece first:

```
Slice 1: Prove the WebSocket connection works (highest risk)
Slice 2: Build real-time updates on proven connection
Slice 3: Add offline support and reconnection
```

## Implementation Rules

### Rule 0: Simplicity First

Before writing code, ask: "What is the simplest thing that could work?"

After writing, review:
- Can this be done in fewer lines?
- Are these abstractions earning their complexity?
- Am I building for hypothetical future requirements?

### Rule 0.5: Scope Discipline

Touch only what the task requires. Do NOT:
- "Clean up" adjacent code
- Refactor imports in files you're not modifying
- Add features not in the spec

If you notice something worth improving, note it — don't fix it:

```
NOTICED BUT NOT TOUCHING:
- src/utils/DateUtils.java has unused import (unrelated)
→ Want me to create tasks for these?
```

### Rule 1: One Thing at a Time

Each increment changes one logical thing. Don't mix concerns.

### Rule 2: Keep It Compilable

After each increment, the project must build and existing tests must pass.

### Rule 3: Feature Flags for Incomplete Features

```java
// Feature flag for work-in-progress
if (featureFlags.isEnabled("task-sharing", userId)) {
    // New sharing UI
}
```

### Rule 4: Safe Defaults

New code defaults to safe, conservative behavior:

```java
// Safe: disabled by default, opt-in
public Task createTask(TaskInput input, boolean notify) {
    boolean shouldNotify = notify; // explicit, not defaulting to true
    // ...
}
```

### Rule 5: Rollback-Friendly

Each increment should be independently revertable.

## Verification

After each increment:

- [ ] Change does one thing and does it completely
- [ ] All existing tests still pass
- [ ] Build succeeds
- [ ] Type checking passes
- [ ] Linting passes
- [ ] New functionality works as expected
- [ ] Committed with descriptive message

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "I'll test it all at the end" | Bugs compound. A bug in Slice 1 makes Slices 2-5 wrong. |
| "It's faster to do it all at once" | It feels faster until something breaks and you can't find which of 500 lines caused it. |
| "These changes are too small to commit separately" | Small commits are free. Large commits hide bugs. |

## Red Flags

- More than 100 lines without running tests
- Multiple unrelated changes in one increment
- "Let me just quickly add this too" scope expansion
- Build or tests broken between increments
- Large uncommitted changes accumulating
