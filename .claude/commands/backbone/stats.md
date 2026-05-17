---
name: backbone:stats
description: Display comprehensive project statistics — phases, skills, templates, git metrics, and generator health.
allowed-tools:
  - Read
  - Bash
  - Glob
  - Grep
---

<objective>
Display comprehensive project statistics for the Agentic Backbone generator.

**When to use:**
- Project health check
- Before/after major releases
- Reporting to stakeholders
- Identifying gaps in coverage

**Metrics:**
- Project structure (files, directories)
- Git activity (commits, contributors, branches)
- Template coverage (frameworks, services)
- Skill inventory (count by category)
- Test coverage (pass/fail counts)
- Generator usage (if telemetry available)
</objective>

<process>
1. **Project Structure**
   - Count files by type:
     - `find . -type f -name '*.sh' | wc -l` (bash scripts)
     - `find . -type f -name '*.py' | wc -l` (python files)
     - `find . -type f -name '*.ts' | wc -l` (typescript files)
     - `find . -type f -name '*.md' | wc -l` (documentation)
   - Count templates: `find templates/ -type f | wc -l`
   - Count skills: `find backbone/skills/ -name 'SKILL.md' | wc -l`

2. **Git Metrics**
   - Total commits: `git rev-list --count HEAD`
   - Commits this month: `git log --since='30 days ago' --oneline | wc -l`
   - Branches: `git branch -a | wc -l`
   - Contributors: `git log --format='%an' | sort -u | wc -l`
   - Last tag: `git describe --tags --abbrev=0 2>/dev/null || echo 'none'`

3. **Template Coverage**
   - Frameworks supported: list from `templates/services/`
   - Service templates: count directories in `templates/services/`
   - Runtime templates: check `templates/runtime/` exists
   - Backbone templates: check `templates/backbone/` completeness

4. **Skill Inventory**
   - General skills: `find backbone/skills/general/ -name 'SKILL.md' | wc -l`
   - Cross-cutting: `find backbone/skills/cross-cutting/ -name 'SKILL.md' | wc -l`
   - Framework-specific: list by framework directory
   - Agent count: `ls .claude/agents/*.md 2>/dev/null | wc -l`
   - Command count: `ls .claude/commands/backbone/*.md 2>/dev/null | wc -l`

5. **Test Coverage**
   - Bash tests: `find tests/bash/ -name '*.bats' 2>/dev/null | wc -l`
   - Python tests: `find tests/python/ -name 'test_*.py' 2>/dev/null | wc -l`
   - Node tests: `find tests/node/ -name '*.test.ts' 2>/dev/null | wc -l`
   - Run test suites and capture pass/fail counts

6. **Security Health**
   - Hooks installed: `ls .claude/hooks/*.sh 2>/dev/null | wc -l`
   - Secret scan status: `bash scripts/secret-scan.sh --all 2>/dev/null && echo 'clean' || echo 'findings'`
   - Injection guard: check `.claude/hooks/pre-tool-use-injection-guard.sh` exists

7. **Generate Report**
   ```
   📈 Backbone Generator Statistics
   ═══════════════════════════════════════════
   
   Project Structure:
     Bash scripts:     25
     Python files:     12
     TypeScript files: 48
     Documentation:    35
     Total templates:  127
   
   Git Activity:
     Total commits:    180
     This month:       42
     Contributors:     3
     Latest tag:       2026.04.25
   
   Templates:
     Service frameworks: 4 (quarkus, springboot, laravel, kotlin)
     Runtime stack:      ✅ (observability + helm)
     Backbone scaffold:  ✅ complete
   
   Skills & Agents:
     Skills:    28
     Agents:    8
     Commands:  11
   
   Tests:
     Bash:   25 passing
     Python: 45 passing
     Node:   31 passing
   
   Security:
     Hooks:        12 installed
     Secret scan:  clean
     Injection:    22 patterns active
   ```

8. **Identify Gaps**
   - Highlight missing templates (M5: Node.js, Python, Go)
   - Highlight incomplete milestones
   - Suggest next priority based on data
</process>

<success_criteria>
- [ ] All metrics calculated correctly
- [ ] Report formatted clearly with sections
- [ ] Git metrics accurate
- [ ] Template coverage listed
- [ ] Test results included
- [ ] Security health shown
- [ ] Gaps identified with recommendations
</success_criteria>
