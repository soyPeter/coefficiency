<!-- FRAMEWORK: GENERAL -->
---
framework: general
name: qms-iso9001
description: ISO 9001-inspired Quality Management System — nonconformance registration, CAPA, governance, and continuous improvement. Use when registering quality issues, creating corrective actions, running QMS reviews, or enforcing quality gates.
required-skills:
  - general/coding-standards
  - general/spec-driven-development
---

# ISO 9001 QMS — Quality Management System

This skill describes the backbone's built-in Quality Management System, inspired by ISO 9001:2015. It provides scripts, templates, and governance hooks for formal quality management.

## When to Use

- Registering a nonconformance (bug, process gap, documentation issue)
- Creating a corrective action from an identified issue
- Closing a CAPA with verification of effectiveness
- Running a QMS status report
- Performing a management review
- Enforcing quality gates before commit/release

## QMS Data Location

All QMS data lives in `backbone/artifacts/qms/`:

| Directory | Contents |
|-----------|----------|
| `backbone/artifacts/qms/ncr/` | Nonconformance Reports (YAML) |
| `backbone/artifacts/qms/capa/` | Corrective Action records (YAML) |
| `backbone/artifacts/qms/objectives/` | Quality objectives and targets (YAML) |

## Commands

### Register a Nonconformance

```bash
./scripts/qms-register-issue.sh \
  --title "Missing input validation on login" \
  --severity critical \
  --category code \
  --source test \
  --description "Login endpoint accepts SQL injection patterns without sanitization"
```

**Severity levels:** critical, major, minor, observation
**Categories:** process, documentation, code, configuration, performance, security, other
**Sources:** review, test, incident, audit, user, other

### Create a Corrective Action

```bash
./scripts/qms-capa-create.sh \
  --ncr NCR-001 \
  --owner "alice" \
  --due 2026-06-23 \
  --root-cause "No validation middleware in request pipeline" \
  --action-plan "Add input sanitization middleware + unit tests"
```

CAPA status lifecycle: `open → in-progress → verified → closed`

### Close a CAPA

```bash
./scripts/qms-capa-close.sh \
  --capa CAPA-001 \
  --verification "Sanitization middleware deployed to staging, 5 tests passing, code reviewed"
```

### Generate QMS Report

```bash
./scripts/qms-report.sh           # Full report (NCRs by status/severity/category, CAPA aging)
./scripts/qms-report.sh --summary # One-line summary for commit messages
./scripts/qms-report.sh --aging   # Items past due
```

## Quality Objectives

Quality objectives are stored in `backbone/artifacts/qms/objectives/` as YAML files. Example:

```yaml
# objectives/2026-Q2.yml
period: "2026-Q2"
objectives:
  - metric: "NCR closure rate"
    target: "80%"
    current: "75%"
    review_date: "2026-07-01"
  - metric: "CAPA aging > 30 days"
    target: "0"
    current: "2"
    review_date: "2026-07-01"
```

## Agent Auto-Registration (Mandatory)

When implementing a task and you discover a bug, design flaw, missing requirement, or any nonconformance, **automatically register an NCR**. Do not wait for the user to ask.

```bash
./scripts/qms-register-issue.sh \
  --title "Specific issue found" \
  --severity major \
  --category code \
  --change CHNG-XXX \
  --description "Found during implementation: what happened, why it's wrong"
```

If the issue requires a corrective action, create a CAPA:

```bash
./scripts/qms-capa-create.sh \
  --ncr NCR-XXX \
  --root-cause "Root cause analysis" \
  --owner dev \
  --due YYYY-MM-DD
```

The NCR is linked to the change folder via `--change CHNG-XXX`. This enables:
- **Gate Z4**: blocks archiving the change while open NCRs exist
- **Pre-tool-use advisory**: warns when editing files in a change with open NCRs
- **lessons-learned.md**: auto-generated on archive with linked NCRs listed

**Exemptions:** Trivial typos, cosmetic issues, or changes that don't affect functionality can skip NCR registration. When in doubt, register.

## Governance Hooks

The following hooks enforce QMS gates:

| Hook | When | Action |
|------|------|--------|
| `pre-tool-use-qms-check.sh` | Pre-Write/Edit | Advisory: warns if change folder has open NCRs |
| `pre-commit-qms.sh` | Pre-commit | Warns if any CAPA is past due |
| `pre-release-qms.sh` | Pre-release | Blocks if any critical NCR is open |

## Continuous Improvement Loop

The QMS implements a Plan-Do-Check-Act (PDCA) cycle:

1. **Plan:** Define quality objectives in `backbone/artifacts/qms/objectives/`
2. **Do:** Register NCRs and create CAPAs during development
3. **Check:** Run `qms-report.sh` to review metrics and trends
4. **Act:** Close CAPAs with verification, update objectives, run management review

### Management Review

Run a management review at least quarterly:
1. `./scripts/qms-report.sh` — review current state
2. Review quality objectives vs actuals
3. Identify trends (e.g., "3 NCRs in 'code' category this quarter")
4. Update `backbone/artifacts/qms/objectives/` with new targets
5. Record decisions in [`backbone/5-DECISIONS.md`](backbone/5-DECISIONS.md)
6. Record lessons in [`backbone/6-MEMORY.md`](backbone/6-MEMORY.md)

## Change Folder Integration

NCRs can be linked to a change folder with `--change CHNG-XXX`:

```bash
./scripts/qms-register-issue.sh \
  --title "Race condition in auth" \
  --severity major \
  --category code \
  --change CHNG-009
```

The NCR YAML will include `change: CHNG-009` for traceability.

### Gates

- **Archive Gate Z4** (`backbone-change-archive.sh`): Blocks archiving a change if any open NCRs are linked to it. Use `--force` to override.
- **Archive auto-generated lessons**: When a change with linked NCRs is archived, a `lessons-learned.md` is created in the archive folder with placeholders for root cause, corrective actions, and prevention.

## Quality Gates in Workflow

During development:
1. **Bug found** → Register NCR with `qms-register-issue.sh` and link to change: `--change CHNG-XXX`
2. **Fix planned** → Create CAPA with `qms-capa-create.sh`
3. **Fix implemented** → Close CAPA with `qms-capa-close.sh --verification "..."`
4. **Before commit** → Pre-commit hook checks CAPA aging
5. **Before archive** → Gate Z4 blocks if open NCRs linked to change
6. **After archive** → Fill in `lessons-learned.md` with root cause and prevention
7. **Quarterly** → Management review with `qms-report.sh`

## ISO 9001 Clause Mapping

| ISO 9001 Clause | Backbone QMS Element |
|-----------------|----------------------|
| 7.5 Documented Information | YAML files in `backbone/artifacts/qms/` |
| 8.7 Control of Nonconforming Outputs | NCR registration + severity classification |
| 10.1 Nonconformity and Corrective Action | CAPA workflow (root cause → action → verification) |
| 9.1 Monitoring, Measurement, Analysis | `qms-report.sh` metrics and trends |
| 9.3 Management Review | Quarterly review process |
| 10.3 Continual Improvement | PDCA cycle + trend analysis → improvement suggestions |

## Anti-patterns

- **Registering NCRs without CAPAs** — Every significant NCR should have a linked CAPA
- **Closing CAPAs without verification** — Always record what was done to verify effectiveness
- **Ignoring trends** — If the same category keeps appearing, address the systemic root cause
- **Skipping management review** — The improvement loop only works if you close it
