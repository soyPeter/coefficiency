---
description: Execute tasks with TDD — supports parallel, wave, and interactive modes
agent: implementer
required-skills:
  - general/coding-standards
  - general/test-quality
  - general/incremental-implementation
  - general/git-commit
  - general/traceability
---

> **skill loading:** Read this command's `required-skills` frontmatter above. For each entry, check if `backbone/skills/<path>/SKILL.md` exists — if yes, `view` it; otherwise use `skill tool "<basename>"` as fallback.

Execute tasks with the description: $ARGUMENTS

## Mode Detection

Check $ARGUMENTS for mode flags (first match wins):
- `--parallel`: Wave-based parallel execution (REQ-PAR-001)
- `--wave N`: Execute only wave N (REQ-PAR-001.1)
- `--interactive`: Sequential with user checkpoints (REQ-PAR-001.2)
- Default: Single task mode (one [WIP] task at a time)

### Single Task Mode
1. Read `backbone/3-TASKS.md` to find the [WIP] task
2. Read `backbone/artifacts/changes/CHNG-XXX/` for full context (proposal, design, tasks)
3. Load [`backbone/skills/general/coding-standards/SKILL.md`](backbone/skills/general/coding-standards/SKILL.md)
4. Implement with REQ- ID tags in code comments
5. For full/standard mode: write tests first (TDD)
6. Run tests, fix until green
7. Update `backbone/artifacts/traceability/` with implementation details
8. Mark task [x] in `backbone/3-TASKS.md`

### Parallel Mode (--parallel)
1. Read `backbone/3-TASKS.md` to find all [ ] tasks in the current change
2. Source `scripts/lib/bb-tools.sh` and call `bb_topological_sort` to build wave DAG
3. If `--wave N` specified, only execute wave N; otherwise execute all waves sequentially
4. Per wave: spawn parallel subagents (one per task), each receives full task context
5. Collect all results per wave before advancing to next
6. If any subagent returns `RESULT: CHECKPOINT`, pause wave and present to user
7. If any subagent returns `RESULT: FAILED`, log failure but continue wave
8. After all waves complete, aggregate results and mark completed tasks

### Interactive Mode (--interactive)
1. Read `backbone/3-TASKS.md` to find all [ ] tasks in the current change
2. For each task: present task description and ask user "Execute this task?"
3. On confirm: execute task inline (no subagent) with user checkpoints between steps
4. On skip: move to next task
5. After each task: ask user "Continue to next task?"

Read `backbone/.MODE`:
- `full`: TDD (red → green → refactor) + mandatory code review after
- `standard`: TDD cycle
- `light`: Skip TDD, commit directly
