---
name: backbone:compact-mode
description: Toggle output compression to reduce token consumption — lite (~30%), full (~65%), ultra (~80%), or off
argument-hint: "<lite|full|ultra|off>"
required-skills:
  - general/caveman-compact
---

Toggle output compression mode: $ARGUMENTS

Valid levels: `lite`, `full`, `ultra`, `off`.

If no argument provided, report current level and offer to change.

## Levels

| Level | Style | Token Savings |
|-------|-------|---------------|
| `lite` | Drop filler words, keep full sentences | ~30% |
| `full` | Fragments, no articles/prepositions | ~65% |
| `ultra` | Telegraphic, single words where possible | ~80% |
| `off` | Normal mode | 0% |

Load `view backbone/skills/general/caveman-compact/SKILL.md` to activate the skill, then apply the requested compression level to all output.

**Never compress:** error messages, stack traces, code changes, commands/output, security warnings, user-facing text.
