---
name: backbone:status
description: Show project status. Consolidates progress and stats.
argument-hint: "[--stats|--progress|--wide]"
allowed-tools:
  - Read
  - Bash
  - Glob
  - Grep
required-skills: []
---

<objective>
Show project status — task progress and statistics.

**Consolidates:** `progress` and `stats`

**When to use:**
- Starting a new session ("What should I do next?")
- Project health check
- Reporting to stakeholders

**Flags:**
- `--stats` — Show file counts, commit counts, coverage, issues
- `--progress` — Show task completion from 3-TASKS.md
- Default: both
- `--wide` — Show expanded details
</objective>

<process>
## Step 1: Parse Arguments

- `--stats` — show statistics only
- `--progress` — show progress only
- `--wide` — expanded output
- Default: show both

## Step 2: Progress (if --progress or default)

Read [`backbone/3-TASKS.md`](backbone/3-TASKS.md):
- Extract milestone table (M1-M7 status)
- Count completed vs pending tasks
- Identify WIP tasks (marked [WIP])

Read `backbone/artifacts/changes/STATE.md` if exists:
- Extract current blockers
- Check session alerts

Show:
```
📊 Project Progress
═══════════════════════════════════════════

Milestones:
  M1 Bootstrap      ✅ 100%
  M2 Dev Portal     ✅ 100%
  M3 Release Mgmt   ✅ 100%
  M4 Observability   ⬜ 0%
  ...

Active Tasks:
  [WIP] Phase B2: Slash commands (6 new commands)

Blockers:
  None
```

## Step 3: Statistics (if --stats or default)

**Project Structure:**
```bash
find . -type f -name '*.sh' | wc -l
find . -type f -name '*.py' | wc -l
find . -type f -name '*.ts' | wc -l
find . -type f -name '*.md' | wc -l
find templates/ -type f | wc -l
find backbone/skills/ -name 'SKILL.md' | wc -l
```

**Git Metrics:**
```bash
git rev-list --count HEAD
git log --since='30 days ago' --oneline | wc -l
git branch -a | wc -l
git describe --tags --abbrev=0 2>/dev/null || echo 'none'
```

**Template Coverage:**
- Frameworks supported: list from `templates/services/`
- Service templates: count directories

**Skill Inventory:**
- General skills, cross-cutting, framework-specific

**Test Coverage:**
- Bash tests, Python tests, Node tests

Show:
```
📈 Backbone Generator Statistics
═══════════════════════════════════════════

Project Structure:
  Bash scripts:     25
  TypeScript files: 48
  Documentation:    35
  Templates:        127

Git Activity:
  Total commits:    180
  This month:       42
  Latest tag:       2026.04.25

Templates:
  Service frameworks: 4 (quarkus, springboot, laravel, kotlin)

Skills & Agents:
  Skills:    28
  Agents:    8
  Commands:  11

Tests:
  Bash:   25 passing
  Python: 45 passing
  Node:   31 passing
```

## Step 4: Git Status

```bash
git status --short
git log --oneline -5
```

## Step 5: Recommend Next Action

- If WIP task exists: "Continue with [WIP task]"
- If uncommitted changes: "Commit changes first"
- If all tasks complete: "All tasks done! Consider /backbone:ship"
</process>

<success_criteria>
- [ ] Progress shows milestone completion percentages
- [ ] Stats show file counts, git metrics, template coverage
- [ ] WIP tasks identified
- [ ] Git status shown
- [ ] Next action recommended
</success_criteria>