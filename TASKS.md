# Tasks & Milestones

*The project's task logbook. Open work is the unchecked items under **Active Milestones**; the rest is history.*
*Mark a task `[WIP]` when you start it and `[x]` when it's done. Don't start a task already marked `[WIP]` without asking.*

---

## Project Progression Summary

| Milestone | Status | Progress | Description |
|-----------|--------|----------|-------------|
| **M1: Project Bootstrap** | [x] | 100% | Completed by generator during `init-project.sh` |
| **M2: Core Platform** | [x] | 100% | Jooby/SQLite backend, React SPA shell, i18n |
| **M3: Security** | [x] | 100% | Auth, HMAC tokens, AES-256-GCM DB encryption |
| **M4: Consultant Management** | [x] | 100% | CRUD, billing, clients, CSV import |
| **M5: COEF Simulator** | [x] | 100% | Tax engine (IRPF+SS), COEF calc, fiscal config |
| **M6: Code Review Remediation** | [ ] | 85% | 8/10 warnings, 6/8 suggestions, 91 tests total, BCrypt, CORS, i18n parity |
| **M7: Javalin Feature Parity** | [x] | 100% | 8 phases: typed VOs, MoM billing, bonus breakdown UI, frontend extraction, forecast/YoY, hooks extraction, i18n parity, backend polish |
| **M8: Flyway Schema Management** | [x] | 100% | Replace inline initSchema() DDL with Flyway migrations for versioned schema management |

---

## Active Milestones

### M6: Code Review Remediation
*Fix review findings: 5 blockers, 10 warnings, 8 suggestions, zero tests. See REVIEW.md.*

#### Blockers (MUST FIX)

- [x] [M] fix: align auth token algorithm between generator and decoder in AuthController.java
- [x] [M] fix: resolve JDBI column-mapping mismatch for findById queries in SqliteAuthRepository
- [x] [M] fix: implement ignored sort/search/order params in list endpoints across BillingService
- [x] [S] fix: add proper CSV parsing with quote escaping in FileImportController
- [x] [S] fix: align INSERT/UPDATE column order with SELECT positional binding across JDBI repos

#### Warnings (SHOULD FIX)

- [x] [S] fix: replace hardcoded HMAC secret with config-driven value in AuthService
- [x] [S] fix: remove dead ExceptionMapper or wire it into Jooby error handling
- [x] [S] fix: replace misleading @RegisterConstructorMapper with row mapper in JDBI repos
- [ ] [S] refactor: move Jdbi injection from controllers into service layer (auth, billing, client)
- [ ] [S] refactor: unify controller package locations under infra/io/rest/
- [x] [XS] fix: reuse shared ObjectMapper instance instead of creating per-call
- [x] [S] feat: add file upload validation (type, size, content) in FileImportController
- [x] [XS] fix: enforce reasonable minimum password length (8+ chars) in AuthService
- [x] [S] fix: distinguish 503 service-unavailable from auth failure in frontend api.ts
- [x] [XS] fix: remove spurious @Inject annotations on no-arg constructors

#### Suggestions (CONSIDER)

- [x] [S] feat: add input validation for simulator concept parameters
- [x] [XS] fix: reconcile hardcoded defaults with application.conf values
- [x] [XS] fix: reuse SecureRandom instance instead of creating per-call
- [x] [XS] refactor: extract magic strings into named constants
- [x] [XS] fix: remove redundant exempt paths from AuthFilter
- [ ] [M] refactor: split oversized SimulatorPage (878 lines) into sub-components
- [ ] [M] refactor: split oversized useIdleTimer hook (387 lines) into smaller hooks
- [x] [XS] fix: standardize i18n keys to single language (English)

#### Architecture

- [ ] [M] refactor: apply DDD/Hexagonal layers to auth module (domain/app/infra separation)
- [ ] [M] refactor: apply DDD/Hexagonal layers to billing module
- [ ] [M] refactor: apply DDD/Hexagonal layers to client module
- [ ] [M] refactor: apply DDD/Hexagonal layers to simulator module
- [ ] [S] refactor: apply DDD/Hexagonal layers to doc and file-import modules

#### Phase 2: Enhanced COEF Simulator

- [x] [M] feat: expand TaxEngine with dual-bracket IRPF, family deductions, and category-based SS
- [x] [M] feat: expand SimulatorInput/Result with full 26-field model
- [ ] [S] feat: add simulations table and save/list/delete history endpoints
- [x] [S] feat: add PUT /api/consultants/{id}/coef endpoint to persist simulation results
- [x] [M] feat: expand SimulatorPage frontend with full input fields and real-time calc

#### Phase 3: Bonus System

- [x] [M] feat: add tenure_bonuses, quarterly_bonuses, bonus_breakdown_cache tables and services
- [x] [S] feat: add bonus breakdown API endpoints
- [x] [S] feat: integrate bonuses into BillingSummary
- [x] [M] feat: add bonus display to BillingSummaryPage frontend


- [x] [L] feat: port report service with 11 endpoints and peer benchmarking
- [x] [M] feat: create ReportController with all report endpoints

#### Phase 5: Admin Module

- [x] [M] feat: port admin module (backup/restore, health, prune, password change)

#### Phase 6: Security Hardening

- [x] [S] fix: migrate passwords to BCrypt with auto-migration from SHA-256
- [x] [XS] fix: restrict CORS to localhost origins

#### Phase 7: Tests & Polish

- [x] [M] test: add unit tests for TaxEngine and SimulatorService
- [x] [S] test: add unit tests for AuthService

#### Gap Closure — Phase 1: Backend Critical Fixes

- [x] [M] fix: replace monthly SQL GROUP BY with per-consultant per-month iteration in BillingService.monthly()
- [x] [M] feat: port BillingCalculator.isActiveInRange() to check consultant activity in a date range
- [x] [S] feat: compute manager bonus per month using Consultant.canEarnManagerBonus() in monthly breakdown
- [x] [S] feat: add tenure bonus counts and quarterly bonus amounts to each month in monthly breakdown
- [x] [S] feat: compute active tariff sums per month in monthly breakdown
- [x] [S] fix: add 2MB file size limit validation to FileImportController.upload()
- [x] [XS] fix: add .csv content-type validation to FileImportController.upload()
- [x] [S] fix: implement deduplication by name+client+startDate in FileImportController.upload()
- [x] [S] fix: replace raw Map return with typed ImportResult record in FileImportController
- [x] [XS] fix: add activeCount to billing summary Map in BillingService.summary()
- [x] [XS] fix: skip CSV header row in FileImportController.upload()

#### Gap Closure — Phase 2: ReportsPage Frontend

- [x] [S] feat: add fetchReportYears(), fetchReport(), fetchReportClients() to frontend api.ts
- [x] [S] feat: add fetchProfitability(), fetchTargets() to frontend api.ts
- [x] [S] feat: add fetchClientTimeline(), fetchRoleAggregation() to frontend api.ts
- [x] [S] feat: add fetchPerConsultant(), fetchForecast(), fetchYoy(), fetchBenchmarks() to frontend api.ts
- [x] [M] feat: add 15 report TypeScript interfaces to frontend types.ts
- [x] [L] feat: create ReportsPage.tsx with consultant roster, COEF analytics, billing summary sections
- [x] [S] feat: add profitability trends chart section to ReportsPage
- [x] [S] feat: add revenue vs targets radial chart section to ReportsPage
- [x] [M] feat: add per-consultant billing searchable table section to ReportsPage
- [x] [S] feat: add client timeline selector section to ReportsPage
- [x] [S] feat: add role aggregation with peer benchmarks section to ReportsPage
- [x] [S] feat: add year/date-range filter bar to ReportsPage
- [x] [XS] feat: add /reports route to app-routing.tsx
- [x] [XS] feat: add Reports nav item to sidebar component

#### Gap Closure — Phase 3: Admin UI in ConfigPage

- [x] [XS] feat: add current/new/confirm password form to ConfigPage delta tab
- [x] [S] feat: add create-backup button and backup list display to ConfigPage
- [x] [S] feat: add restore-backup from list functionality to ConfigPage
- [x] [S] feat: add create-dump-backup with password prompt to ConfigPage
- [x] [S] feat: add restore-dump-backup with password prompt to ConfigPage
- [x] [S] feat: add prune-database confirmation dialog to ConfigPage
- [x] [XS] feat: add backup fetch functions to frontend api.ts

#### Gap Closure — Phase 4: i18n Completeness

- [x] [S] fix: replace hardcoded English labels in SimulatorPage.tsx with FormattedMessage
- [x] [M] feat: add 23 missing consultants.* i18n keys to en.ts and es.ts
- [x] [M] feat: add 17 missing billing.* i18n keys to en.ts and es.ts
- [x] [M] feat: add 31 missing config.* i18n keys to en.ts and es.ts
- [x] [XS] feat: add 4 profitability.* i18n keys to en.ts and es.ts
- [x] [S] feat: add 26 simulator.* i18n keys for family situation, meal card, bonus fields
- [x] [L] feat: achieve full Javalin i18n key parity (CHNG-014) — 200 missing keys added across en.ts and es.ts (consultants, billing, common, config, simulator, report, profitability, setupWizard, config.dump, clients sections). 589 EN / 588 ES keys total. tsc + build green.

#### Gap Closure — Phase 5: BillingSummaryPage Extensions

- [x] [S] feat: add fetchMomBilling() to frontend api.ts and MomBillingRow/MomBillingResponse types
- [x] [M] feat: add MoM billing line chart with dual axes (daily billing + growth %) to BillingSummaryPage
- [x] [S] feat: add MoM billing per-month table with projected rows to BillingSummaryPage
- [x] [S] feat: add fetchBonusBreakdown() and refreshBonusBreakdown() to frontend api.ts
- [x] [S] feat: add bonus breakdown table with year filter to BillingSummaryPage
- [x] [S] feat: add bonus summary KPI cards (manager, tenure, quarterly totals) to BillingSummaryPage
- [x] [S] feat: add fetchForecast() to frontend api.ts and ForecastResponse type
- [x] [S] feat: add 5 forecast KPI cards to BillingSummaryPage
- [x] [S] feat: add year-over-year comparison table with fetchYoy() to BillingSummaryPage
- [x] [S] feat: add bonus refresh button to BillingSummaryPage

#### Gap Closure — Phase 6: ProfitabilityStatus UI

- [x] [XS] feat: create StatusBadge.tsx component with 4 color-coded profitability states
- [x] [S] feat: add profitabilityStatus column to consultant table in ConsultantsPage
- [x] [M] feat: create RevenueLeaderboard.tsx component with search/sort/pagination/medals
- [x] [S] feat: add RevenueLeaderboard to BillingSummaryPage
- [x] [M] feat: extract ConsultantTable.tsx from ConsultantsPage inline table
- [x] [S] feat: create ConsultantFilterBar.tsx with search input (Active/All/Terminated toggle deferred per design decision)
- [x] [S] feat: create DropdownInput.tsx with search-as-you-type

#### Gap Closure — Phase 7: Backend Polish

- [x] [XS] feat: create Money.java value object with non-negative validation
- [x] [XS] feat: create Coef.java, CoefPct.java, Tariff.java value objects
- [x] [XS] feat: create Bonus.java, TaxRate.java, Salary.java value objects
- [x] [L] refactor: update Consultant domain record to use typed value objects (Coef, Money, Tariff, etc.)
- [x] [L] refactor: update all service/controller/DTO layers for typed value objects
- [x] [M] feat: BillingCalculator fully ported (monthDaily, currentDaily, remainingDays, ytdBilling, annualProjected, trailingAvg, avgGrowthRate, projectedRemaining)
- [x] [S] feat: port PaginationHelper.paginate() utility to shared package
- [x] [S] feat: seed 20+ default settings + 8 cost concepts + 7 SS categories on database initialization

#### CHNG-015 (Complete): Javalin Parity Phase 8 — Backend Polish
*Fiscal endpoints, backup upload, PaginationHelper, DB seeding, OpenAPI/Swagger, SetupWizardPage.*

- [x] [S] T-001: Create FiscalController with GET/PUT /api/fiscal/{key}
- [x] [S] T-002: Register FiscalController in CoeffApplication
- [x] [S] T-003: Add backup upload endpoints to AdminController
- [x] [XS] T-004: Create PaginationHelper utility
- [x] [M] T-005: Add default DB seeding to CoeffConfig
- [x] [S] T-006: Wire OpenAPI/Swagger plugin
- [x] [M] T-007: Port SetupWizardPage frontend
- [x] [S] T-008: Add i18n keys for admin/report sections

### M8: Flyway Schema Management
*Replace inline initSchema() DDL with Flyway migrations for versioned schema management (CHNG-016).*

- [x] [S] build: add flyway-core and jooby-flyway dependencies to coeff build
- [x] [M] feat: create V1__initial_schema.sql base migration
- [x] [M] feat: wire Flyway in SqliteConnection and remove initSchema() DDL
- [x] [S] feat: wire Flyway migrate in AuthController.setup()
- [x] [S] feat: wire Flyway migrate after dump restore in AdminService
- [x] [S] fix: add baselineOnMigrate(true) for non-empty schema restore
- [x] [XS] fix: mark ConsultantRow createdAt/updatedAt as @Nullable
- [x] [S] feat: create V2__add_views.sql for Flyway view migration
- [x] [XS] fix: remove NOT NULL from ALTER TABLE ADD COLUMN for SQLite compat

#### Test Coverage

- [ ] [S] test: add integration tests for AuthController and SimulatorController

- [ ] [S] test: add integration tests for AuthController endpoints
- [ ] [S] test: add integration tests for ConsultantController CRUD
- [ ] [S] test: add integration tests for SimulatorController endpoints
- [ ] [S] test: add frontend component tests for LoginPage and SimulatorPage

#### CHNG-013: Javalin Parity Phase 6 — Hook Extraction
*Port 7 shared business-logic hooks from Javalin frontend into coeff frontend.*

- [x] [S] T-001: Create hooks directory barrel export file (index.ts)
- [x] [S] T-002: Port useCoefConfig hook from Javalin
- [x] [S] T-003: Port useFiscalConfig hook from Javalin
- [x] [XS] T-004: Port useConcepts hook from Javalin
- [x] [S] T-005: Port useBackups hook from Javalin
- [x] [M] T-006: Port useDumpBackups hook from Javalin (215 lines)
- [x] [XS] T-007: Port usePasswordForm hook from Javalin
- [x] [XS] T-008: Port useCsvExport utilities from Javalin

#### Phase 3: Bonus System

- [x] [M] feat: add tenure_bonuses, quarterly_bonuses, bonus_breakdown_cache tables and services
- [x] [S] feat: add bonus breakdown API endpoints
- [x] [S] feat: integrate bonuses into BillingSummary
- [x] [M] feat: add bonus display to BillingSummaryPage frontend

### M5: COEF Simulator
*Tax engine (IRPF+SS), COEF calculator, fiscal configuration.*

- [x] [M] feat: create TaxEngine and SimulatorService
- [x] [M] feat: create SimulatorController, SettingsController, ConceptsController
- [x] [S] feat: create frontend SimulatorPage and ConfigPage

### M4: Consultant Management
*Consultant CRUD, billing analytics, client grouping, CSV import.*

- [x] [S] feat: create Consultant domain entity, action, and use cases
- [x] [S] feat: create Consultant JDBI repos, DTOs, and controller
- [x] [S] feat: create Billing service and controller
- [x] [S] feat: create Client grouping and financial analytics endpoints
- [x] [S] feat: create CSV import endpoint
- [x] [M] feat: create frontend ConsultantsPage, BillingPage, ClientsPage, ImportPage

### M2: Core Platform (Backend + Frontend Foundation)

*Foundational platform: Jooby/SQLite backend, React SPA shell, i18n. Dependency for all feature PRDs.*

- [x] [S] build: configure coeff subproject with Gradle, SQLite, and quality gates
- [x] [XS] feat: create SqliteConnection and schema initialization
- [x] [XS] feat: create ExceptionMapper and domain exceptions
- [x] [S] feat: create CoeffApplication with Jooby, CORS, static files, OpenAPI
- [x] [S] feat: create React SPA shell with Vite, HashRouter, and Metronic layout
- [x] [S] feat: create i18n infrastructure with EN/ES bundles

### M3: Security (Auth, Token Validation & DB Encryption)

*Three security layers: password-based auth, HMAC token validation, AES-256-GCM database encryption.*

- [x] [S] feat: create AuthService with HMAC token and password hashing
- [x] [XS] feat: create AuthRepository and SqliteAuthRepository
- [x] [S] feat: create AuthController with setup/login/logout endpoints
- [x] [S] feat: create AuthFilter for token validation on /api/* routes
- [x] [M] feat: create DbEncryption for AES-256-GCM file encryption
- [x] [S] feat: create frontend api.ts with auth headers and 401/503 handling
- [x] [S] feat: create LoginPage with login/setup forms

---

## Completed Tasks

### M1: Project Bootstrap
*Completed during project generation. Scaffold, build tool, and first build were set up automatically.*

- [x] Project scaffold created (src/, tests/, config/)
- [x] Framework and build tool configured
- [x] First working build verified
- [x] Initial commit created

---

## Task Format Convention

For non-trivial tasks (new features, architectural changes), include the PRD reference:
```markdown
- [ ] feat: Add OAuth login (PRD: docs/project/prd/20260424-oauth.md)
```

---

## Legend

- `[ ]` = Pending
- `[WIP]` = In progress — do NOT start another agent on this task
- `[x]` = Completed
