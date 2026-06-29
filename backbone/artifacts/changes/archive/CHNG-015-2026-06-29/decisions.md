# CHNG-015: Decisions Log

## ADR-015-001: Fiscal endpoints re-use SettingsController
| Field | Value |
|-------|-------|
| **Decision** | FiscalController delegates to SettingsController for storage |
| **Rationale** | SettingsController already handles `fiscal.*` key CRUD. FiscalController is just a routing layer — thin delegation is correct. |
| **Type** | Two-way door |
| **Date** | 2026-06-22 |

## ADR-015-002: DB seeding in CoeffConfig
| Field | Value |
|-------|-------|
| **Decision** | Add `seedIfEmpty()` to CoeffConfig.java (existing initialization class) |
| **Rationale** | CoeffConfig already handles app initialization. Adding seeding there avoids a new class for ~30 lines of SQL. |
| **Type** | Two-way door |
| **Date** | 2026-06-22 |

## ADR-015-003: SetupWizard as standalone page
| Field | Value |
|-------|-------|
| **Decision** | Port SetupWizardPage as route `/setup`, not a modal |
| **Rationale** | Matches Javalin UX — full-page wizard that transitions to dashboard on completion. |
| **Type** | Two-way door |
| **Date** | 2026-06-22 |

## ADR-015-004: OpenAPI via Jooby SwaggerModule
| Field | Value |
|-------|-------|
| **Decision** | Use Jooby's built-in SwaggerModule for OpenAPI generation |
| **Rationale** | Jooby has first-class OpenAPI support via annotations. No need for a separate library. Matches Javalin's approach (Javalin OpenAPI plugin). |
| **Type** | Two-way door |
| **Date** | 2026-06-22 |
