---
name: backbone:review
description: Run verification and review across quick/standard/deep/full-audit depths with checkpoint protocol
argument-hint: "[--depth quick|standard|deep|full-audit] [--no-subagent]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - Task
required-skills:
  - general/coding-standards
  - general/code-review
  - cross-cutting/architecture
  - cross-cutting/security
  - cross-cutting/testing/test-quality
  - cross-cutting/code-quality
---

Run verification and review: $ARGUMENTS

Read `backbone/.MODE` for default depth:
- `full`: default depth = deep (full audit + subagent code review)
- `standard`: default depth = standard (full verify suite)
- `light`: default depth = quick (tests + git status)

## Depths
- **quick**: Run tests, check git status, check for secrets
- **standard**: Run tests, build, security scan, template sync check, traceability audit
- **deep**: Standard + preflight gating + signal-based specialist selection with multi-pass adversarial review. Spawns per-specialist subagents based on change signals.
- **full-audit**: Full codebase audit via 4 parallel subagents — DDD/SOLID/Architecture, API/Security, Code Quality, Test Quality. Writes comprehensive report.

## Result Parsing (REQ-CHK-002)

After any subagent returns, parse its first line for a result tag:

```bash
RESULT_LINE=$(head -1 <subagent_output>)
case "$RESULT_LINE" in
  "RESULT: CHECKPOINT")
    CHECKPOINT_TYPE=$(echo "$subagent_output" | sed -n '2s/^CHECKPOINT_TYPE: //p')
    CHECKPOINT_CTX=$(echo "$subagent_output" | sed -n '3s/^Checkpoint context: //p')
    # Present to user, collect response
    user_response=$(question "Checkpoint: $CHECKPOINT_CTX" "Type: $CHECKPOINT_TYPE")
    # Spawn continuation with prior_state + checkpoint_response
    spawn continuation with args: "--prior-state <state> --checkpoint-response <response>"
    ;;
  "RESULT: FAILED")
    echo "Subagent failed. Review partial results above." >&2
    ;;
  *)
    # COMPLETE or unknown — continue normally
    ;;
esac
```

## Preflight Gate

Before any AI review, run automated checks and STOP on failure:

```bash
npm run build  || exit 1
npm run lint   || exit 1
npm run test   || exit 1
```

If preflight fails, report the failure and do NOT proceed to AI review.

## Signal Detection

Detect what changed to select relevant specialists (deep mode only):

```bash
CHANGED_FILES=$(git diff --name-only HEAD~1)
HAS_DB=$(echo "$CHANGED_FILES" | grep -qE '(db|migrations?|schema|sql)' && echo true || echo false)
HAS_API=$(echo "$CHANGED_FILES" | grep -qE '(api|routes?|controllers?|endpoints?)' && echo true || echo false)
HAS_FRONTEND=$(echo "$CHANGED_FILES" | grep -qE '\.(tsx|jsx|vue|svelte)$' && echo true || echo false)
HAS_BACKEND=$(echo "$CHANGED_FILES" | grep -qE '(service|repository|domain|adapter|port)' && echo true || echo false)
FILE_COUNT=$(echo "$CHANGED_FILES" | wc -l)
NEEDS_ARCH=$([ "$FILE_COUNT" -gt 20 ] && echo true || echo false)
```

## Specialist Mapping

Spawn a subagent per matching specialist (always: code-quality, security, performance, tests):

| Specialist | Signal | Focus Areas |
|------------|--------|-------------|
| Code Quality | always | Style, bugs, error handling, maintainability, duplication |
| Security | always | Auth flaws, injection, secrets, insecure defaults |
| Performance | always | N+1 queries, blocking ops, memory leaks |
| Test Coverage | always | Missing tests, edge cases, mock appropriateness |
| Database | hasDb | Query performance, indexes, migration safety |
| Architecture | needsArchitecture | Module boundaries, dep direction, layer coupling |
| API | hasApi | REST conventions, status codes, pagination |
| Frontend | hasFrontend | Component boundaries, state, a11y |
| Backend | hasBackend | Service boundaries, domain logic, concurrency |

## Process

### quick / standard
1. Check git status for changed files
2. Run tests
3. Run `./scripts/secret-scan.sh --staged` for secrets
4. For standard: run full verification suite (build, template sync, traceability)
5. Write report to `backbone/artifacts/reports/review-$(date +%Y-%m-%d).md`

### deep
1. Run preflight gate (build + lint + test). Stop if any fail.
2. Detect change signals from `git diff --name-only HEAD~1`
3. Spawn parallel specialist subagents from matching signals. Each returns JSON findings.
4. Aggregate findings — deduplicate by `pass:file:line:description`, group by severity
5. Register QMS records: for each P0/P1 finding, run `./scripts/qms-register-issue.sh` then `./scripts/qms-capa-create.sh`
6. Compile report with P0→P3 severity classification (Critical/High/Medium/Low). Skip remediation plan (reserved for full-audit).

### full-audit
Full codebase deep-review:
1. Glob `src/main/java/**/*.java` and `frontend/src/**/*.{ts,tsx}`
2. Spawn 4 parallel `gsd-codebase-mapper` subagents (DDD+SOLID, API+Security, Code Quality, Test Quality)
3. Compile deep-review report at `backbone/artifacts/reports/deep-review-$(date +%Y-%m-%d).md`
4. Register QMS records: for each P0/P1 finding, run `./scripts/qms-register-issue.sh` then `./scripts/qms-capa-create.sh`
5. Generate remediation plan at `backbone/artifacts/reports/remediation-$(date +%Y-%m-%d).md` with phases, steps, dependency graph, rollback strategy, model tier assignment, success criteria

## Report Sections
- What's Clean (things done right)
- CRITICAL Security Findings
- SOLID Violations
- DDD Health Assessment
- API Contract Issues
- Clean Code / Maintainability
- Test Coverage & Quality
- Non-Issues (intentional)
- Consolidated Priority Recommendations (P0→P3 with REQ-IDs)
- Summary Statistics

## QMS & Remediation

After any deep/full-audit review, the following artifacts are produced:

| Artifact | Path | Purpose |
|----------|------|---------|
| NCR records | `backbone/artifacts/qms/ncr/NCR-XXX.yml` | Nonconformance report per P0/P1 finding |
| CAPA records | `backbone/artifacts/qms/capa/CAPA-XXX.yml` | Corrective action linked to each NCR |
| Remediation plan | `backbone/artifacts/reports/remediation-YYYY-MM-DD.md` | Phased action plan with dependency graph |

The QMS chain: Finding → NCR → CAPA → Remediation plan step → Task → Commit → CAPA closure.
