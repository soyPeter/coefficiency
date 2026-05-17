---
name: backbone:map-codebase
description: Analyze templates, scripts, and skills to generate an inventory and detect issues.
allowed-tools:
  - Read
  - Bash
  - Glob
  - Grep
  - Task
---

<objective>
Generate a comprehensive inventory of the Agentic Backbone codebase.

**Analyzes:**
- `templates/` — All project templates with framework coverage
- `scripts/` — Automation scripts with test coverage
- `backbone/skills/` — Skills inventory by category
- `dev-portal/` — API routes and UI components
- `.claude/` — Hooks, agents, commands

**Detects:**
- Orphaned skills (not referenced in templates)
- Missing tests for scripts
- Placeholder leaks in templates
- Duplicate files between backbone/ and templates/backbone/
- Outdated conventions

**Output:** Markdown inventory report with findings and recommendations.
</objective>

<process>
1. **Template Inventory**
   ```bash
   find templates -type d -maxdepth 2 | sort
   ```
   - List all framework templates
   - Check each has: Dockerfile, docker-compose.yml, README.md
   - Detect placeholder leaks: `grep -r "__PLACEHOLDER__" templates/ || true`

2. **Script Inventory**
   ```bash
   find scripts -name "*.sh" -type f | sort
   ```
   - List all bash scripts
   - Check which have tests in tests/bash/
   - Report untested scripts

3. **Skills Inventory**
   ```bash
   find backbone/skills -name "SKILL.md" -type f | sort
   ```
   - Group by framework: general/, java/, quarkus/, springboot/, cross-cutting/
   - Check frontmatter completeness
   - Flag skills >300 lines

4. **Dev Portal Inventory**
   - List API routes
   - List UI pages
   - Check for orphaned components

5. **Hook Inventory**
   ```bash
   ls .claude/hooks/ scripts/hooks/
   ```
   - Check all hooks are executable
   - Verify hook parity

6. **Generate Report**
   - Write to `backbone/planning/CODEBASE-INVENTORY.md`
   - Include: counts, coverage gaps, recommendations
   - Update STATE.md session log
</process>

<success_criteria>
- [ ] All templates catalogued with framework info
- [ ] All scripts listed with test coverage status
- [ ] All skills grouped by category
- [ ] Placeholder leaks identified
- [ ] Untested scripts flagged
- [ ] Report written to CODEBASE-INVENTORY.md
</success_criteria>
