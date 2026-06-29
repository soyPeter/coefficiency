---
description: Record a decision in 5-DECISIONS.md — supports --supersedes D-NNN to mark old decisions as superseded
required-skills:
  - general/documentation-and-adrs
---

> **skill loading:** Read this command's `required-skills` frontmatter above. For each entry, check if `backbone/skills/<path>/SKILL.md` exists — if yes, `view` it; otherwise use `skill tool "<basename>"` as fallback.

Record an important decision with full context, alternatives, and rationale: $ARGUMENTS

Parse `--supersedes D5,D8` from arguments if present.

Process:
1. Extract decision title, context, alternatives, rationale
2. Find next decision number in [[[`backbone/5-DECISIONS.md`](backbone/5-DECISIONS.md)](backbone/5-DECISIONS.md)](backbone/5-DECISIONS.md) (increment highest D-NNN)
3. If `--supersedes D5,D8`:
   - For each decision number, find entry in `backbone/5-DECISIONS.md`
   - Add `**Status:** Superseded` and `**Superseded by:** D-NEW` to each old entry
   - Update index line: `- D5: [Title] — Superseded by D-NEW`
4. Append new entry to `backbone/5-DECISIONS.md`:
   - Date
   - Context — what prompted the decision
   - Decision — what was chosen
   - Alternatives — what was considered and rejected
   - Why — rationale for the choice
   - Status: Accepted
5. Add index entry: `- D-NEW: [Title] — Accepted`
