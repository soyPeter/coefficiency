---
name: backbone:quick
description: Execute ad-hoc backbone task with atomic commit. Skips full PRD planning for small changes.
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
---

<objective>
Execute a small, well-defined task on the Agentic Backbone generator with minimal overhead.

**When to use:**
- Fix a typo or broken link
- Update a single template file
- Add a small utility function
- Fix a failing test

**When NOT to use:**
- New feature requiring PRD
- Architectural changes
- Multi-file refactoring
- Changes affecting generated projects

**Workflow:**
1. Parse task description from $ARGUMENTS
2. Load required skills
3. Use worktrunk for feature work (mandatory)
4. Execute changes
5. Run relevant tests
6. Update 3-TASKS.md if non-trivial
7. Commit with conventional message
</objective>

<process>
1. **Parse Task**
   - Extract task description from $ARGUMENTS
   - Classify: fix / docs / refactor / feat

2. **Load Skills**
   - If working on scripts: `view backbone/skills/general/coding-standards/SKILL.md` (Bash patterns in `backbone/4-KNOWLEDGE.md`)
   - If working on Python: `view backbone/skills/general/coding-standards/SKILL.md` (Python patterns in `backbone/4-KNOWLEDGE.md`)
   - If working on Node.js: `view backbone/skills/general/coding-standards/SKILL.md` (Node patterns in `backbone/4-KNOWLEDGE.md`)
   - Always: `view backbone/skills/general/git-commit/SKILL.md`

3. **Worktrunk Check**
   - If task is a feature (not fix/docs): use worktrunk
   - Run: `bash scripts/worktrunk.sh create quick-<timestamp>`
   - If on protected branch with dirty tree: create worktree first

4. **Execute**
   - Make minimal changes
   - Follow existing code style
   - Add tests if applicable

5. **Verify**
   - Run: `npm test` (if tests exist for modified code)
   - Run: `bash scripts/verify-template-sync.sh` (if backbone/ changed)
   - Run: `bash scripts/secret-scan.sh --staged` (if new files)

6. **Commit**
   - Use conventional commits: `<type>(<scope>): <subject>`
   - Types: fix, docs, refactor, feat, test
   - Update backbone/VERSION if backbone/ files changed

7. **Update Tasks**
   - If task took >15 min or touched >3 files:
     - Add entry to backbone/3-TASKS.md under Quick Tasks
     - Update backbone/planning/STATE.md (auto-syncs)
</process>

<critical_rules>
- NEVER commit without tests passing
- NEVER skip worktrunk for feature work on protected branches
- NEVER leave WIP tasks in 3-TASKS.md without completing them
- ALWAYS update VERSION when backbone/ files change
</critical_rules>
