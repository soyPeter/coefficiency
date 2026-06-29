---
name: backbone:handoff
description: Compact the current conversation into a handoff document for another agent to continue seamlessly
---

Compact the current session into a handoff document saved to `.backbone/handoff/<timestamp>.md`.

## What the Handoff Contains

1. **Current goal** — What feature or task is being worked on
2. **CHNG-XXX context** — Which change folder, what's WIP, what's complete
3. **Key decisions** — From decisions.md or this session with rationale
4. **Remaining work** — Unfinished tasks, next steps, blockers
5. **Architecture context** — Files touched, design decisions, patterns used

## Process

1. Gather context:
   - Read [`backbone/3-TASKS.md`](backbone/3-TASKS.md) for current WIP tasks
   - Read `backbone/artifacts/changes/CHNG-XXX/` for proposal, design, decisions
   - Read `.backbone/ledger/progress.md` if exists (subagent progress)
   - Check `git status` and `git log --oneline -5` for recent work

2. Write handoff to `.backbone/handoff/$(date +%Y-%m-%d-%H%M%S).md`

3. Tell the user: "Handoff saved to [path]. The next agent can read it with: `cat [path]`"
