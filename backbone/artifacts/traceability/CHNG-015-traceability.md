# Traceability — CHNG-015: Javalin Parity Phase 8 — Backend Polish

## Implementation Summary

Implemented 8 backend polish tasks: FiscalController with dedicated fiscal endpoints, backup upload endpoints in AdminController, PaginationHelper utility, default DB seeding on first startup, OpenAPI/Swagger plugin wiring, SetupWizardPage frontend, and i18n key additions.

## File Map

| REQ-ID | Files | Status |
|--------|-------|--------|
| REQ-FISCAL-001 | `services/coeff/src/main/java/io/bitnomio/coeff/simulator/FiscalController.java` | Created — thin routing layer delegating to SettingsController |
| REQ-FISCAL-001 | `services/coeff/src/main/java/io/bitnomio/coeff/CoeffApplication.java` | Modified — registered FiscalController MVC |
| REQ-BACKUP-UPLOAD-001 | `services/coeff/src/main/java/io/bitnomio/coeff/admin/infra/rest/AdminController.java` | Modified — added `restoreUpload()` and `restoreDumpUpload()` endpoints |
| REQ-BACKUP-UPLOAD-001 | `services/coeff/src/main/java/io/bitnomio/coeff/admin/app/AdminService.java` | Modified — added `restoreFromUpload()` and `restoreDumpFromUpload()` methods |
| REQ-PAGINATION-001 | `services/coeff/src/main/java/io/bitnomio/coeff/shared/util/PaginationHelper.java` | Created — static `paginate()` with null-safe and bounds-clamping |
| REQ-PAGINATION-001 | `services/coeff/src/test/java/io/bitnomio/coeff/shared/util/PaginationHelperTest.java` | Created — 7 unit tests covering all edge cases |
| REQ-SEEDING-001 | `services/coeff/src/main/java/io/bitnomio/coeff/CoeffConfig.java` | Modified — added `seedIfEmpty()` with 19 default settings, 8 cost concepts |
| REQ-OPENAPI-001 | `services/coeff/src/main/java/io/bitnomio/coeff/CoeffApplication.java` | Modified — installed `OpenAPIModule` with `/swagger` and `/redoc` UIs |
| REQ-SETUPWIZARD-001 | `services/coeff/frontend/src/pages/SetupWizardPage.tsx` | Created — 4-step wizard (welcome → account → config → done) |
| REQ-SETUPWIZARD-001 | `services/coeff/frontend/src/App.tsx` | Modified — added `/setup` route with HashRouter for unauthenticated state |
| REQ-SETUPWIZARD-001 | `services/coeff/frontend/src/i18n/en.ts` | Modified — added `common.back` key |
| REQ-SETUPWIZARD-001 | `services/coeff/frontend/src/i18n/es.ts` | Modified — added `common.back` key |
| — | `services/coeff/frontend/src/i18n/en.ts` | Modified — added `config.backupRestoreUpload` key |
| — | `services/coeff/frontend/src/i18n/es.ts` | Modified — added `config.backupRestoreUpload` key |

## Verification

- **Backend compile:** `./gradlew :services:coeff:compileJava` — PASS
- **Backend tests:** `./gradlew :services:coeff:test` — All 27 tests PASS (7 new PaginationHelper tests + 20 existing)
- **Frontend compile:** `npx tsc --noEmit` — PASS (0 errors)
