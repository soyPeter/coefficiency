---
name: backbone:overnight
description: Start an autonomous overnight (gnhf) run — agents work while you sleep. Requires npm install -g gnhf.
argument-hint: "<task-description> [--agent claude|opencode|codex] [--max-iterations N] [--max-tokens N] [--companion]"
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
  - Grep
required-skills:
  - general/gnhf
---

<objective>
Start a gnhf autonomous loop that runs agents until a stop condition is met.
Each iteration makes one committed change. You wake up to a branch of clean work.

**When to use:**
- User says they're going to sleep / leaving and wants work to continue
- Long-running multi-hour task that doesn't need human steering
- Parallel agent work on independent tasks using worktrees
- Repetitive tasks like "refactor all X to Y" or "add tests for module Z"

**Flags:**
- `--agent <name>` — Agent to use (claude, opencode, codex; default: claude)
- `--max-iterations <n>` — Stop after N iterations (default: 20)
- `--max-tokens <n>` — Stop after N total tokens (default: 5000000)
- `--companion` — Companion mode: poll progress and steer between iterations
- `--worktree` — Run in isolated worktree (default: true for feature work)
</objective>

<steps>
1. **Load the gnhf skill** — `view backbone/skills/general/gnhf/SKILL.md`
2. **Verify prerequisites** — `gnhf --help`, clean git status, note current branch
3. **Prepare the prompt** — Include objective, constraints, non-goals, verification steps, observable stop condition. Reference the active change folder if one exists.
4. **Create worktree** (if `--worktree` or feature work) — `gnhf --worktree "<prompt>"`
5. **Launch** — Use Hands-Off mode for unattended, Companion for supervised
6. **Morning review** — On return, inspect branch, commits, notes.md, run verification, report summary
</steps>
