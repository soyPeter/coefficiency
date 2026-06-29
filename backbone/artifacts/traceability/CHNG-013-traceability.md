# Traceability — CHNG-013: Javalin Parity Phase 6 — Hook Extraction

## Implementation Summary

Ported 7 shared business-logic hooks from the Javalin frontend to coeff's `frontend/src/hooks/` directory. Each hook was copied verbatim from the Javalin source with import path adjustments to match coeff's project structure. Created a barrel export (`index.ts`) for clean imports from `@/hooks`.

Key adaptations:
- `useFiscalConfig.ts`: Added `IrpfBracket` and `SsCategory` interface definitions inline (these types don't exist in coeff's `types.ts`; per ADR-013-001, types are exported from hooks files).
- `useBackups.ts` and `useDumpBackups.ts`: Use `BackupFile` interface defined in `useBackups.ts` matching coeff's API shape (`filename` field instead of Javalin's `name`). `useDumpBackups.ts` imports `BackupFile` from `./useBackups`.
- All API-dependent hooks accept `authFetch` as a function parameter (per ADR-013-002), keeping them testable with mock fetch functions.

## File Map

| REQ-ID | Files | Status |
|--------|-------|--------|
| REQ-HOOK-COEFCONFIG-001 | `services/coeff/frontend/src/hooks/useCoefConfig.ts` | Added |
| REQ-HOOK-FISCONFIG-001 | `services/coeff/frontend/src/hooks/useFiscalConfig.ts` | Added |
| REQ-HOOK-CONCEPTS-001 | `services/coeff/frontend/src/hooks/useConcepts.ts` | Added |
| REQ-HOOK-BACKUPS-001 | `services/coeff/frontend/src/hooks/useBackups.ts` | Added |
| REQ-HOOK-DUMPBACKUPS-001 | `services/coeff/frontend/src/hooks/useDumpBackups.ts` | Added |
| REQ-HOOK-PASSWORDFORM-001 | `services/coeff/frontend/src/hooks/usePasswordForm.ts` | Added |
| REQ-HOOK-CSVEXPORT-001 | `services/coeff/frontend/src/hooks/useCsvExport.ts` | Added |
| — | `services/coeff/frontend/src/hooks/index.ts` | Added (barrel export) |

## Files Created

| File | Description |
|------|-------------|
| `services/coeff/frontend/src/hooks/index.ts` | Barrel export re-exporting all 7 hooks and their types |
| `services/coeff/frontend/src/hooks/useCoefConfig.ts` | COEF engine parameters hook (loads from `/api/fiscal`, exposes `load`/`setPartial`/`setParam`/`flashSaved`) |
| `services/coeff/frontend/src/hooks/useFiscalConfig.ts` | Fiscal parameters hook (IRPF brackets, SS config, deductions; loads from `/api/fiscal`) |
| `services/coeff/frontend/src/hooks/useConcepts.ts` | Pure state hook managing Concept[] array and ConceptDraft form |
| `services/coeff/frontend/src/hooks/useBackups.ts` | Encrypted backup lifecycle hook (list, create with i18n messages) |
| `services/coeff/frontend/src/hooks/useDumpBackups.ts` | SQL dump backup lifecycle hook (create, restore, upload with dialog state) |
| `services/coeff/frontend/src/hooks/usePasswordForm.ts` | Pure state hook for password change form fields |
| `services/coeff/frontend/src/hooks/useCsvExport.ts` | Stateless CSV export utilities (BOM, semicolon delimiter) |

## Test Files

No test files — frontend has no test infrastructure (no Jest/Vitest/RTL in dependencies). Verified via build.

## Verification Results

- TypeScript: `tsc --noEmit` — SUCCESS (no errors)
- Vite build: `vite build` — SUCCESS (2553 modules, 9.08s)
