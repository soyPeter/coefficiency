---
name: backbone:close
description: Close feature with UAT, optionally ship. Consolidates close-feature and ship.
argument-hint: "<feature-name> [--ship|--release] [--no-tag] [--skip-review] [--skip-uat]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
required-skills: []
---

<objective>
Close out a feature by verifying all requirements are implemented and tested,
then optionally ship (run full release checklist).

**Consolidates:** `close-feature` and `ship`

**When to use:**
- All tasks for a feature are marked [x] in 3-TASKS.md
- Before merging a feature branch
- When ready to release (with --ship)

**Flags:**
- `--ship` / `--release` — Run full ship checklist (tests, version bump, tag, changelog)
- `--no-tag` — Close without git tag
- `--skip-review` — Skip the code review step
- `--skip-uat` — Skip the conversational UAT step
- `--skip-gate` — Skip the git proxy gate validation (push directly)
</objective>

<process>
## Step 0: Check Mode

Read `.MODE` file to determine behavior:
- `light`: Mark [x] only, skip verification suite
- `standard` / `full`: Run full close process

## Step 0a: Commit Leftovers

Before closing, commit any uncommitted changes so close runs on a clean state:

1. **Check for pending changes:**
   ```bash
   git status --porcelain
   ```

2. **If there are uncommitted changes:**
   - Stage all: `git add -A`
   - Use CHNG-XXX as scope in commit message
   - Default message: `"chore(<scope>): close leftovers for CHNG-XXX"`
   - Commit without triggering full pre-commit suite: `git commit --no-verify -m "..."`

3. **Confirm clean state before proceeding.**

## Step 1: Detect Feature

- Use `<feature-name>` argument if provided
- Otherwise read [`backbone/3-TASKS.md`](backbone/3-TASKS.md), find most recently completed feature
- Find the associated CHNG-XXX folder

## Step 1a: Check Progress Ledger (REQ-HOFF-002)

If a subagent session was used, check the durable progress ledger for any tasks already completed but not reflected in 3-TASKS.md:

```bash
cat .backbone/ledger/progress.md 2>/dev/null || echo "(no ledger)"
```

Sync any ledger-completed tasks to 3-TASKS.md before proceeding.

## Step 2: Collect REQ- IDs

- Read the proposal: `backbone/artifacts/changes/CHNG-XXX/proposal.md`
- Extract all REQ- IDs using regex: `REQ-\w+-\d+`
- Count total requirements

## Step 3: Audit Traceability

Mode `full` only (light skips):
- Read `backbone/artifacts/traceability/feature-name.md`
- For each REQ- ID:
  - Does it have a code file reference? If not → WARNING
  - Does it have a test file reference? If not → WARNING
  - Is it marked as `done`? If not → WARNING

If mode is `full`, produce a gap report table.

## Step 3a: Review Decision Log (REQ-DLOG-001)

Read `backbone/artifacts/changes/CHNG-XXX/decisions.md`:
- Are all decisions resolved? Flag any open auto/human decisions.
- Are there `human` decisions that were made without explicit user sign-off? Flag them.
- Summary: "Decisions: N auto, N human, N unresolved"

## Step 3b: YAGNI Over-Engineering Check (REQ-YAGNI-001)

Before closing, do a lightweight YAGNI audit on the diff:
- Scan `git diff --stat` for unnecessary files, dependencies, or abstractions
- Check if stdlib/native/platform features were overlooked (e.g., custom datepicker when `<input type="date">` works)
- Flag any speculative generality (configs for features not yet built, abstraction layers for one implementation)
- Log findings: "YAGNI audit: N issues (N fixed, N flagged as deliberate)"

## Step 4: Final Verification (standard/full only)

Run the verification suite:

```bash
npm test
bats tests/bash/
pytest tests/python/
npm run build
bash scripts/verify-template-sync.sh
bash scripts/secret-scan.sh --staged
```

## Step 5: Code Review (skip with --skip-review)

Load `view backbone/skills/general/code-review/SKILL.md`
Review changed files for architecture violations, edge cases, naming.

## Step 5a: Conversational UAT (skip with --skip-uat)

Before marking the feature complete, run user acceptance testing:

1. **Run UAT:**
   ```bash
   # /backbone:uat presents each task scenario one at a time
   # User responds 'pass' or 'fail' with details
   ```

2. **On failure:** Diagnose root cause, generate fix plans, offer gaps-only execution
3. **On all pass:** UAT session recorded in `backbone/artifacts/changes/CHNG-XXX/uat.md`
4. **Skip option:** Use `--skip-uat` to bypass UAT (e.g., for trivial changes or when UAT was already completed separately)

## Step 5b: Push Through Gate (default)

Before merging, push through the validation gate to catch issues in isolation:

```bash
# Load the git-proxy-gate skill
view backbone/skills/general/git-proxy-gate/SKILL.md

# Push current branch through gate
bash scripts/gate-push.sh
```

- Gate runs build, lint, tests, secret scan, and template sync in an isolated worktree
- Safe findings are auto-fixed (with `--yes`); judgement calls are escalated
- On success: branch is pushed to origin automatically
- On failure: worktree preserved at `<project>-gate/<branch>/` for inspection
- Skip with `--skip-gate` or `--skip-review` flag

**Legacy fallback** (if gate-push.sh is unavailable or `--skip-gate`):

If you're in a git worktree (check `git rev-parse --git-dir` contains `worktrees`):

```bash
# Detect current branch and parent repo
BRANCH=$(git branch --show-current)
PARENT_REPO=$(git rev-parse --git-common-dir 2>/dev/null | sed 's|/*\.git/worktrees/.*||')
cd "$PARENT_REPO"

# Merge — auto-detects base from branch name
./scripts/worktrunk.sh merge "$BRANCH"
```

If worktrunk is not available:
```
cd <parent-repo>
git checkout <base> && git merge --no-ff <branch>
```

## Step 5c: Generate Documentation & Verify Tests

1. **Generate release/feature docs:**
   ```bash
   ./scripts/generate-feature-docs.sh CHNG-XXX
   ```

2. **Verify REQ-ID test coverage:**
   ```bash
   ./scripts/verify-req-tests.sh CHNG-XXX
   ```
   Exit code 1 = coverage gaps (advisory), exit code 2 = test failures (blocking).

## Step 5d: QMS Gate

Check all NCRs linked to this change folder are closed before marking complete:

```bash
# Find NCRs linked to this change
for f in backbone/artifacts/qms/ncr/*.yml; do
  if grep -q "change: CHNG-XXX" "$f" 2>/dev/null; then
    STATUS=$(grep "^status:" "$f" | sed 's/status: *//' | tr -d '"')
    ID=$(grep "^id:" "$f" | sed 's/id: *//' | tr -d '"')
    TITLE=$(grep "^title:" "$f" | sed 's/title: *//' | tr -d '"')
    if [[ "$STATUS" != "closed" ]]; then
      echo "❌ BLOCKED: $ID ($TITLE) — resolve before closing"
      exit 1
    fi
  fi
done
```

For `--ship`, also block on any open critical NCRs project-wide:

```bash
./scripts/hooks/pre-release-qms.sh
```

## Step 5e: Generate In-Code Developer Documentation

Scan changed files and add missing public API documentation (JavaDoc, JSDoc, TSDoc, etc.).

1. **Detect language from changed files:**
   - `*.java` → JavaDoc (load `skill "javadoc"`)
   - `*.ts`, `*.tsx` → TSDoc (load `skill "coding-standards"` for JSDoc conventions)
   - `*.js`, `*.jsx` → JSDoc
   - `*.py` → Google-style docstrings (load `skill "python-patterns"`)
   - `*.kt`, `*.kts` → KDoc (load `skill "kotlin-patterns"`)

2. **For each changed source file:**
   - Read the file
   - Identify public classes, methods, functions, and interfaces missing doc comments
   - Add doc comments following framework conventions:
     - `@param` and `@return` for all method parameters/returns
     - Description of purpose, not just what it does
     - `@throws` / exception documentation where applicable
   - Skip: test files, private/internal members, trivial getters/setters

3. **Commit doc additions as a separate refactor commit:**
   ```bash
   git add <changed-source-files>
   git commit -m "docs(<scope>): add in-code documentation for CHNG-XXX"
   ```

## Step 6: Mark Feature Complete

- Update 3-TASKS.md: mark feature tasks as [x]
- Update STATE.md if needed

## Step 7: Ship (if --ship or --release)

Run the ship checklist:

```bash
# Tests
npm test

# Build
npm run build

# Security
bash scripts/secret-scan.sh --all
bash scripts/prompt-injection-scan.sh --diff origin/main
bash scripts/base64-scan.sh

# Version bump
# Read backbone/VERSION, bump CalVer
# Update backbone/VERSION

# Changelog — generate from conventional commits since last tag
NEW_TAG=$(date +%Y.%-m.%-d)
bash scripts/generate-changelog.sh > CHANGELOG.md.tmp
if [ -s CHANGELOG.md.tmp ] && ! grep -q "none" CHANGELOG.md.tmp; then
    cat CHANGELOG.md.tmp
    # Append to existing CHANGELOG or create new one
    if [ -f CHANGELOG.md ]; then
        # Insert new entry after header
        tail -n +3 CHANGELOG.md >> CHANGELOG.md.new 2>/dev/null || true
        head -3 CHANGELOG.md > CHANGELOG.md.new 2>/dev/null || true
        cat CHANGELOG.md.tmp >> CHANGELOG.md.new
        mv CHANGELOG.md.new CHANGELOG.md
    else
        mv CHANGELOG.md.tmp CHANGELOG.md
    fi
    git add CHANGELOG.md
fi
rm -f CHANGELOG.md.tmp CHANGELOG.md.new

# Tag
git tag "$NEW_TAG"
```

## Step 8: Report

```
✅ Feature close-out: <feature-name>

Requirements:
  Total REQ- IDs: N
  Implemented:    N ✅
  Tested:         N ✅

Traceability:    ✅ (full mode)
Verification:   ✅ (standard/full) / ⏭️ (light)

Next: /backbone:ship (if not already shipped)
```

If --ship was used, show the release report instead.
</process>

<critical_rules>
- NEVER mark a feature complete if REQ- IDs are missing code or tests in full mode
- NEVER skip verification in standard/full mode
- The --no-tag flag skips git tagging but still runs verification
</critical_rules>

<success_criteria>
- [ ] Feature marked complete in 3-TASKS.md
- [ ] All REQ- IDs verified (full mode)
- [ ] Verification suite passed (standard/full)
- [ ] Code review completed or skipped
- [ ] Git tag created (unless --no-tag)
- [ ] Close report generated
</success_criteria>