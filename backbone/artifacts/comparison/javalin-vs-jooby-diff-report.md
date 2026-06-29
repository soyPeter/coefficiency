# Difference Report: Javalin-coef-calc → Coefficiency (Jooby)

**Date:** 2026-06-21
**Source:** `/Users/peter/projects/javalin-coef-calc` (Javalin 7.2.0, Maven)
**Target:** `/Users/peter/projects/coefficiency` (Jooby 4.5.1, Gradle)

---

## 1. Summary

| Dimension | Javalin Project | Jooby Project |
|-----------|----------------|---------------|
| Web Framework | Javalin 7.2.0 (Jetty 12) | Jooby 4.5.1 (Netty) |
| Build Tool | Maven (shade plugin) | Gradle (Shadow plugin) |
| DI | Manual/static | Avaje Inject (compile-time) |
| DB Access | Raw JDBC + HikariCP | JDBI 3.53.0 |
| Backend files | 110 source files | ~40 source files |
| Frontend files | 53 source files | ~35 source files |
| REST endpoints | 42 | 26 |
| DB tables | 8 + 2 views | 4 + 2 views |
| Tests | 28 test files | 0 |

---

## 2. Feature Gap Analysis

### 2.1 Modules Present in Javalin but Missing in Jooby

| # | Module | Endpoints | Backend Files | Frontend Impact | Priority |
|---|--------|-----------|---------------|-----------------|----------|
| 1 | **Bonus System** | 3 (`/api/billing/bonus-breakdown`, `bonus-breakdown/refresh`, `POST /api/consultants/{id}/coef`) | 10 files (tenurebonus/, quarterlybonus/, bonusbreakdown/) | Bonus breakdown table in BillingSummaryPage | High |
| 2 | **Report Module** | 11 endpoints (`/api/report`, `/profitability`, `/targets`, `/client-timeline`, `/clients`, `/role-aggregation`, `/per-consultant`, `/forecast`, `/yoy`, `/benchmarks`, `/years`) | 13 files | Full ReportsPage with 11 sections | High |
| 3 | **Admin Module** | 8 endpoints (`backup`, `backups`, `restore`, `restore-upload`, `backup-dump`, `dump-restore`, `health`, `prune`) | 5 files | Backup management in ConfigPage | Medium |
| 4 | **Peer Benchmarking** | 1 endpoint (`/api/report/benchmarks`) + status computation | 3 files | Benchmark display in reports | Medium |
| 5 | **Password Change** | `POST /api/auth/password` | 1 DTO | Password form in ConfigPage | Medium |
| 6 | **Database Reset** | `POST /api/auth/reset-database` | — | — | Low |

### 2.2 Enhanced Features (Present in Both, Richer in Javalin)

| Feature | Javalin | Jooby | Gap |
|---------|---------|-------|-----|
| **Auth/password hashing** | BCrypt + SHA-256 (auto-migrate) | SHA-256 only | No BCrypt in Jooby |
| **CORS** | Localhost-only | Open (`*`) | Security downgrade |
| **Rate limiting** | Yes (Javalin plugin) | No | Missing |
| **Token signing key** | Random per-instance (`data/.hmac-secret`) | Hardcoded constant | Security bug (B1/W1) |
| **Simulator inputs** | 26 input fields, bonus calendar, categories | ~3 input fields | Very basic simulation |
| **Simulator results** | Full breakdown + projection + save-to-consultant + history | Basic COEF% only | Minimal results |
| **Simulation history** | `simulations` table, saved runs | Not persisted | Missing |
| **CSV import** | 9 columns, validation, dedup, 2MB limit, .csv type check | 8 columns, split-only | Missing validation, dedup |
| **Fiscal config** | 30+ settings, working days grid, IRPF brackets, SS per-category | Working days, fewer settings | Limited configurability |
| **OpenAPI/Swagger** | Full OpenAPI + Swagger UI + ReDoc | None | Missing API docs |
| **Code quality** | Checkstyle, SpotBugs, JaCoCo 53% | OWASP only | Missing |

### 2.3 Database Schema Differences

| Table | Javalin | Jooby | Action |
|-------|---------|-------|--------|
| `users` | + token_version, BCrypt hash column | SHA-256 hash + salt | Add token_version, migrate |
| `consultants` | 22 fields (full COEF data) | 16 fields (basic) | Add coef_projection, profitability_status, plus simulation result fields |
| `settings` | 30+ key/value pairs | ~10 key/value pairs | Add new keys |
| `cost_concepts` | Same | Same | Align seeded data |
| `simulations` | EXISTS | MISSING | CREATE |
| `tenure_bonuses` | EXISTS | MISSING | CREATE |
| `quarterly_bonuses` | EXISTS | MISSING | CREATE |
| `bonus_breakdown_cache` | EXISTS | MISSING | CREATE |
| `v_client_financials` | Same (more fields) | Same | Enhance |
| `v_position_profitability` | Enhanced for benchmarks | Basic | Enhance |

### 2.4 Frontend Differences

| Page | Javalin | Jooby | Action |
|------|---------|-------|--------|
| `SimulatorPage` | 26 inputs, bonus calendar, categories, concept autocomplete, real-time calc, save-to-consultant | Basic inputs, fewer fields | Major expansion |
| `BillingSummaryPage` | MoM chart, bonus breakdown table, YOY, forecast, revenue leaderboard | Basic charts, no bonus, no forecast | Add bonus + forecast sections |
| `ConfigPage` | 5 tabs (COEF, Fiscal, Concepts, Password, Backups) | 3 tabs (no Password, no Backups) | Add 2 tabs |
| `ConsultantsPage` | Full COEF data display, leaderboard, detail drawer with simulator link, CSV export | Basic CRUD, fewer charts | Enhance data display |
| `ClientsPage` | Revenue concentration pie, CSV export | No export | Add export |
| `ReportsPage` | **MISSING in Jooby** | **MISSING** | CREATE |
| `DocsPage` | Auto-generated from OpenAPI | Hardcoded | Use OpenAPI |
| `FileImportPage` | Drag-drop, validation, progress | Drag-drop, basic | Add validation |

### 2.5 Additional Frontend Libraries in Javalin

| Library | Purpose | Jooby has it? |
|---------|---------|---------------|
| `@dnd-kit` | Drag and drop | No |
| `@tanstack/react-query` | Server state management | No |
| `@tanstack/react-table` | Table with sorting/filtering | No |
| `sonner` | Toast notifications | No |
| `zod` | Schema validation | No |
| `react-hook-form` | Form state management | No |
| `apexcharts` | Additional chart types | No |
| `motion` (framer-motion) | Animations | No |
| `lucide-react` | Icons | No |
| `date-fns` | Date utilities | No |
| `leaflet` | Maps (unused?) | No |
| `notistack` | Notifications | No |

---

## 3. Security Differences

| Issue | Javalin | Jooby | Severity |
|-------|---------|-------|----------|
| HMAC secret | Random per-instance file | Hardcoded constant | **Critical** |
| Password hashing | BCrypt | SHA-256-only | **High** |
| CORS | localhost-only | `*` (any origin) | **Medium** |
| Rate limiting | Enabled | Missing | **Low** |
| Password min length | 8 chars | 4 chars | **Medium** |
| Token decode | hex (matches backend) | base64 decode of hex | **Critical** (B1) |
| Virtual threads | Enabled | Missing (Netty handles) | Low |

---

## 4. Recommended Porting Order

### Phase 1: Fix Existing Blockers (M6 tasks)
- Fix B1-B5 from REVIEW.md (token decode, JDBI mapping, sort/search, CSV parsing, column mismatch)
- Fix W1 (hardcoded HMAC secret)
- Fix W8 (password minimum length)
- Fix W5 (controller package locations)

### Phase 2: Core Enhancements
- Port enhanced Simulator with 26-field input
- Port BCrypt password hashing
- Port CORS restriction to localhost
- Add rate limiting

### Phase 3: Bonus System
- Add tenure_bonuses, quarterly_bonuses, bonus_breakdown_cache tables
- Port bonus calculation services
- Port bonus breakdown API endpoints
- Add bonus UI to BillingSummaryPage

### Phase 4: Report Module
- Add report service endpoints
- Add peer benchmarking
- Port full ReportsPage frontend

### Phase 5: Admin Module
- Port backup/restore system
- Port system health endpoint
- Add password change
- Add backup management UI

### Phase 6: Polish
- Add OpenAPI/Swagger
- Add tests (unit + integration)
- Add code quality tooling
- Port additional frontend libraries
