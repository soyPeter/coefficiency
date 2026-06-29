# Porting Plan: Javalin → Jooby

**Goal:** Port all features from `javalin-coef-calc` to `coefficiency` (Jooby)

---

## Phase 1: Fix Existing Blockers (M6 Tasks)

These are the 5 blocker issues from REVIEW.md plus critical security warnings. Must fix first because they affect existing code and would compound errors during porting.

| Task | Size | Description |
|------|------|-------------|
| B1: Fix token decode | [S] | Change backend to produce base64 tokens (or frontend to hex-decode). Currently `atob()` on hex tokens always fails → users can never persist login |
| B2: Fix JDBI column mapping | [M] | Add `@ColumnName` annotations to `Consultant` domain record for snake_case → camelCase mapping |
| B3: Fix sort/search/order params | [M] | Implement dynamic SQL in `ConsultantSqlQueryRepo` for sort, order, search parameters |
| B4: Fix CSV parsing | [S] | Replace naive `line.split(",")` with proper CSV parser (e.g., OpenCSV or Apache Commons CSV) |
| B5: Fix CSV column schema | [S] | Align `FileImportController`, `DocsController`, and frontend import page to use same column schema |
| W1: Replace hardcoded HMAC secret | [S] | Load HMAC secret from `data/.hmac-secret` file, generate random on first run |
| W8: Enforce 8-char password min | [XS] | Change `length < 4` to `length < 8` |

**Verification:** `./gradlew :services:coeff:build` passes, manual login/session persistence works

---

## Phase 2: Port Core Simulator Enhancement

The Javalin project has a far more detailed COEF simulator (26 input fields vs 3). This is the core business value.

### Backend
| Task | Size | Description |
|------|------|-------------|
| Expand TaxEngine | [M] | Add dual-bracket IRPF (estatal + regional), family deductions (spouse, children, ascendants, disability), LIRPF expenses, professional categories, bonus calendar logic |
| Expand SimulatorInput | [S] | Add 26 fields matching Javalin's `SimulatorInput`: bonus calendar, category, kids, ascendants, disability, family situation, other income IRPF/SS, tax-free remuneration, etc. |
| Expand SimulatorResult | [S] | Add full breakdown: gross/net monthly salary, net annual, monthly SS + IRPF, effective rates, total consultant cost, COEF %, margin, manager bonus, monthly projection |
| Add simulation history | [M] | Create `simulations` table, add save/list/delete endpoints |
| Add `PUT /consultants/{id}/coef` | [S] | Endpoint to save COEF simulation results to a consultant record |
| Add professional categories | [S] | Load categories from settings, define bonus schedules (Trimestral/Semestral/Anual) |

### Frontend
| Task | Size | Description |
|------|------|-------------|
| Expand SimulatorPage inputs | [M] | Add 26 input fields: category selector, age, bonus calendar, children/ascendants/disability counters, family situation, other income inputs, tax-free remuneration, dynamic cost rows with autocomplete |
| Add real-time calculation | [S] | Trigger calculation on any input change, display live results |
| Add save-to-consultant | [S] | Save COEF results back to consultant with confirmation |
| Add simulation history UI | [S] | List past simulations, load/compare results |

---

## Phase 3: Port Bonus System

### Backend
| Task | Size | Description |
|------|------|-------------|
| Create tenure bonus table & service | [M] | Create `tenure_bonuses` table, `TenureBonusService` (EUR 300 after 3 months tenure), `SqliteTenureBonusRepository` |
| Create quarterly bonus table & service | [M] | Create `quarterly_bonuses` table, `QuarterlyBonusService` (EUR 500/quarter if net hires meet target), `SqliteQuarterlyBonusRepository` |
| Create bonus breakdown cache | [M] | Create `bonus_breakdown_cache` table, `BonusBreakdownCacheService`, auto-rebuild on startup + manual refresh endpoint |
| Add bonus breakdown endpoints | [S] | `GET /api/billing/bonus-breakdown?year=`, `POST /api/billing/bonus-breakdown/refresh` |
| Add manager bonus eligibility | [S] | Day-of-month rules, August exclusion, start/end day cutoff logic |
| Integrate bonus into BillingSummary | [S] | Add tenure + quarterly bonus counts/amounts to summary response |

### Frontend
| Task | Size | Description |
|------|------|-------------|
| Add bonus breakdown table | [S] | Year-filterable table in BillingSummaryPage showing manager bonus, tenure, quarterly bonus |
| Add bonus KPIs to billing | [S] | Display total bonus amounts in billing summary cards |

---

## Phase 4: Port Report Module

### Backend
| Task | Size | Description |
|------|------|-------------|
| Create report service endpoints | [L] | Port 11 endpoints: `/api/report`, `/profitability`, `/targets`, `/client-timeline`, `/clients`, `/role-aggregation`, `/per-consultant`, `/forecast`, `/yoy`, `/benchmarks`, `/years` |
| Add peer benchmarking | [M] | P25/P50/P75 tariff percentiles per role, `ProfitabilityStatus` enum, auto-recompute on COEF save + CSV import |
| Create v_position_profitability view | [S] | Enhanced view with benchmarks, ranked by total margin |

### Frontend
| Task | Size | Description |
|------|------|-------------|
| Create ReportsPage | [L] | 11-section report: consultants list, COEF stats, billing summary, bonuses, clients, profitability chart, revenue vs targets, per-consultant breakdown (searchable/sortable), client timeline selector, role aggregation with peer benchmarks, YoY comparison. Year/date range filters. CSV export |

---

## Phase 5: Port Admin Module

### Backend
| Task | Size | Description |
|------|------|-------------|
| Add backup/restore endpoints | [M] | Create encrypted DB copies, list backups, restore from backup, encrypted SQL dumps, restore from dump |
| Add health endpoint | [S] | System + DB health: JVM metrics, CPU, memory, disk, DB size, row counts |
| Add prune endpoint | [S] | Reset business data (consultants, simulations, concepts, settings, bonuses) preserving users |
| Add password change endpoint | [S] | `POST /api/auth/password` with old password verification |
| Add database reset endpoint | [XS] | `POST /api/auth/reset-database` |

### Frontend
| Task | Size | Description |
|------|------|-------------|
| Add backup management tab to ConfigPage | [M] | Create encrypted/dump backups, list with dates, restore with confirmation, prune with confirmation |
| Add password change form to ConfigPage | [S] | Old password + new password form with validation |

---

## Phase 6: Security Hardening

| Task | Size | Description |
|------|------|-------------|
| Migrate to BCrypt passwords | [S] | Replace SHA-256 with BCrypt, auto-migrate legacy hashes on login |
| Restrict CORS to localhost | [XS] | Change `Access-Control-Allow-Origin: *` to `http://localhost:*` + `http://127.0.0.1:*` |
| Add rate limiting | [XS] | Implement request rate limiting |

---

## Phase 7: Polish & Quality

| Task | Size | Description |
|------|------|-------------|
| Add OpenAPI/Swagger/ReDoc | [M] | Integrate Jooby OpenAPI module, annotate endpoints |
| Add unit tests | [M] | Tests for TaxEngine, SimulatorService, AuthService, BillingCalculator, bonus services |
| Add integration tests | [S] | E2E tests for main controller endpoints |
| Add JaCoCo coverage | [S] | Configure JaCoCo with minimum coverage threshold |
| Add frontend ESLint/Prettier | [S] | Configure code quality tooling matching Javalin project |

---

## Dependency Map

```
Phase 1 (Bug fixes)
  │
  ▼
Phase 2 (Core simulator) ──── Phase 3 (Bonus system)
  │                              │
  ▼                              ▼
Phase 4 (Report module) ◄────────┘
  │
  ▼
Phase 5 (Admin module)
  │
  ▼
Phase 6 (Security)
  │
  ▼
Phase 7 (Polish & tests)
```

- Phases 2 and 3 can run in parallel (different modules)
- Phase 4 depends on both 2 and 3 (reports aggregate bonus + simulator data)
- Phase 5 is independent of 2-4
- Phase 6 can run in parallel with 2-5
- Phase 7 is last

## Effort Estimate

| Phase | Backend Files | Frontend Files | New Tables | Est. Effort |
|-------|--------------|----------------|------------|-------------|
| 1 (Fixes) | 5-8 | 1 | 0 | 1-2 days |
| 2 (Simulator) | 5-8 | 2-3 | 1 | 2-3 days |
| 3 (Bonuses) | 8-12 | 2-3 | 3 | 2-3 days |
| 4 (Reports) | 10-15 | 2-3 | 0 | 3-4 days |
| 5 (Admin) | 5-8 | 2-3 | 0 | 2-3 days |
| 6 (Security) | 2-4 | 0 | 0 | 0.5 day |
| 7 (Polish) | 5-10 | 2-3 | 0 | 2-3 days |
| **Total** | **40-65** | **11-16** | **4** | **~13-19 days** |
