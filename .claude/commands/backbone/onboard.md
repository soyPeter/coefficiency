---
name: backbone:onboard
description: Initialize an existing project with Agentic Backbone (skeleton docs, hooks, registration)
argument-hint: "[--project-dir /path] [--dry-run]"
allowed-tools:
  - Read
  - Bash
  - Glob
  - Grep
required-skills: []
---

<objective>
Onboard an existing project to use Agentic Backbone.

Runs the full onboarding pipeline:
1. Create `backbone/` skeleton (4-KNOWLEDGE.md, 5-DECISIONS.md, 6-MEMORY.md, 3-TASKS.md, etc.)
2. Generate architecture metadata (framework detection, C4, patterns)
3. Wire Claude Code hooks, OpenCode plugins, and git hooks to `~/.backbone/`
4. Register project for future `./scripts/update-backbone.sh --all-known`
5. Print manual steps for filling in project-specific content

Run from the project root, or use `--project-dir /path`.
</objective>

<process>

## Pre-Flight

1. Verify user is in the project root (has `src/`, `build.gradle.kts`, `pom.xml`, `package.json`, etc.)
2. If `backbone/` already exists, confirm the user wants to re-onboard (will overwrite some files)

## Execution

Run the onboarding script:

```bash
bash ~/.backbone/scripts/backbone-onboard.sh --project-dir "$(git rev-parse --show-toplevel)"
```

If `--dry-run` was requested, add `--dry-run` flag.

## Post-Flight

1. Show the user which files were created:
   - `backbone/4-KNOWLEDGE.md`
   - `backbone/5-DECISIONS.md`
   - `backbone/6-MEMORY.md`
   - `backbone/3-TASKS.md`
   - `backbone/.MODE`
   - `backbone/9-AGENT-SKILLS.md`

2. Remind the user to edit `backbone/4-KNOWLEDGE.md` with:
   - Core framework + version
   - Build tool
   - NEVER DO list
   - Test/lint commands

3. Remind the user to fill in `backbone/5-DECISIONS.md` with past architectural decisions.

4. Suggest marking an initial task as [WIP] in `backbone/3-TASKS.md`.
</process>
