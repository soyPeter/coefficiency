---
description: Scan for stale decision and memory entries — no Status field or no [Archived] marker. Supports --dry-run.
---

> **skill loading:** Read this command's `required-skills` frontmatter above. For each entry, check if `backbone/skills/<path>/SKILL.md` exists — if yes, `view` it; otherwise use `skill tool "<basename>"` as fallback.

Scan [[`backbone/5-DECISIONS.md`](backbone/5-DECISIONS.md)](backbone/5-DECISIONS.md) and [[`backbone/6-MEMORY.md`](backbone/6-MEMORY.md)](backbone/6-MEMORY.md) for stale entries and suggest compaction: $ARGUMENTS

Parse `--dry-run` from arguments if present.

## Process

1. **Scan decisions** — Read `backbone/5-DECISIONS.md`, find all `## Decision N:` entries. For each, check if `**Status:**` line exists. Missing Status → candidate.
2. **Scan memory** — Read `backbone/6-MEMORY.md`, find all list items. If not prefixed with `**[Archived:` → candidate.
3. **Present candidates** — If `--dry-run`, print report and exit. Otherwise, for each candidate ask: `Mark as superseded/archived? [y/N]`
4. **Apply changes** — For decisions: add `**Status:** Superseded` after `**Why:**`. For memory: prefix with `**[Archived: YYYY-MM-DD]**`. Update index entries.
5. **Report** — Print summary of changes made.
