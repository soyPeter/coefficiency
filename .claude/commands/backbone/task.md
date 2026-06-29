---
name: backbone:task
description: Execute tasks with TDD — supports parallel, wave, and interactive modes
argument-hint: "<task-description> [--quick|--light|--deep] [--changelog <msg>] [--parallel] [--wave N] [--interactive]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - Task
---

Execute tasks with the description: $ARGUMENTS

## Mode Detection

Check $ARGUMENTS for mode flags (first match wins):
- `--parallel`: Wave-based parallel execution (REQ-PAR-001)
- `--wave N`: Execute only wave N (REQ-PAR-001.1)
- `--interactive`: Sequential with user checkpoints (REQ-PAR-001.2)
- `--compact`: Enable caveman output compression for token savings (~65%) (REQ-COMPACT-001)
- `--loop <cadence>`: Run on repeat until `/goal` condition is met (REQ-LOOP-001). Cadence: `30m`, `1h`, `nightly`, `pr`, `monitor`
- `--goal <condition>`: Stop condition checked by a separate verifier subagent (REQ-LOOP-002). Example: `--goal "All auth tests pass and lint is clean"`
- Default: Single task mode (one [WIP] task at a time)

If `--compact` is set, load `view backbone/skills/general/caveman-compact/SKILL.md` and apply `full` level compression for all output during this task. Switch back to normal mode after task completes.

If `--loop` is set without `--goal`, the loop runs once per cadence indefinitely (prompt user for stop condition on first run). If `--loop` + `--goal` are both set, see Loop Mode below.

### Pre-Flight (All Modes)

1. **Check progress ledger** — If resuming after compaction, check `.backbone/ledger/progress.md` and `git log --oneline -5` to ensure no completed tasks are re-dispatched.
2. **Read shared language** — Read `backbone/artifacts/changes/CHNG-XXX/CONTEXT.md` if it exists. Use domain terminology from the glossary in all code and communications.
3. **Check decision log** — Read `backbone/artifacts/changes/CHNG-XXX/decisions.md` if it exists. Don't re-decide settled questions.
4. **Load YAGNI ladder** — Before writing code, load the Ponytail protocol (`view backbone/skills/general/coding-standards/SKILL.md`): need it? stdlib? native? dep? one line? minimum. Never cut validation, security, data-loss prevention, a11y.
5. **Loop pre-flight check (if --loop set)** — Run the 4-condition test before building a loop (REQ-LOOP-CHK-001):
   1. Task repeats at least weekly? If not, a single prompt wins.
   2. Automated verification exists? A test/type check/linter can reject bad output.
   3. Token budget can absorb waste? Loops re-read context and retry.
   4. Agent has runtime access? Can run the code it writes and see what breaks.
   If any condition fails, warn and revert to single-task mode.

### Loop Mode (--loop <cadence> --goal <condition>)

Loop mode turns a task into an unattended automation. The task repeats on a cadence until an objective condition is met, checked by a separate verifier subagent.

```
/backbone:task --loop 30m --goal "All auth tests pass and lint is clean"
  Scan src/auth for failures, propose fixes in claude/auth-fixes,
  open draft PR when goal condition holds.
```

#### Cadence Values
- `30m`, `1h`, `2h` — Session-scoped loop. Re-runs every N minutes within the current session.
- `nightly` — Designed for scheduled tasks. One run per day.
- `pr` — Event-triggered. Runs on every PR open/push event.
- `monitor` — Runs, checks goal, sleeps if not met, re-checks on file changes.

#### State File (REQ-LOOP-STATE-001)
Loop mode creates a state file at `.backbone/state/<task-slug>.md` that persists across runs:

```markdown
# Loop State: <task>

## Last Run
<date> UTC · <N> iterations, <N>/<N> passed

## In Progress
- <branch> — status

## Completed This Session
- <branch> → merged (goal met)

## Escalated to Human
- <file> — reason (root cause unclear, not a code issue)

## Lessons Learned
- <date>: <finding>
```

The state file is the loop's memory. Without it, every run restarts from zero.

#### Process
1. **Check state** — Read `.backbone/state/<slug>.md`. If last run already met the goal, exit.
2. **Load skill** — Read task context + any loop-specific skill (e.g., ci-triage).
3. **Execute** — Run the task implementation.
4. **Verify goal** — Dispatch a separate verifier subagent to check the goal condition. The verifier is a fresh agent with no context from the implementation step (maker/checker split). If it reports the goal as met, proceed. If not, loop.
5. **Record** — Update state file with results, lessons, escalations.
6. **Decide** — If goal met: mark done, log to progress ledger, commit, open PR. If goal not met and iterations < max: wait for cadence and re-run. If goal not met and iterations >= max: escalate to human.
7. **Hard stop** — Loop has a max iteration cap (default 10). After that, it escalates rather than burning tokens indefinitely.

#### Maker/Checker Split (REQ-LOOP-MCK-001)
The implementer and the verifier are always separate subagents. The verifier:
- Is a fresh agent (no inherited context from the implementer)
- Gets only: the goal condition, the diff, and the test results
- Returns: GOAL_MET | GOAL_NOT_MET + evidence
- Runs on a capable model (not the cheapest)

#### Failure Modes Documented (REQ-LOOP-FML-001)
- **Ralph Wiggum**: Loop emits completion early. Mitigation: separate verifier, not the implementer grading itself.
- **Goal drift**: Constraints disappear after multiple iterations. Mitigation: re-read goal from state file each cycle.
- **Token waste**: Re-reading context every cycle burns tokens. Mitigation: `--compact` flag + max iterations cap.
- **Comprehension debt**: Code shipped that no human has read. Mitigation: human reviews all PRs before merge.

### Single Task Mode
1. Read `backbone/3-TASKS.md` to find the [WIP] task
2. Read `backbone/artifacts/changes/CHNG-XXX/` for full context (proposal, design, tasks)
3. Load [`backbone/skills/general/coding-standards/SKILL.md`](backbone/skills/general/coding-standards/SKILL.md)
4. Implement with REQ- ID tags in code comments
5. For full/standard mode: write tests first (TDD)
6. **Self-review (REQ-SRV-001)** — Before marking done, check: YAGNI applied? No over-engineering? Edge cases handled? Tests pass? No debugging artifacts left?
7. **Record decision** — If a meaningful choice was made during implementation, append it to `backbone/artifacts/changes/CHNG-XXX/decisions.md`
8. Run tests, fix until green
9. Update `backbone/artifacts/traceability/` with implementation details
10. Mark task [x] in `backbone/3-TASKS.md`

### Parallel Mode (--parallel)
1. Read `backbone/3-TASKS.md` to find all [ ] tasks in the current change
2. Source `scripts/lib/bb-tools.sh` and call `bb_topological_sort` to build wave DAG
3. If `--wave N` specified, only execute wave N; otherwise execute all waves sequentially
4. Per wave: spawn parallel subagents (one per task), each receives full task context. Use file-based handoffs:
   - Extract task brief: `bash scripts/task-brief.sh backbone/artifacts/changes/CHNG-XXX/tasks.md N`
   - Pass brief file path to subagent (not pasted text)
   - Subagent writes results to report file, returns only status line
5. Collect all results per wave before advancing to next
6. If any subagent returns `RESULT: CHECKPOINT`, pause wave and present to user
7. If any subagent returns `RESULT: FAILED`, log failure but continue wave
8. After all waves complete, aggregate results and mark completed tasks
9. **Update progress ledger (REQ-HOFF-002)** — Append completed tasks to `.backbone/ledger/progress.md`:
   ```bash
   mkdir -p .backbone/ledger
   echo "Task N: complete (commits $(git rev-parse HEAD~1 | head -c7)..$(git rev-parse HEAD | head -c7), review clean)" >> .backbone/ledger/progress.md
   ```

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
