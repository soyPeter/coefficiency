---
description: Ship a release — version bump, tag, changelog, push
required-skills:
  - general/git-commit
---

> **skill loading:** Read this command's `required-skills` frontmatter above. For each entry, check if `backbone/skills/<path>/SKILL.md` exists — if yes, `view` it; otherwise use `skill tool "<basename>"` as fallback.

Ship a release for the current feature: $ARGUMENTS

Process:
1. Verify all tasks are [x] in [`backbone/3-TASKS.md`](backbone/3-TASKS.md)
2. Bump version in `backbone/VERSION`
3. Create a git tag
4. Generate changelog from commit history
5. Push to remote
