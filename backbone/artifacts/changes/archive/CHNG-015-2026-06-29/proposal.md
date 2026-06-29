# CHNG-015: Javalin Parity Phase 8 — Backend Polish

## Overview
Address minor backend gaps between coeff (Jooby-based) and Javalin: dedicated fiscal endpoints, backup upload endpoints, PaginationHelper, default DB seeding, OpenAPI/Swagger wiring, and SetupWizardPage frontend.

## EARS Requirements

### REQ-FISCAL-001 (Ubiquitous)
Coeff SHALL expose dedicated `/api/fiscal/{key}` GET/PUT endpoints for individual fiscal settings, matching Javalin's `FiscalController`.

### REQ-BACKUP-UPLOAD-001 (Ubiquitous)
Coeff's AdminController SHALL expose `POST /api/admin/backups/restore-upload` and `POST /api/admin/backups/dump/restore-upload` endpoints matching Javalin's `AdminController`.

### REQ-PAGINATION-001 (Ubiquitous)
Coeff SHALL provide a `PaginationHelper.paginate()` utility returning `{ data, meta: { total, offset, limit } }` identical to Javalin's implementation.

### REQ-SEEDING-001 (Ubiquitous)
Coeff SHALL run default DB seeding on first startup (no user exists): insert default settings, cost concepts, and default IRPF brackets matching Javalin's schema initialization.

### REQ-OPENAPI-001 (Ubiquitous)
Coeff SHALL wire OpenAPI/Swagger UI at `/openapi.json` and `/swagger` using Jooby's OpenAPI plugin, matching Javalin's SwaggerPlugin/ReDocPlugin setup.

### REQ-SETUPWIZARD-001 (Ubiquitous)
Coeff SHALL port Javalin's `SetupWizardPage` as a frontend page that guides first-time users through account creation and initial config.

## Scope
- **In scope:** FiscalController, AdminController additions, PaginationHelper, DB seeding, OpenAPI config, SetupWizardPage.
- **Out of scope:** Non-admin endpoints, complex refactoring, test coverage (separate task).

- **REQ-ARCHIVE:** Completed and archived.
- **REQ-CLOSE-001**: All tasks completed and change archived.
