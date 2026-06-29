# CHNG-015: Backend Polish — Design

## Architecture

### Fiscal Endpoints (REQ-FISCAL-001)
Create `FiscalController.java` in coeff's `simulator` package (mirrors Javalin's `config/infra/rest/FiscalController.java`). Use Jooby annotations: `@GET @Path("/api/fiscal")`, `@GET @Path("/api/fiscal/{key}")`, `@PUT @Path("/api/fiscal/{key}")`. Delegate to `SettingsController` for storage.

### Backup Upload Endpoints (REQ-BACKUP-UPLOAD-001)
Add two methods to coeff's `AdminController`:
- `POST /api/admin/backups/restore-upload` — multipart upload, calls `adminService.restoreFromUpload(uploadedFile)`
- `POST /api/admin/backups/dump/restore-upload` — multipart with `password` field, calls `adminService.restoreDumpFromUpload(uploadedFile, password)`

### PaginationHelper (REQ-PAGINATION-001)
Create `PaginationHelper.java` in `shared/util/`. Static method `paginate(List, offset, limit)` returns `Map.of("data", ..., "meta", Map.of("total", ..., "offset", ..., "limit", ...))`.

### DB Seeding (REQ-SEEDING-001)
Add a `seedIfEmpty()` call in `CoeffApplication` or `AdminService` that:
1. Check if any user exists
2. If no user, insert default settings (delta_annual=12, auto_logout_timeout=15, fiscal.* defaults)
3. Insert default cost concepts (mealCard, training, laptop, healthInsurance, etc.)
4. Insert default IRPF brackets and SS contribution bases
5. Insert default workingDays array (21 per month)

### OpenAPI/Swagger (REQ-OPENAPI-001)
Add Jooby's `SwaggerModule` or `OpenAPIModule` to `CoeffApplication`. Configure with title "Consultant COEF Calculator", version "1.0.0". Mount at `/openapi.json` and `/swagger`.

### SetupWizardPage (REQ-SETUPWIZARD-001)
Port Javalin's `SetupWizardPage` (React component) to coeff's `frontend/src/pages/`. Routes: `/setup` → SetupWizardPage. Uses `useState` for multi-step: Welcome → Account → Config → Done.

## Decisions

### ADR-015-001: Fiscal endpoints re-use SettingsController
- **Decision:** `FiscalController` delegates to the existing `SettingsController` rather than duplicating storage logic.
- **Rationale:** `SettingsController` already handles `fiscal.*` key CRUD. A separate controller is just a routing layer — thin delegation is appropriate.
- **Type:** Two-way door.

### ADR-015-002: DB seeding in CoeffConfig vs separate seeder
- **Decision:** Add `seedIfEmpty()` to `CoeffConfig.java` (called during app startup).
- **Rationale:** CoeffConfig already handles app initialization. Adding a seeding step there avoids a new class file for what amounts to 30 lines of SQL.
- **Type:** Two-way door.

### ADR-015-003: SetupWizard as standalone page
- **Decision:** Port SetupWizardPage as a standalone page at route `/setup`, not as a modal or overlay.
- **Rationale:** Matches Javalin's UX — first-time setup is a full-page wizard that transitions to the dashboard on completion.
- **Type:** Two-way door.

## Traceability
| REQ-ID | File | Element |
|--------|------|---------|
| REQ-FISCAL-001 | simulator/FiscalController.java | GET/PUT /api/fiscal/{key} |
| REQ-BACKUP-UPLOAD-001 | admin/infra/rest/AdminController.java | restore-upload endpoints |
| REQ-PAGINATION-001 | shared/util/PaginationHelper.java | paginate() |
| REQ-SEEDING-001 | CoeffConfig.java | seedIfEmpty() |
| REQ-OPENAPI-001 | CoeffApplication.java | SwaggerModule |
| REQ-SETUPWIZARD-001 | frontend/src/pages/SetupWizardPage.tsx | Setup wizard UI |
