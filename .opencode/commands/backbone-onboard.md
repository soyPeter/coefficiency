---
description: Initialize an existing project with Agentic Backbone
---

Run the onboarding pipeline for this project:

1. **Create backbone/ skeleton**
   ```bash
   bash ~/.backbone/scripts/init-backbone.sh --project-dir .
   ```

2. **Generate architecture metadata**
   ```bash
   bash ~/.backbone/scripts/reverse-engineer.sh --project-dir . --apply
   ```

3. **Wire hooks and plugins to centralized ~/.backbone/**
   ```bash
   bash ~/.backbone/scripts/install-backbone-hooks.sh --project-dir .
   ```

4. **Register for future `--all-known` updates**
   ```bash
   bash ~/.backbone/scripts/update-backbone.sh --register .
   ```

5. **Fill in project-specific content:**
   - `backbone/4-KNOWLEDGE.md` — Tech stack, build commands, NEVER DO list
   - `backbone/5-DECISIONS.md` — Past architectural decisions
   - `backbone/6-MEMORY.md` — Lessons learned, known issues
   - `backbone/3-TASKS.md` — First task as [WIP]
   - `backbone/.MODE` — light, standard, or full

After onboarding, run `backbone:status` or read `backbone/3-TASKS.md` to start working.
