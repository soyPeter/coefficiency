---
name: backbone:compact
description: Scan for stale decision and memory entries — no Status field or no [Archived] marker. Supports --dry-run.
allowed-tools:
  - Read
  - Edit
  - Bash
  - Grep
  - Question
---

<objective>
Scan [[`backbone/5-DECISIONS.md`](backbone/5-DECISIONS.md)](backbone/5-DECISIONS.md) and [[`backbone/6-MEMORY.md`](backbone/6-MEMORY.md)](backbone/6-MEMORY.md) for entries without Status or [Archived] markers, present candidates, and let the user mark them as superseded/archived.

**Flags:**
- `--dry-run` — Report candidates without modifying files
</objective>

<process>
## Step 0: Parse Flags

`--dry-run` — set DRY_RUN=true

## Step 1: Scan Decisions

Read `backbone/5-DECISIONS.md`. Find all `## Decision N:` entries. For each:
- Check if the entry has a `**Status:**` line
- If missing Status → candidate for review

Report format:
```
Decision entries without Status:
  - D1: [Title]
  - D3: [Title]
```

## Step 2: Scan Memory

Read `backbone/6-MEMORY.md`. Find all list items (`- ...`). For each:
- Check if item starts with `**[Archived:` 
- If not archived → candidate for review

Report format:
```
Memory entries not archived:
  - [date] entry text
  - [date] entry text
```

## Step 3: Present Candidates

If `--dry-run`: print the full report and exit.

Otherwise, for each candidate, ask the user:
```
Candidate: D1 — [Title]
Mark as superseded? [y/N]
```

If yes:
- For decisions: add `**Status:** Superseded` after the `**Why:**` line
- For memory: prefix with `**[Archived: YYYY-MM-DD]**`
- Update the index entry: `- D1: [Title] — Superseded`

## Step 4: Report

Print summary of changes made (or would be made with --dry-run).
</process>