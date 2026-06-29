# CHNG-013: Javalin Parity Phase 6 — Hook Extraction

## Overview
Extract 7 shared business-logic hooks from the Javalin frontend into the coeff frontend. These hooks encapsulate reusable state management patterns (config loading, CRUD forms, backup workflows, CSV export) that coeff currently duplicates across pages.

## EARS Requirements

### REQ-HOOK-COEFCONFIG-001 (Ubiquitous)
`useCoefConfig` SHALL load COEF engine parameters (workingDays, coefDaysMonth, coefDaysYear, multipliers, thresholds) from `/api/fiscal` on mount and expose `load`, `setPartial`, `setParam`, `flashSaved`.

### REQ-HOOK-FISCONFIG-001 (Ubiquitous)
`useFiscalConfig` SHALL load fiscal parameters (IRPF brackets, SS config, deductions) from `/api/fiscal` on mount and expose `load`, `setPartial`, `setParam`, `flashSaved`.

### REQ-HOOK-CONCEPTS-001 (Ubiquitous)
`useConcepts` SHALL manage an array of `Concept` objects and a `ConceptDraft` form with `setDraftName/Type/Value` setters and `resetDraft`.

### REQ-HOOK-BACKUPS-001 (Ubiquitous)
`useBackups` SHALL list encrypted backups from `/api/admin/backups` on mount and expose `backups`, `message`, `loading`, `create`, `reload`.

### REQ-HOOK-DUMPBACKUPS-001 (Ubiquitous)
`useDumpBackups` SHALL manage password-protected dump backup lifecycle (create, restore, upload) with full dialog state (password fields, messages, file picker).

### REQ-HOOK-PASSWORDFORM-001 (Ubiquitous)
`usePasswordForm` SHALL manage password change form state: current/new/confirm password fields with `clear` and `setMessage`.

### REQ-HOOK-CSVEXPORT-001 (Ubiquitous)
`useCsvExport` SHALL provide `downloadCsv(filename, rows, columns)` and `downloadMultiSectionCsv(filename, sections)` utilities for CSV export with BOM and semicolon delimiter.

## Scope
- **In scope:** 7 new hook files in `frontend/src/hooks/`, types for Concept/ConceptDraft/BackupFile, exports from hooks index.
- **Out of scope:** Page refactoring to use the new hooks (separate task).

- **REQ-ARCHIVE:** Completed and archived.
- **REQ-CLOSE-001**: All tasks completed and change archived.
