---
name: backbone:map
description: Generate architecture map. Inventory, reverse-engineer, or deep architecture audit.
argument-hint: "[--reverse|--full|--deep-arch]"
allowed-tools:
  - Read
  - Bash
  - Glob
  - Grep
  - Task
required-skills:
  - cross-cutting/architecture
---

<objective>
Analyze templates, scripts, and skills to generate an inventory, or
reverse-engineer an existing project into backbone metadata, or
perform a deep architecture audit via subagents.

**Consolidates:** `map-codebase`, `reverse-engineer`, and deep architecture analysis

**When to use:**
- Generating project inventory (no flag)
- Reverse-engineering existing project (--reverse)
- Detecting orphaned skills, missing tests, placeholder leaks
- Deep architecture depth audit (--deep-arch)

**Flags:**
- `--reverse` — Analyze existing project, generate backbone metadata (C4 diagrams, architecture map, 4-KNOWLEDGE.md, 5-DECISIONS.md, 6-MEMORY.md)
- `--full` — Run both inventory and reverse-engineering
- `--deep-arch` — Full architecture depth audit via subagent: module thickness, layer boundaries, circular deps, DDD compliance, SOLID violations
</objective>

<process>
## Step 0: Parse Arguments

- `--reverse` — run reverse-engineering only
- `--full` — run both inventory and reverse-engineering
- `--deep-arch` — run deep architecture audit
- Default: run inventory only

## Step 1: Template Inventory (if not --reverse)

```bash
find templates -type d -maxdepth 2 | sort
```
- List all framework templates
- Check each has: Dockerfile, docker-compose.yml, README.md
- Detect placeholder leaks: `grep -r "__PLACEHOLDER__" templates/ || true`

## Step 2: Script Inventory

```bash
find scripts -name "*.sh" -type f | sort
```
- List all bash scripts
- Check which have tests in tests/bash/

## Step 3: Skills Inventory

```bash
find backbone/skills -name "SKILL.md" -type f | sort
```
- Group by framework: general/, java/, quarkus/, springboot/, cross-cutting/
- Check frontmatter completeness
- Flag skills >300 lines

## Step 4: Dev Portal Inventory

- List API routes
- List UI pages

## Step 5: Hook Inventory

```bash
ls .claude/hooks/ scripts/hooks/
```
- Check all hooks are executable

## Step 6: Generate Inventory Report

Write to `backbone/artifacts/changes/CODEBASE-INVENTORY.md`.

## Step 7: Generate Architecture Map (if --reverse or --full)

First run the reverse-engineer script for CHNG scaffolding and C4 diagrams:

```bash
bash ~/.backbone/scripts/reverse-engineer.sh [--project-dir <path>] [--apply]
```

Then **replace the tree-dump architecture-map.md** with a proper structural map.
Read the actual codebase structure and generate these sections:

**a) System context (C4 Level 1)** — what system is this, what external systems does it talk to

**b) Subdomain/bounded context map** — list modules/subdomains with:
- Their internal layers (domain/ app/ infra/ ports/) with file counts
- Dependency arrows between modules (which depends on which)
- Identify leaf nodes, hub modules, isolated modules

**c) Layer architecture table** per module — domain% vs app% vs infra% vs ports%
- Flag modules with 0% domain (anemic)
- Flag modules with >50% app/ (procedural)

**d) Port/adapter mapping** — table of port interfaces, their implementation locations and naming
- Flag naming inconsistencies (`*Adapter` vs `*Impl` vs `*Repository`)
- Flag implementations in wrong layers

**e) Deployment architecture** — how it runs (single JVM, containers, DBs)

**f) Dependency flow summary** — what flows via events, what via ports

**g) Architectural patterns observed** — hexagonal, event-driven, DDD aggregates, strategy pattern, etc.

Write the generated map to `architecture-map.md` in the CHNG folder.

## Step 8: Deep Architecture Audit (if --deep-arch)

**Executable process:**

1. Load `cross-cutting/architecture` skill

2. Run structural reverse-engineering with --apply:
   ```bash
   bash ~/.backbone/scripts/reverse-engineer.sh --project-dir <path> --apply
   ```

3. Find the most recent CHNG folder:
   ```bash
   CHNG_DIR=$(ls -d backbone/artifacts/changes/CHNG-* | sort -r | head -1)
   ```

4. Read and follow the shared deep-arch workflow:
   ```bash
   cat backbone/reference/workflows/deep-arch-map.md
   ```
   Execute Steps 4-13 from that workflow. It includes: parallel explorer prompts, secret scanning, the report template with prescriptive sections, metadata updates, QMS NCR registration, and cleanup.

5. If no CHNG folder exists, create one:
   ```bash
   bash backbone-change-init.sh "arch-depth-audit"
   ```

## Step 9: Report

```
(Default):
✅ Architecture map complete
  Inventory: N frameworks, N scripts, N skills, N hooks

(--reverse):
  Detected: <framework>, <language>, <build tool>
  CHNG folder: backbone/artifacts/changes/CHNG-XXX-...

(--deep-arch):
  Architecture audit:
  - Module thickness: domain=N% app=N% infra=N%
  - Layer violations: N
  - Circular deps: N
  - DDD issues: N
  - SOLID violations: N
  Report: backbone/artifacts/reports/arch-map-YYYY-MM-DD.md
```
</process>

<success_criteria>
- [ ] All templates catalogued with framework info
- [ ] All scripts listed with test coverage status
- [ ] All skills grouped by category
- [ ] Placeholder leaks identified
- [ ] (if --reverse) Architecture map generated with: system context, subdomain map, layer table, port/adapter table, dependency flow, deployment view, patterns observed
- [ ] (if --deep-arch) Architecture depth report written with module thickness, violations, recommendations
- [ ] Report written to CODEBASE-INVENTORY.md (inventory), CHNG folder (reverse), or CHNG folder (deep-arch)
</success_criteria>
