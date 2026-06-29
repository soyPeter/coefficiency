---
description: Run automated simplification on the current diff using 4 parallel agents (Reuse, Simplification, Efficiency, Altitude)
required-skills:
  - general/code-simplification
---

> **skill loading:** Read this command's `required-skills` frontmatter above. For each entry, check if `backbone/skills/<path>/SKILL.md` exists — if yes, `view` it; otherwise use `skill tool "<basename>"` as fallback.

Run the **Automated Phase** of the code-simplification skill on the current working tree diff.

1. Gather the diff via `git diff` (unstaged) and `git diff --cached` (staged)
2. Follow the instructions in the code-simplification skill's "Phase 2 — Automated (Diff Review)" section
3. Launch 4 concurrent review agents (Reuse, Simplification, Efficiency, Altitude)
4. Deduplicate and apply the fixes
5. Summarize what was fixed and what was skipped
