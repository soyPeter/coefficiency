<!-- FRAMEWORK: GENERAL -->
---
framework: general
name: code-quality
description: Code quality standards covering clean code, SOLID principles, design patterns, and code review practices. Use before writing any code to ensure adherence to project quality standards.
---

# Code Quality

## Overview

Code quality spans four dimensions. Load the relevant sub-skill for detailed guidance.

## Skills in This Category

| Skill | When to Load | What It Covers |
|-------|-------------|----------------|
| `clean-code` | Always | Naming, functions, comments, formatting, DRY/KISS/YAGNI |
| `solid-principles` | Architecture design | SRP, OCP, LSP, ISP, DIP with examples |
| `design-patterns` | When implementing common patterns | Factory, Builder, Strategy, Observer, Decorator, etc. |
| `code-review` | Before reviewing PRs | Review checklist, common issues, security patterns |

## Loading

```bash
# Load a sub-skill:
view backbone/skills/cross-cutting/code-quality/clean-code/SKILL.md
view backbone/skills/cross-cutting/code-quality/solid-principles/SKILL.md
```

## Core Rules (Apply Always)

- **Names reveal intent** — `calculateTotal()` not `calc()`, `userCount` not `x`
- **One thing per function** — if it does more than one thing, split it
- **No commented-out code** — delete it, git has the history
- **No magic numbers** — use named constants
- **Smallest possible scope** — local over global, private over public
- **Fail fast** — validate inputs at boundaries, not deep in logic
- **Symmetry** — if there's `save()`, there should be `load()`; if `open()`, then `close()`
