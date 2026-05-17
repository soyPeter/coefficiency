# Out-of-Scope Knowledge Base

The `.out-of-scope/` directory stores persistent records of rejected feature requests.

## Purposes

1. **Institutional memory** — why a feature was rejected
2. **Deduplication** — surface previous decisions when similar requests come in

## Directory Structure

```
.out-of-scope/
├── dark-mode.md
├── plugin-system.md
└── graphql-api.md
```

One file per **concept**, not per issue. Multiple issues requesting the same thing are grouped under one file.

## File Format

```markdown
# Dark Mode

This project does not support dark mode or user-facing theming.

## Why this is out of scope

The rendering pipeline assumes a single color palette. Supporting multiple 
themes would require a significant architectural change that doesn't align 
with the project's focus.

## Prior requests

- #42 — "Add dark mode support"
- #87 — "Night theme for accessibility"
```

### Naming

Use kebab-case: `dark-mode.md`, `plugin-system.md`. Recognizable at a glance.

### Writing the Reason

Reference:
- Project scope or philosophy
- Technical constraints
- Strategic decisions

Avoid temporary circumstances ("we're too busy") — those are deferrals, not rejections.

## When to Check

During triage, read all `.out-of-scope/*.md` files. When evaluating a new issue:

- Check if the request matches an existing concept
- If yes, surface to maintainer: "This is similar to `.out-of-scope/dark-mode.md` — rejected because [reason]. Do you still feel the same way?"

## When to Write

Only when an **enhancement** is rejected as `wontfix`:

1. Check if matching file exists
2. If yes: append new issue to "Prior requests"
3. If no: create new file with concept name, decision, reason, first prior request
4. Post comment on issue explaining decision
5. Close issue with `wontfix` label

## Updating or Removing

If the maintainer changes their mind:
- Delete the `.out-of-scope/` file
- New issue proceeds through normal triage
