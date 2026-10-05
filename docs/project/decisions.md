<!-- VERSION: 2026.05.13#5-commandpipeline,16commandstotal -->
# 5. Decision Log

*This file tracks the "why" behind major technical and architectural decisions. It is the learning log.*

## D-008: Class-based JDBI repo with binding helper instead of `@RegisterConstructorMapper` + `@BindBean`

**Context:** `ConsultantSqlCommandRepo` was a JDBI SQL Object interface using `@BindBean Consultant` for `save()`/`update()`. After refactoring `Consultant` to use typed value objects (records), `@BindBean` could no longer bind `Coef`/`Tariff` etc. to SQL `double` columns.

**Decision:** Converted `ConsultantSqlCommandRepo` from a `@RegisterConstructorMapper` interface to a class that takes `Jdbi` directly. Created `ConsultantBindings` to flatten typed VOs to raw `double` values in a `Map<String, Object>`. Switched `CoefJdbiFactory` from `jdbi.onDemand(...)` to `new ConsultantSqlCommandRepo(jdbi)`. Registered `ConstructorMapper.of(ConsultantRow.class)` globally on the shared `Jdbi` bean.

**Why:** Keeps persistence explicit and debuggable without JDBI framework magic. Avoids registering a global argument factory for value types (which would add framework coupling). The `ConsultantRow` mapper registration is needed because `SqliteConsultantQueryRepo` and `ConsultantController.getById()` also use `mapTo(ConsultantRow.class)`.

---

## Decision D-009: Tests written per value object (44 new tests)

**Context:** Mode is `full` (TDD required). No existing tests for value objects or Consultant domain.

**Decision:** Wrote 44 new tests across 8 test classes covering all value object validation, equality, and Consultant factory methods.

**Why:** Ensures REQ-VO-* and REQ-CONSULTANT-* requirements are verifiable. Catches regression if validation logic changes.

---

## Decision D-010: Bonus Breakdown — frontend-only integration (no backend changes)

**Context:** Backend controller (`BonusBreakdownController`), cache service (`BonusBreakdownCacheService`), and DB table (`bonus_breakdown_cache`) already exist from earlier platform tasks (CHNG-008 and initial Phase 3 Bonus System work). The Javalin reference app shows a per-month bonus breakdown UI that needs to be replicated on the coefficiency frontend.

**Decision:** No backend changes. Added `BonusBreakdownRow` TypeScript interface, `fetchBonusBreakdown`/`refreshBonusBreakdown` API functions, and bonus breakdown card with KPI cards, year filter, refresh button, and detail table to `BillingSummaryPage`. Derive `availableYears` from `monthly` data via `useMemo` instead of adding a separate years endpoint. Use `undefined` year sentinel to pass no `?year=` param for "all years" mode. Added 500ms delay after refresh before refetching as a pragmatic heuristic for async rebuild persistence.

**Why:** Backend is complete; the only gap was frontend integration. Adding a separate years endpoint or polling mechanism would add complexity with no benefit. The existing `request<T>` helper and `useMemo` patterns match the rest of the codebase.

---

## Decision D-011: M6 suggestion fixes (input validation, defaults reconciliation, magic-string extraction, i18n)

**Context:** Four M6 Code Review Remediation suggestions remained open: input validation for simulator concept parameters, reconciling hardcoded defaults against application.conf, extracting repeated map-key strings into named constants, and standardizing i18n keys to English.

**Decision:** (1) Added `validateInput()` in `SimulatorController` with non-negative bounds checks on all numeric parameters, throwing `BadRequestException` on violation. (2) Added missing `fiscal.report_target_revenue` and `fiscal.report_target_margin` seed entries in `CoeffConfig` (the only hardcoded defaults not already seeded). (3) Extracted repeated map-key literals (`"month"`, `"hires"`, `"terminations"`, `"fees"`, `"margin"`, `"avgCoefPct"`, etc.) and settings-key literals (`"fiscal.coefDaysMonth"`, `"fiscal.tenure_bonus_amount"`, etc.) into private static final constants in `BillingService` and `ReportService`. (4) Renamed Spanish-origin i18n keys (`menu.principal` → `menu.main`, `simulator.guardado` → `simulator.saved`, etc.) in both `en.ts` and `es.ts`, and replaced hardcoded English label strings in `SimulatorPage.tsx` and `ReportsPage.tsx` with `<FormattedMessage>` using existing i18n keys.

**Why:** Input validation prevents downstream errors from malformed simulator requests. Seeding missing defaults ensures programmatic defaults match the seeded database values. Named constants reduce maintenance burden when API map-key contracts change and prevent typos. English-only i18n keys match the project's Universal Naming Convention (EN-only identifiers in 4-KNOWLEDGE.md).

---

## Decision D-012: All schema changes go through Flyway

**Context:** The project historically managed schema via inline JDBC DDL in `SqliteConnection.initSchema()` with ad-hoc ALTER TABLE migration statements. This made schema versioning, auditing, and cross-environment reproducibility difficult. When importing Javalin-format dumps, schema mismatches caused crashes (missing columns, missing views). Flyway was introduced via `jooby-flyway` with `baselineOnMigrate(true)` to handle both fresh databases and dump restores.

**Decision:** From now on, every schema change (new tables, columns, indexes, views, ALTER TABLE) MUST be a Flyway migration (`V{number}__{description}.sql` in `src/main/resources/db/migration/`). The inline `initSchema()` DDL fallbacks and `AdminService.migrateSchema()` are legacy compatibility only — they are NOT for new schema changes. New schema = new Flyway migration.

**Why:** Flyway provides versioned, auditable, reproducible schema management. Migration files are the single source of truth. The legacy fallbacks caused silent failures (ALTER TABLE with `NOT NULL DEFAULT` on populated tables, duplicate column errors) that Flyway migrations avoid.

**Key constraints (SQLite-specific):**
- `ALTER TABLE ADD COLUMN` only accepts constant defaults — no `DEFAULT (datetime('now'))`. Use `TEXT` without default and let application code fill nulls, or ensure the column exists in the initial `CREATE TABLE` if a function default is needed.
- Always use `CREATE ... IF NOT EXISTS` for idempotency.
- Test migrations against both fresh DBs and restored dumps.

---

## Decision Index

- D-008: Class-based JDBI repo with binding helper instead of `@RegisterConstructorMapper` + `@BindBean`
- D-009: Tests written per value object (44 new tests)
- D-010: Bonus Breakdown — frontend-only integration (no backend changes)
- D-011: Input validation, i18n key standardization, and magic-string extraction (M6 suggestions)
- D-012: All schema changes go through Flyway

