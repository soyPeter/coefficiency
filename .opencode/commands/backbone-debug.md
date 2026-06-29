---
description: Debug a problem with persistent sessions — scientific method + checkpoint protocol
agent: implementer
required-skills:
  - general/debugging-and-error-recovery
---

> **skill loading:** Read this command's `required-skills` frontmatter above. For each entry, check if `backbone/skills/<path>/SKILL.md` exists — if yes, `view` it; otherwise use `skill tool "<basename>"` as fallback.

Debug: $ARGUMENTS

## Subcommands

Parse $ARGUMENTS for subcommand (first word):

- `list`: List all debug sessions in `backbone/debug/`
- `status <slug>`: Show session state without resuming
- `continue <slug>`: Resume a session from its last state
- `<anything else>`: Start a new debug session

## New Session Flow

1. **Symptom gathering** — Ask user 5 questions:
   - What did you expect to happen?
   - What actually happened?
   - Error messages or stack traces?
   - When did this start / what changed?
   - Can you reproduce it reliably?

2. **Create session file** at `backbone/debug/{slug}.md` with YAML frontmatter:
   ```yaml
   state: observe  # observe → hypothesis → experiment → validate → resolved
   created: <timestamp>
   slug: <slug>
   ```

3. **Scientific method loop:**
   - **Observe** — Document symptoms, reproduction steps, environment
   - **Hypothesize** — Propose root cause with evidence. Create numbered hypotheses list
   - **Experiment** — Design minimal test to confirm/disprove. Spawn explorer agent if needed
   - **Validate** — Confirm fix, update session file, mark resolved

4. **Agent return types** (REQ-DBG-004.2):
   ```
   RESULT: COMPLETE
   ---
   Root cause identified and fix verified.
   
   RESULT: CHECKPOINT
   CHECKPOINT_TYPE: human-verify
   Checkpoint context: <what needs user input>
   ---
   
   RESULT: CHECKPOINT
   CHECKPOINT_TYPE: blocked
   Checkpoint context: <what's blocking>
   ---
   
   RESULT: FAILED
   ---
   INVESTIGATION INCONCLUSIVE
   Hypothesis eliminated: [list eliminated causes]
   Remaining candidates: [what wasn't tested yet]
   ```

5. **Update session file** after each step — state, hypotheses tested, results

## Continue Flow (`continue <slug>`)

1. Read `backbone/debug/{slug}.md` to restore full context
2. Resume from last state in the scientific method
3. If a checkpoint was pending, process checkpoint_response first
4. Continue the loop

## Cleanup

After resolution, mark session as `state: resolved` and offer to archive:
```
RESULT: COMPLETE
---
Root cause: <summary>
Fix: <summary>
Session archived to backbone/artifacts/archive/debug/
```
