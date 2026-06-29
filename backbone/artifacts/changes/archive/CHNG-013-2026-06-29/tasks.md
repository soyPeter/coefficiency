# CHNG-013: Tasks

## Task List

### [S] T-001: Create hooks directory export file
Create `frontend/src/hooks/index.ts` that re-exports all 7 hooks for clean imports.
- **Verification:** `import { useCoefConfig } from '@/hooks'` resolves.

### [S] T-002: Port useCoefConfig hook
Copy javalin's `useCoefConfig.ts` to coeff's `hooks/`. Adjust import paths. Verify `CoefConfig` interface, `load`, `setPartial`, `setParam`, `flashSaved` are exported.
- **Source:** javalin `hooks/useCoefConfig.ts`
- **Verification:** TypeScript compiles, hook loads from `/api/fiscal`.

### [S] T-003: Port useFiscalConfig hook
Copy javalin's `useFiscalConfig.ts`. Adjust imports. Verify `FiscalConfig`, brackets, ssConfig, params are managed.
- **Source:** javalin `hooks/useFiscalConfig.ts`
- **Verification:** TypeScript compiles, default values match javalin.

### [XS] T-004: Port useConcepts hook
Copy javalin's `useConcepts.ts`. Adjust imports. This is a pure state hook with no API calls.
- **Source:** javalin `hooks/useConcepts.ts`
- **Verification:** State updates propagate correctly.

### [S] T-005: Port useBackups hook
Copy javalin's `useBackups.ts`. Adjust imports. Verify `create` calls POST `/api/admin/backup` and `reload` calls GET `/api/admin/backups`.
- **Source:** javalin `hooks/useBackups.ts`
- **Verification:** Backup creation flow works, messages display.

### [M] T-006: Port useDumpBackups hook
Copy javalin's `useDumpBackups.ts`. This is the largest hook (215 lines). Adjust imports. Verify all dialog states, create/restore/upload flows.
- **Source:** javalin `hooks/useDumpBackups.ts`
- **Verification:** Dump restore flow, file upload dialog, error messages all functional.

### [XS] T-007: Port usePasswordForm hook
Copy javalin's `usePasswordForm.ts`. Pure state hook.
- **Source:** javalin `hooks/usePasswordForm.ts`
- **Verification:** State setters work, `clear` resets all fields.

### [XS] T-008: Port useCsvExport utilities
Copy javalin's `useCsvExport.ts`. Stateless utility functions. No adjustments needed.
- **Source:** javalin `hooks/useCsvExport.ts`
- **Verification:** `downloadCsv` and `downloadMultiSectionCsv` produce valid CSV.
