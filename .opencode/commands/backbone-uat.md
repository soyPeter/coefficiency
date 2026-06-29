---
description: Conversational UAT — present test scenarios one at a time, pass/fail, auto-diagnose
agent: implementer
required-skills:
  - general/test-quality
  - general/debugging-and-error-recovery
---

> **skill loading:** Read this command's `required-skills` frontmatter above. For each entry, check if `backbone/skills/<path>/SKILL.md` exists — if yes, `view` it; otherwise use `skill tool "<basename>"` as fallback.

Run conversational UAT: $ARGUMENTS

## Mode Detection

Parse $ARGUMENTS:
- `--resume`: Continue from last unanswered scenario in an active UAT session
- `<nothing else>`: Start new UAT session for the active CHNG folder

## Process

### New Session
1. Read `backbone/3-TASKS.md` to find the active change folder
2. Read `backbone/artifacts/changes/CHNG-XXX/tasks.md` to extract test scenarios
3. Load skill `test-quality` for scenario construction standards
4. Create `backbone/artifacts/changes/CHNG-XXX/uat.md` session file
5. For each task in tasks.md:
   a. Present task description + ask user "Does this work as expected?"
   b. User responds in plain text: `pass` or `fail` (with details)
   c. On `pass`: Mark `[x] PASS` in uat.md, log optional notes
   d. On `fail`:
      - Diagnose root cause (read relevant files, check outputs)
      - Generate fix plan (specific file changes needed)
      - Offer to execute fixes: "Create fix tasks and run?"
      - If accepted: mark task with `[FIX]`, generate fix tasks, offer gaps-only execution
   e. Save progress to uat.md after each scenario

### Resume Session (--resume)
1. Find the active change folder
2. Read `backbone/artifacts/changes/CHNG-XXX/uat.md`
3. Find the last `[ ] PENDING` scenario
4. Resume from that point following the same flow

## Session File Format

```markdown
# UAT: CHNG-038

**Started:** 2026-06-13T10:00:00Z
**Resume-Point:** 3

## Scenario 1: Wave-based execution runs parallel subagents
- [x] PASS — All subagents executed concurrently
- Notes: 3 tasks in wave 1, all completed in 4.2s

## Scenario 2: Checkpoint returns control to user mid-execution
- [ ] PENDING

## Scenario 3: Debug sessions persist across context resets
- [ ] PENDING
```

## Completion

After all scenarios processed:
- Generate summary: X pass, Y fail, Z skipped
- Offer to execute fix plans for failed scenarios
- If all pass: mark UAT complete in session file
- If fixes applied: suggest running `/backbone:review --depth quick` for regression
