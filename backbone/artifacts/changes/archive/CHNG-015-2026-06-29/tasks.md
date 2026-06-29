# CHNG-015: Backend Polish — Tasks

## Task List

### [x] [S] T-001: Create FiscalController with GET/PUT /api/fiscal/{key}
Create `FiscalController.java` in `simulator/` package. Inject `Jdbi`. Annotate with `@Singleton @Path("/api")`. Implement: `allFiscal()` (GET `/fiscal`), `getFiscal(key)` (GET `/fiscal/{key}`), `upsertFiscal(key, body)` (PUT `/fiscal/{key}`), `workingDays()` (GET `/fiscal/working-days`), `upsertWorkingDays(body)` (PUT `/fiscal/working-days`).
- **File:** `services/coeff/src/main/java/io/bitnomio/coeff/simulator/FiscalController.java`
- **Verification:** `curl http://localhost:62226/api/fiscal/coefDaysMonth` returns a value.

### [x] [S] T-002: Register FiscalController in CoeffApplication
Add `mvc(new io.bitnomio.coeff.simulator.FiscalController_());` to CoeffApplication.
- **File:** CoeffApplication.java
- **Verification:** Build succeeds, /api/fiscal routes respond.

### [x] [S] T-003: Add backup upload endpoints to AdminController
Add two methods: `restoreUpload(Context)` handling multipart file upload, and `restoreDumpUpload(Context)` handling file + password. Use `uploadedFile("file")` (Jooby) / `formParams` for multipart.
- **File:** AdminController.java
- **Verification:** `curl -F "file=@backup.enc" http://localhost:62226/api/admin/backups/restore-upload` returns 200.

### [x] [XS] T-004: Create PaginationHelper utility
Create `PaginationHelper.java` in `shared/util/` with static `paginate(List, int offset, int limit)`.
- **File:** `shared/util/PaginationHelper.java`
- **Verification:** Unit test passes: `paginate([a,b,c], 0, 2) → {data: [a,b], meta: {total: 3, offset: 0, limit: 2}}`.

### [x] [M] T-005: Add default DB seeding to CoeffConfig
Add `seedIfEmpty()` method checking `SELECT COUNT(*) FROM users`. If 0, insert: default settings (delta_annual=12, auto_logout_timeout=15), fiscal defaults (coefDaysMonth=21, coefMultiplier=1.7, mngBonusPct=0.05, etc.), default concepts (meal card, training, laptop, health insurance), IRPF brackets, SS bases, workingDays array.
- **File:** CoeffConfig.java
- **Verification:** Fresh database has default settings after first startup.

### [x] [S] T-006: Wire OpenAPI/Swagger plugin
Add Jooby's SwaggerModule to CoeffApplication. Configure info (title, version, description). Set documentation path to `/openapi.json`, UI path to `/swagger`.
- **File:** CoeffApplication.java
- **Verification:** `http://localhost:62226/openapi.json` returns OpenAPI spec. `/swagger` shows Swagger UI.

### [x] [M] T-007: Port SetupWizardPage frontend
Create `SetupWizardPage.tsx` in `frontend/src/pages/`. Multi-step wizard: Welcome (language select, "Get Started"), Account (username/password/confirm, "Continue"), Config (delta target, auto-logout, "Finish Setup"), Done (5 choices: Import CSV, Restore Backup, Go to Dashboard). Add route `/setup` that redirects to `/` if setup is complete.
- **Files:** SetupWizardPage.tsx, App.tsx (routing)
- **Verification:** Wizard completes and redirects to dashboard.

### [x] [S] T-008: Add i18n keys for admin/report sections (if missing)
Verify all keys required by new endpoints/UI exist in en.ts/es.ts. Keys needed: `config.fiscalTab`, `config.backupRestoreUpload`, `setupWizard.*`, admin-related route keys.
- **Files:** en.ts, es.ts
- **Verification:** No missing key warnings from react-intl.
