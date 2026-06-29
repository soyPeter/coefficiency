---
description: Quality management — register NCR, compact stale entries
required-skills:
  - cross-cutting/qms/qms-iso9001
  - general/coding-standards
  - general/spec-driven-development
---

Quality Management System operations: $ARGUMENTS

Usage:
- Register a nonconformance: `./scripts/qms-register-issue.sh --title "..." --severity major --category code`
- Compact stale entries: scan `5-DECISIONS.md` and `6-MEMORY.md` for outdated entries

Loaded skills give context for root cause analysis, coding standards, and SDD when planning CAPAs.

Disabled if `backbone/.MODE` is `light`.
