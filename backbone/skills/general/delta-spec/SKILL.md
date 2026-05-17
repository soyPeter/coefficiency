---
name: "Delta Specification Conventions"
description: "Track changes to existing systems with structured delta specifications documenting ADDED, MODIFIED, and REMOVED requirements for brownfield projects."
framework: "general"
---
<!-- FRAMEWORK: GENERAL -->
# Delta Specification Conventions

## Purpose

Track changes to existing systems with structured delta specifications. Delta specs document ADDED, MODIFIED, and REMOVED requirements for brownfield projects.

## When to Use

- Adding features to existing codebases
- Refactoring legacy code
- Migrating or modernizing systems
- Any change that affects existing requirements

## Delta Spec Format

```markdown
# Delta Specification: CHANGE-NNN

**Title:** [Brief description]
**Date:** [YYYY-MM-DD]
**Related PRD:** [Link to original PRD]
**Impact:** [High / Medium / Low]

## ADDED

### REQ-NEW-001: [New Requirement Title]
```
WHEN [event], the [system] SHALL [response].
```
**Rationale:** [Why this is being added]
**Files to create:**
- [ ] [file path]

## MODIFIED

### REQ-XXX-002: [Existing Requirement Title]
**Previous:**
```
[Old EARS requirement]
```
**Updated:**
```
[New EARS requirement]
```
**Rationale:** [Why this is changing]
**Files to update:**
- [ ] [file path]

## REMOVED

### REQ-XXX-003: [Deprecated Requirement Title]
**Reason:** [Why this is being removed]
**Files to delete:**
- [ ] [file path]

## Impact Analysis

### Files Affected
- [file path]: [Nature of change]

### Tests to Update
- [test path]: [What needs to change]

### Migration Notes
[Instructions for migrating existing data/state]

## Verification

- [ ] All ADDED requirements have tests
- [ ] All MODIFIED requirements have updated tests
- [ ] All REMOVED requirements have tests removed
- [ ] Traceability matrix updated
- [ ] Backward compatibility maintained (or explicitly broken with migration path)
```

## Rules

1. **One delta spec per change** — Each logical change gets its own CHANGE-NNN document.
2. **Reference original PRD** — Every delta spec links to the PRD it modifies.
3. **Preserve history** — MODIFIED sections show both before and after.
4. **Explain removals** — REMOVED sections require a reason.
5. **Update traceability** — Delta specs modify the traceability matrix.

## Storage Convention

- **Location:** `storage/changes/CHANGE-NNN.md`
- **Index:** Add entry to `storage/changes/index.md`
- **Task reference:** Link from `backbone/3-TASKS.md`:
  ```markdown
  - [ ] change: Add 2FA (Delta: storage/changes/CHANGE-001.md)
  ```

## Review Checklist

Before applying a delta spec:
- [ ] Impact analysis identifies all affected files
- [ ] Tests are updated for MODIFIED requirements
- [ ] Tests are removed for REMOVED requirements
- [ ] Backward compatibility is maintained or migration path documented
- [ ] Traceability matrix reflects all changes
