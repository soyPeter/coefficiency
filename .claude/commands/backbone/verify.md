---
name: backbone:verify
description: Run full verification pipeline — tests, build, template sync, security scan, requirement traceability, and health checks.
allowed-tools:
  - Read
  - Bash
  - Glob
  - Grep
required-skills: []
---

<objective>
Execute the complete verification pipeline for the Agentic Backbone generator.
Includes requirement traceability: validates every REQ-ID from the current
change folder has corresponding code and tests.

**Pipeline steps:**
1. Run all test suites (bash, python, node)
2. Build dev-portal
3. Verify template sync (backbone/ vs templates/backbone/)
4. Run security scans (secrets, base64)
5. Check hook parity
6. Validate skill frontmatter
7. Verify STATE.md is current
8. **Validate requirement traceability** — checks current change folder's REQ-IDs
   against traceability matrix for code + test coverage

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

8. **Requirement Traceability** (only if a change folder exists)
   - Detect the active change folder:
     ```bash
     ls -d backbone/artifacts/changes/CHNG-*/
     ```
   - Read the proposal.md, extract all REQ-IDs:
     ```bash
     grep -oE 'REQ-[A-Z0-9]+-[0-9]+' backbone/artifacts/changes/CHNG-XXX/proposal.md
     ```
   - For each REQ-ID, check the traceability matrix
   - Report gaps as a table

9. **Auto-Register NCRs for Failures**
   For each step that FAILED, auto-register an NCR:
   ```bash
   ./scripts/qms-register-issue.sh \
     --title "Verify failure: [step] - [details]" \
     --severity [level] \
     --category [type]
   ```

10. **Generate Report**
    - Write to `backbone/artifacts/changes/VERIFICATION.md`
    - Include timestamp, results, failures, NCRs registered
</process>

<success_criteria>
- [ ] All tests pass
- [ ] Dev portal builds successfully
- [ ] Templates in sync (or drift documented)
- [ ] No secrets detected
- [ ] All hooks executable
- [ ] All skills valid
- [ ] STATE.md current
- [ ] Every REQ-ID in the active change folder has code + tests
- [ ] VERIFICATION.md written with full results table
</success_criteria>