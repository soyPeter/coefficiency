# Writing Agent Briefs

An agent brief is a structured comment posted when an issue moves to `ready-for-agent`. It is the authoritative specification that an AFK agent will work from.

## Principles

### Durability Over Precision

The issue may sit for days or weeks. The codebase will change.

- **Do** describe interfaces, types, and behavioral contracts
- **Do** name specific types, function signatures, or config shapes
- **Don't** reference file paths — they go stale
- **Don't** reference line numbers
- **Don't** assume the current implementation structure will remain

### Behavioral, Not Procedural

Describe **what** the system should do, not **how** to implement it.

- **Good:** "The `SkillConfig` type should accept an optional `schedule` field of type `CronExpression`"
- **Bad:** "Open src/types/skill.ts and add a schedule field on line 42"

### Complete Acceptance Criteria

Every agent brief must have concrete, testable acceptance criteria.

- **Good:** "Running `npm test` passes with no failures"
- **Bad:** "Triage should work correctly"

### Explicit Scope Boundaries

State what is out of scope.

## Template

```markdown
## Agent Brief

**Category:** bug / enhancement
**Summary:** one-line description

**Current behavior:**
Describe what happens now.

**Desired behavior:**
Describe what should happen. Be specific about edge cases.

**Key interfaces:**
- `TypeName` — what needs to change and why
- `functionName()` return type — current vs desired
- Config shape — any new options needed

**Acceptance criteria:**
- [ ] Specific, testable criterion 1
- [ ] Specific, testable criterion 2
- [ ] Specific, testable criterion 3

**Out of scope:**
- Thing that should NOT be changed
- Adjacent feature that is separate
```
