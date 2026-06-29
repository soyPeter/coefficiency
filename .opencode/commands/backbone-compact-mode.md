---
description: Toggle output compression — lite (~30%), full (~65%), ultra (~80%), or off
---

> **skill loading:** Read this command's `required-skills` above. Check `backbone/skills/general/caveman-compact/SKILL.md` — if yes, `view` it; otherwise use `skill tool "caveman-compact"`.

Toggle output compression mode: $ARGUMENTS

Valid levels: `lite`, `full`, `ultra`, `off`. If no argument, report current level.

| Level | Style | Savings |
|-------|-------|---------|
| `lite` | Drop filler | ~30% |
| `full` | Fragments | ~65% |
| `ultra` | Telegraphic | ~80% |
| `off` | Normal | 0% |

Load `view backbone/skills/general/caveman-compact/SKILL.md`, then apply compression level.

**Never compress:** errors, stack traces, code, commands, security warnings, user-facing copy.
