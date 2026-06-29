---
description: Close a feature — verify all REQ-IDs, run UAT, push through gate, archive change folder
agent: plan
required-skills:
  - general/coding-standards
  - general/git-commit
  - general/git-proxy-gate
---

> **skill loading:** Read this command's `required-skills` frontmatter above. For each entry, check if `backbone/skills/<path>/SKILL.md` exists — if yes, `view` it; otherwise use `skill tool "<basename>"` as fallback.

Close out the current or specified feature by verifying all requirements are implemented and tested: $ARGUMENTS

Read `backbone/.MODE`:
- `full`/`standard`: Run full close process — UAT, verify traceability, mark tasks [x], merge worktree, archive
- `light`: Mark [x] only, skip verification

Flags:
- `--skip-uat`: Skip conversational UAT step
- `--skip-gate`: Skip git proxy gate validation (push directly)
- `--ship` / `--release`: Version bump + tag + changelog + push

Process:
1. Find the active change folder in `backbone/artifacts/changes/CHNG-*/`
2. Verify all REQ-IDs have code + tests in traceability matrix
3. Run `./scripts/verify-traceability.sh`
4. **Code Review**: Review changed files for architecture violations, edge cases, naming
5. **UAT** (unless `--skip-uat`): Run `/backbone:uat` to verify each task scenario works as expected
   - If any scenario fails: offer fix (diagnose → plan → gaps-only execution) or proceed with known issues
6. **QMS Gate**: Check for open NCRs
   - If any NCR links to this CHNG (`grep "change: CHNG-XXX" backbone/artifacts/qms/ncr/*.yml`): verify it's closed. Block if open.
   - If `--ship`: run `./scripts/hooks/pre-release-qms.sh` — blocks on open critical NCRs
7. **Push through gate** (default, skip with `--skip-gate`):
   - Load git-proxy-gate skill: `view backbone/skills/general/git-proxy-gate/SKILL.md`
   - Run gate: `bash scripts/gate-push.sh`
   - Gate validates (build, lint, tests, scan, template sync) in isolated worktree
   - On failure: worktree preserved at `<project>-gate/<branch>/` for inspection
8. If in a worktree and `--skip-gate` (`git rev-parse --git-dir | grep worktrees`): merge back to dev
   - `PARENT_REPO=$(git rev-parse --git-common-dir | sed 's|/*\.git/worktrees/.*||')`
   - `cd "$PARENT_REPO" && ./scripts/worktrunk.sh merge $(git branch --show-current)`
9. Run `./scripts/generate-feature-docs.sh CHNG-XXX` to generate release notes, memory entry, and feature docs
10. Run `./scripts/verify-req-tests.sh CHNG-XXX` to verify each REQ-ID has test coverage
11. Mark all tasks [x] in [`backbone/3-TASKS.md`](backbone/3-TASKS.md)
12. Run `./scripts/backbone-change-archive.sh CHNG-XXX` to archive
