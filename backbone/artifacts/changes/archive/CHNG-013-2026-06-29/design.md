# CHNG-013: Hook Extraction — Design

## Architecture
Each hook is a self-contained `.ts` file under `frontend/src/hooks/`. Hooks depend only on React primitives (`useState`, `useCallback`, `useEffect`) and optionally `react-intl`. No external state management.

## API Dependencies
Hooks use `authFetch` pattern: a caller-provided function matching `(url: string, options?: RequestInit) => Promise<Response>`. This keeps hooks testable and avoids coupling to `api.ts`.

## Porting Strategy
For each Javalin hook:
1. Copy the hook file → coeff's `frontend/src/hooks/` directory
2. Adjust import paths (e.g., `@/types` → `@/types`)
3. Keep `authFetch` signature identical (coeff's `request<T>` already returns parsed JSON — hooks call `authFetch(...).then(r => r.json())`)
4. No behavioral changes

## Hook Details

| Hook | State | API Calls | Key Interfaces |
|------|-------|-----------|----------------|
| `useCoefConfig` | workingDays, coefDaysMonth, multipliers, thresholds | GET `/api/fiscal` | `CoefConfig`, `UseCoefConfigResult` |
| `useFiscalConfig` | brackets, regionalBrackets, ssConfig, params | GET `/api/fiscal` | `FiscalConfig`, `UseFiscalConfigResult` |
| `useConcepts` | concepts[], draft (name/type/value) | None (state only) | `Concept`, `ConceptDraft`, `UseConceptsResult` |
| `useBackups` | backups[], message, loading | GET `/api/admin/backups`, POST `/api/admin/backup` | `UseBackupsResult` |
| `useDumpBackups` | dumpBackups[], 4 dialog+form states | POST `/api/admin/backup-dump`, POST `/api/admin/backups/dump/.../restore` | `UseDumpBackupsResult` |
| `usePasswordForm` | currentPassword, newPassword, confirmPassword, message | None (state only) | `UsePasswordFormResult` |
| `useCsvExport` | Stateless (pure functions) | None | — |

## Decisions

### ADR-013-001: Import types from `@/types` vs inline
- **Decision:** Export `BackupFile`, `Concept`, `ConceptDraft` interfaces from hooks files. The `BackupFile` type already exists in `api.ts` — deduplicate by importing from hooks.
- **Rationale:** Keeps hooks self-contained. Pages can import types directly from hooks.
- **Type:** Two-way door.

### ADR-013-002: authFetch parameter vs direct API import
- **Decision:** Hooks accept `authFetch` as a parameter.
- **Rationale:** Dependency injection pattern — keeps hooks testable with mock fetch functions. Matches Javalin's approach exactly.
- **Type:** Two-way door.

## Traceability
| REQ-ID | File | Element |
|--------|------|---------|
| REQ-HOOK-COEFCONFIG-001 | hooks/useCoefConfig.ts | useCoefConfig hook |
| REQ-HOOK-FISCONFIG-001 | hooks/useFiscalConfig.ts | useFiscalConfig hook |
| REQ-HOOK-CONCEPTS-001 | hooks/useConcepts.ts | useConcepts hook |
| REQ-HOOK-BACKUPS-001 | hooks/useBackups.ts | useBackups hook |
| REQ-HOOK-DUMPBACKUPS-001 | hooks/useDumpBackups.ts | useDumpBackups hook |
| REQ-HOOK-PASSWORDFORM-001 | hooks/usePasswordForm.ts | usePasswordForm hook |
| REQ-HOOK-CSVEXPORT-001 | hooks/useCsvExport.ts | useCsvExport utilities |
