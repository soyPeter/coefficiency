---
name: backbone:verify
description: Run full verification pipeline — tests, build, template sync, security scan, and health checks.
allowed-tools:
  - Read
  - Bash
  - Glob
  - Grep
---

<objective>
Execute the complete verification pipeline for the Agentic Backbone generator.

**Pipeline steps:**
1. Run all test suites (bash, python, node)
2. Build dev-portal
3. Verify template sync (backbone/ vs templates/backbone/)
4. Run security scans (secrets, base64)
5. Check hook parity
6. Validate skill frontmatter
7. Verify STATE.md is current

**Output:** VERIFICATION.md report with PASS/FAIL for each step.
</objective>

<process>
1. **Tests**
   ```bash
   npm test
   ```
   - If any suite fails, report and stop (unless --continue flag)

2. **Build**
   ```bash
   cd dev-portal && npm run build
   ```
   - Verify build completes without errors

3. **Template Sync**
   ```bash
   bash scripts/verify-template-sync.sh
   ```
   - Report drift if found
   - Suggest --fix if drift detected

4. **Security Scans**
   ```bash
   bash scripts/secret-scan.sh --all
   bash scripts/base64-scan.sh --all
   ```
   - Report any findings

5. **Hook Parity**
   ```bash
   bash scripts/verify-hook-parity.sh
   ```
   - Verify all hooks installed and executable

6. **Skill Validation**
   - Find all SKILL.md files
   - Check frontmatter: name, description, framework
   - Check line count <= 300
   - Report violations

7. **STATE.md Sync**
   ```bash
   bash .claude/hooks/post-tool-use-planning-sync.sh
   ```
   - Verify STATE.md reflects current 3-TASKS.md

8. **Generate Report**
   - Write to `backbone/planning/VERIFICATION.md`
   - Include timestamp, results, failures, recommendations
   - Format:
     ```markdown
     # Verification Report — YYYY-MM-DD HH:MM:SS
     
     | Step | Status | Details |
     |------|--------|---------|
     | Tests | ✅/❌ | ... |
     ...
     ```
</process>

<success_criteria>
- [ ] All tests pass
- [ ] Dev portal builds successfully
- [ ] Templates in sync (or drift documented)
- [ ] No secrets detected
- [ ] All hooks executable
- [ ] All skills valid
- [ ] STATE.md current
- [ ] VERIFICATION.md written
</success_criteria>
