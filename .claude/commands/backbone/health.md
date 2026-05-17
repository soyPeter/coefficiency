---
name: backbone:health
description: Validate backbone integrity — check template sync, run tests, verify hooks, and report status.
allowed-tools:
  - Read
  - Bash
  - Glob
  - Grep
---

<objective>
Run a comprehensive health check on the Agentic Backbone generator.

**Checks performed:**
1. Template sync (backbone/ vs templates/backbone/)
2. Test suite execution (bash, python, node)
3. Hook validation
4. SKILL.md frontmatter lint
5. Secret scan on staged files
6. STATE.md sync status

**Output:** Structured health report with PASS/FAIL for each check.
</objective>

<process>
1. **Template Sync Check**
   ```bash
   bash scripts/verify-template-sync.sh
   ```
   - If drift detected: report and suggest `--fix`

2. **Test Suite**
   ```bash
   npm test
   ```
   - Or individually:
     - `bats tests/bash/`
     - `pytest tests/python/`
     - `cd dev-portal && npm test`

3. **Hook Validation**
   - Check all hooks are executable
   - Verify hook parity: `bash scripts/verify-hook-parity.sh`

4. **Skill Lint**
   - Find all SKILL.md files
   - Check frontmatter (name, description, framework)
   - Check line count (<300 recommended)
   - Report violations

5. **Secret Scan**
   ```bash
   bash scripts/secret-scan.sh --staged
   ```

6. **STATE.md Sync**
   - Verify STATE.md exists and is up to date
   - Force sync if stale: `bash .claude/hooks/post-tool-use-planning-sync.sh`

7. **Report**
   - Summarize results
   - List any failures
   - Suggest fixes
</process>

<success_criteria>
- [ ] Template sync passes (or drift documented)
- [ ] All tests pass
- [ ] All hooks executable
- [ ] No SKILL.md violations
- [ ] No secrets in staged files
- [ ] STATE.md is current
</success_criteria>
