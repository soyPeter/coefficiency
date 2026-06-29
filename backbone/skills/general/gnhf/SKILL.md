<!-- FRAMEWORK: GENERAL -->
---
framework: general
name: gnhf
description: Use when the user says they are going to sleep or leaving and wants agent work to continue, asks to run an overnight autonomous coding session, asks to set up gnhf, or wants a morning review of gnhf results. Also use when the user wants parallel agent work using worktrees.
---

# GNHF — Good Night, Have Fun

gnhf is an autonomous agent orchestrator (`npm install -g gnhf`) that runs agents in a loop until a stop condition is met. Each iteration makes one committed change. You wake up to a branch of clean work.

## Prerequisites

```bash
npm install -g gnhf
gnhf --help                          # verify installation
git status --short                   # must be clean
git branch --show-current            # note your starting branch
```

## Two Modes

### Hands-Off

User is going to sleep / leaving. Prepare a precise prompt, launch, done.

```
gnhf \
  --agent claude \
  --max-iterations 20 \
  --max-tokens 5000000 \
  --stop-when "<observable completion condition>" \
  --prevent-sleep on \
  "<worker prompt>"
```

The prompt should include: objective, constraints, non-goals, verification steps, stop condition. Be specific — gnhf runs unattended.

### Companion

User is around but wants agents doing background work. Poll progress, steer with tighter prompts, review diffs between iterations.

```
gnhf --worktree --agent opencode \
  --max-iterations 10 \
  --stop-when "tests pass" \
  "implement the NATS event publisher"
```

`--worktree` mode creates an isolated worktree so you keep working in your main checkout.

## Morning Review

When the user returns:

```bash
git branch --all | grep gnhf
git log --oneline --decorate --max-count=20
git diff main...HEAD --stat
```

Read `.gnhf/runs/*/notes.md` for the agent's log. Run independent verification (tests, lint, build). Report: branch, iterations, tokens consumed, what changed, verification results, and recommendation (merge / needs fixes / discard).

## Backbone Integration

- gnhf runs in `--worktree` mode by default when working on backbone projects — keeps the main checkout clean
- Use the active change folder's `tasks.md` to derive the gnhf prompt
- For parallel work: `gnhf --worktree "task A" &` + `gnhf --worktree "task B" &`
- Exit summary includes iteration count, token usage, and diff stats
