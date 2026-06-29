---
description: Map codebase architecture — inventory, reverse-engineer, or deep architecture audit
agent: general
required-skills:
  - cross-cutting/architecture
---

> **skill loading:** Read required-skills frontmatter. For each entry, check `backbone/skills/<path>/SKILL.md` first, then fallback to skill tool.

Map codebase architecture: $ARGUMENTS

## Modes
- **Default**: Template inventory, script inventory, skills inventory (quick overview)
- `--reverse`: Reverse-engineer existing project into backbone metadata
- `--full`: Run both inventory and reverse-engineering
- `--deep-arch`: Full architecture depth audit via subagents (DDD/SOLID/layer boundaries)

## Process

### Default (Inventory)
1. Run `bash ~/.backbone/scripts/reverse-engineer.sh` (for file structure)
2. Report modules, layers, dependencies, architectural patterns

### --reverse
1. Run `bash ~/.backbone/scripts/reverse-engineer.sh [--project-dir <path>] [--apply]`
2. Produces CHNG folder, C4 diagrams, architecture map, metadata drafts

### --deep-arch

1. Load `cross-cutting/architecture` skill
2. Run `bash ~/.backbone/scripts/reverse-engineer.sh --project-dir <path> --apply`
3. `CHNG_DIR=$(ls -d backbone/artifacts/changes/CHNG-* 2>/dev/null | sort -r | head -1)`
4. Read and follow the shared deep-arch workflow at `@backbone/reference/workflows/deep-arch-map.md` — execute Steps 4-13 (parallel explorers, secret scanning, report template, metadata updates, QMS NCRs, cleanup)
5. If no CHNG folder exists: `bash backbone-change-init.sh "arch-depth-audit"`
