---
name: backbone:close-feature
description: Close out a feature branch — verify all REQ- IDs have code and tests, run final traceability audit, full verify suite, code review, and suggest ship.
argument-hint: "[--feature <name>] [--skip-review]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
---
<objective>
Close out a feature by verifying all requirements are implemented and tested.

**When to use:**
- All tasks for a feature are marked [x] in 3-TASKS.md
- Before merging a feature branch
- Before running `/backbone:ship`

**What it does:**
1. Reads the PRD → collects all REQ- IDs
2. Verifies each REQ- ID has code + tests in the traceability matrix
3. Reports any gaps (BLOCK if requirements are missing)
4. Runs full verification suite (tests, build, template sync, security)
5. Runs code review on changed files
6. If all clean: suggests `/backbone:ship`

**Flags:**
- `--feature <name>` — Feature name (otherwise auto-detected from last design doc)
- `--skip-review` — Skip the code review step (time-saver for trivial features)
</objective>

<process>
## Step 0: Parse Arguments

- Extract `--feature` (optional) — feature name
- Extract `--skip-review` (optional) — skip code review
- If no feature name: read `backbone/3-TASKS.md`, find most recently completed feature

## Step 1: Collect REQ- IDs

- Read the PRD: `backbone/prd/YYYYMMDD-feature-name.md`
- Extract all REQ- IDs using regex: `REQ-\w+-\d+`
- Count total requirements
- Group by EARS type (Ubiquitous, Event-Driven, State-Driven, Unwanted, Optional)

## Step 2: Audit Traceability

- Read `storage/traceability/feature-name.md`
- For each REQ- ID:
  - Does it have a code file reference? If not → WARNING
  - Does it have a test file reference? If not → WARNING
  - Is it marked as `done`? If not → WARNING
- Produce a table:

  ```
  | REQ-ID | Type | Code File | Test File | Status |
  |--------|------|-----------|-----------|--------|
  | REQ-AUTH-001 | Ubiquitous | src/domain/Auth.java | test/domain/AuthTest.java | ✅ done |
  | REQ-AUTH-002 | Event | — missing — | — missing — | ❌ gap |
  ```

- If ANY gaps: print the gap report, ask user how to proceed (BLOCK or continue)

## Step 3: Final Verification

Run the full verification suite:

```bash
# Tests
npm test
bats tests/bash/
pytest tests/python/

# Build
npm run build

# Template sync
bash scripts/verify-template-sync.sh

# Security
bash scripts/secret-scan.sh --all
```

Record PASS/FAIL for each.

## Step 4: Code Review (skip with --skip-review)

Load `view backbone/skills/general/code-review/SKILL.md`
Review changed files since the feature branch started:
- Architecture violations (wrong imports in domain, etc.)
- Missing edge case handling
- English naming violations
- REQ- ID coverage in both code and tests

## Step 5: Report

Summarize the feature close-out:

```
✅ Feature close-out: <feature-name>

Requirements:
  Total REQ- IDs: 12
  Implemented:    12 ✅
  Tested:         11 ⚠️  (1 missing test)
  Coverage:       91.7%

Verification:
  Tests:       198 passing ✅
  Build:       success ✅
  Sync:        synced ✅
  Security:    clean ✅
  Code Review: 2 warnings (non-blocking)

Next: Run `/backbone:ship` to tag and release
```

If all gates pass, suggest:
- `git merge` the feature branch
- `/backbone:ship` for release
</process>

<critical_rules>
- NEVER mark a feature complete if REQ- IDs are missing code or tests — BLOCK
- NEVER skip the verification suite (tests, build, sync, security)
- NEVER skip code review unless --skip-review is explicit
- ALWAYS produce a summary table the user can review before proceeding
- ALWAYS leave the traceability matrix updated after running
</critical_rules>

<success_criteria>
- [ ] All REQ- IDs have code and test references in traceability
- [ ] All verification suite steps pass
- [ ] Code review completed (or explicit skip)
- [ ] Close-out report generated with next-action suggestion
- [ ] Traceability matrix reflects final state
</success_criteria>
