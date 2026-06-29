---
description: Start an autonomous overnight (gnhf) run — agents work while you sleep. Requires npm install -g gnhf.
agent: plan
required-skills:
  - general/coding-standards
  - general/gnhf
---

> **skill loading:** Read this command's `required-skills` frontmatter above. For each entry, check if `backbone/skills/<path>/SKILL.md` exists — if yes, `view` it; otherwise use `skill tool "<basename>"` as fallback.

Start an autonomous gnhf loop: $ARGUMENTS

Read `backbone/.MODE`:
- `full`/`standard`: Hands-Off mode with worktree isolation, morning review checklist
- `light`: Quick companion mode, no worktree

gnhf runs agents in a loop until a stop condition is met. Each iteration commits one change.
Use when the user is going to sleep / leaving and wants work to continue.

**Flags:**
- `--agent <name>` — Agent (claude, opencode, codex; default from gnhf config)
- `--max-iterations <n>` — Stop after N iterations (default: 20)
- `--max-tokens <n>` — Stop after N total tokens (default: 5000000)
- `--companion` — Companion mode: poll and steer between iterations
- `--worktree` — Run in isolated git worktree

**Steps:**
1. Load gnhf skill
2. Verify `gnhf --help`, clean git, current branch
3. Prompt = objective + constraints + verification + stop condition
4. Launch: `gnhf [--worktree] [--agent X] --max-iterations N "<prompt>"`
5. On return: inspect branch, commits, notes.md, verify, report summary
