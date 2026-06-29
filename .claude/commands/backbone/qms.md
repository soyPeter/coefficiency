---
name: backbone:qms
description: Quality management — register NCR, compact stale entries. Disabled in Light mode.
argument-hint: "<ncr-description> [--severity <level>] [--category <type>] [--change CHNG-XXX] [--compact]"
allowed-tools:
  - Bash
  - Read
  - Question
required-skills:
  - cross-cutting/qms/qms-iso9001
  - general/coding-standards
  - general/spec-driven-development
---

<objective>
Quality Management System — register nonconformances and compact stale entries.

**Consolidates:** `register-issue` and `compact`

**When to use:**
- A defect or nonconformance is discovered
- Before starting a new feature (compact stale entries)
- After creating a new decision that supersedes old ones

**Flags:**
- `--compact` — Scan 5-DECISIONS.md and 6-MEMORY.md for stale entries

**Disabled in Light mode:** Check MODE at start. If `light`, print
"QMS disabled in Light mode" and exit 0.
</objective>

<process>
## Step 0: Check Mode

Read `.MODE` file:
- If `light`: print "QMS disabled in Light mode" and exit 0

## Step 1: Parse Arguments

- If `--compact` flag: run compaction only
- Otherwise: register NCR

## Step 2: Register NCR (if no --compact)

Gather details using `Question` tool (if not provided via flags):
1. **Title** — Short description of the issue
2. **Severity** — critical, major, minor, observation
3. **Category** — code, process, documentation, configuration, performance, security, other
4. **Change link** — Optional CHNG-XXX to link

Build and run:
```bash
./scripts/qms-register-issue.sh \
  --title "..." \
  --severity <level> \
  --category <type> \
  [--change CHNG-XXX]
```

The script auto-creates a CAPA linked to the NCR.
The loaded skills (`qms-iso9001`, `coding-standards`, `spec-driven-development`) give you the context to:
- Analyze the NCR's root cause
- Apply proper coding standards when the fix involves code
- Follow specification-driven development for any design changes
- Generate a meaningful CAPA action plan using this knowledge

Report:
```
✅ Registered: NCR-042
  Severity: major
  Category: code
  Change:   CHNG-009 (if linked)
✅ CAPA auto-created: CAPA-001

Next steps:
  Update CAPA:   ./scripts/qms-capa-close.sh --capa CAPA-001 --verification "..."
  View report:   ./scripts/qms-report.sh --aging
```

## Step 3: Compact (if --compact)

### Scan Decisions

Read [`backbone/5-DECISIONS.md`](backbone/5-DECISIONS.md) and find all entries without `**Status:**`:
```bash
grep -n '^## Decision' backbone/5-DECISIONS.md
```

### Scan Memory

Read [`backbone/6-MEMORY.md`](backbone/6-MEMORY.md) and find list items without `[Archived:`:
```bash
grep -n '^- \*\*\[Archived:\|^- \*\*\[Stale:' backbone/6-MEMORY.md
```

### Present Candidates

```
📋 Compact Report (dry-run)
  5-DECISIONS.md: N entries without Status
  6-MEMORY.md: N entries not archived
  Run without --dry-run to review and mark.
```

Present each candidate to user for confirmation.

### Apply Changes

For each confirmed supersession/archive, add the marker.

## Step 4: Report

```
✅ QMS operation complete
  - NCR registered: NCR-042 (if registered)
  - Decisions marked: N
  - Memory entries archived: N
```
</process>

<critical_rules>
- ALWAYS ask before registering if unsure about severity or category
- NEVER delete entries — only add markers
- QMS commands are disabled in Light mode
</critical_rules>

<success_criteria>
- [ ] NCR created with appropriate severity, category, and title (if not --compact)
- [ ] Linked to change folder if applicable
- [ ] (if --compact) Stale entries identified and marked
- [ ] User informed of next steps
</success_criteria>