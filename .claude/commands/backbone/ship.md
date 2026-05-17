---
name: backbone:ship
description: Release checklist and execution. Runs tests, build, security scan, version bump, tag, and changelog generation.
argument-hint: "[--dry-run] [--skip-tests] [--skip-security]"
allowed-tools:
  - Read
  - Bash
  - Write
  - Edit
  - Glob
  - Grep
---

<objective>
Execute release checklist for the Agentic Backbone generator.

**When to use:**
- Preparing a new release
- After completing a milestone
- Before tagging a version
- When all tests pass and you're ready to ship

**Release Gates:**
1. All tests pass
2. Build succeeds
3. Security scan clean
4. Version bumped
5. Changelog updated
6. Git tag created

**Safety:**
- `--dry-run`: Show what would happen without executing
- `--skip-tests`: Skip test execution (not recommended)
- `--skip-security`: Skip security scan (not recommended)
</objective>

<process>
1. **Pre-flight Checks**
   - Parse flags: `--dry-run`, `--skip-tests`, `--skip-security`
   - Check current branch: must be `main` or `dev` or release branch
   - Check for uncommitted changes: must be clean
   - If dirty: abort and ask user to commit first

2. **Gate 1: Tests** (skip with `--skip-tests`)
   - Run: `npm test` (Node tests)
   - Run: `pytest tests/python/` (Python tests)
   - Run: `bats tests/bash/` (Bash tests)
   - If any fail: abort, route to `/backbone:debug`
   - Record: "Tests: X passing, Y failing"

3. **Gate 2: Build** (always run)
   - Run: `npm run build` (dev-portal)
   - If fails: abort, fix build errors
   - Record: "Build: success"

4. **Gate 3: Security Scan** (skip with `--skip-security`)
   - Run: `bash scripts/secret-scan.sh --all`
   - Run: `bash scripts/prompt-injection-scan.sh --diff origin/main`
   - Run: `bash scripts/base64-scan.sh`
   - If findings: abort, route to `/backbone:debug`
   - Record: "Security: clean"

5. **Gate 4: Template Sync** (always run)
   - Run: `bash scripts/verify-template-sync.sh`
   - If fails: abort, run `--fix`
   - Record: "Templates: synced"

6. **Gate 5: Version Bump** (always run)
   - Read current version from `backbone/VERSION`
   - Determine next version (CalVer: YYYY.MM.DD)
   - If version already current: skip
   - Else: update `backbone/VERSION`
   - Record: "Version: {old} → {new}"

7. **Gate 6: Changelog** (always run)
   - Run changelog generation (from conventional commits)
   - Append changes since last tag
   - Record: "Changelog: updated"

8. **Gate 7: Documentation** (always run)
   - Check `backbone/5-DECISIONS.md` has recent entries
   - Check `backbone/6-MEMORY.md` has recent entries
   - Check `backbone/planning/STATE.md` is synced
   - Record: "Documentation: current"

9. **Commit Release** (skip in `--dry-run`)
   - Stage all changes: `git add -A`
   - Commit: `chore(release): bump version to YYYY.MM.DD`
   - Tag: `git tag -a YYYY.MM.DD -m "Release YYYY.MM.DD"`
   - Record: "Tag: YYYY.MM.DD created"

10. **Post-release** (skip in `--dry-run`)
    - Push branch: `git push origin {branch}`
    - Push tag: `git push origin YYYY.MM.DD`
    - Record: "Pushed to origin"

11. **Generate Release Report**
    ```
    🚀 Release Report: YYYY.MM.DD
    ═══════════════════════════════════════════
    
    Gates:
      ✅ Tests:       101 passing
      ✅ Build:       success
      ✅ Security:    clean
      ✅ Templates:   synced
      ✅ Version:     2026.04.24 → 2026.04.25
      ✅ Changelog:   updated
      ✅ Docs:        current
    
    Git:
      Commit: abc1234
      Tag:    2026.04.25
      Branch: dev
    
    Changes since last release:
      - feat(security): add read-guard, boundary-check...
      - docs: update PRD index...
      - feat(gsd): make GSD security layer default...
    ```

12. **Dry Run Output** (if `--dry-run`)
    - Show all steps that would execute
    - Show commands that would run
    - Do NOT execute any git commands
    - State: "This was a dry run. Remove --dry-run to execute."
</process>

<success_criteria>
- [ ] All release gates pass (or explicit skip)
- [ ] Tests pass before proceeding
- [ ] Build succeeds
- [ ] Security scan clean
- [ ] Version bumped correctly
- [ ] Changelog updated
- [ ] Tag created and pushed
- [ ] Release report generated
</success_criteria>
