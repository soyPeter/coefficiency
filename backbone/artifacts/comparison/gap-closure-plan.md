# Gap Closure Plan: Javalin → Jooby Feature Parity

**Current completeness:** ~70% backend, ~40% frontend  
**Goal:** 100% feature parity with `javalin-coef-calc`  
**Total est. effort:** ~14-20 days  

---

## Phase 1: Critical Backend Fixes (1-2 days)

These fix incorrect behavior that produces wrong data.

### 1.1 Fix monthly breakdown (BillingService.monthly())
**Problem:** Current SQL `GROUP BY strftime('%Y-%m',start_date)` only shows months with new hires. Terminations are always 0. No manager bonus per month.

**Fix:** Port BillingCalculator's per-month iteration logic. For each year from earliest to current, for each month 1-12, iterate all consultants and count hires, terminations, compute manager bonus (with `canEarnManagerBonus`), tenure bonuses, quarterly bonuses, active tariffs.

**Files:**
- `services/coeff/src/main/java/io/bitnomio/coeff/billing/BillingService.java` — rewrite `monthly()` method
- New: `services/coeff/src/main/java/io/bitnomio/coeff/billing/domain/BillingCalculator.java` — port 13 static methods

**Size:** [M]

### 1.2 Fix file import (FileImportController)
**Problem:** No file validation (size/type), no dedup, no multipart upload, no structured result.

**Fix:** Add file size limit (2MB), type check (.csv only), dedup on (name+client+startDate), return structured `ImportResult(success, count, message)`.

**Files:**
- `services/coeff/src/main/java/io/bitnomio/coeff/file/FileImportController.java`

**Size:** [S]

### 1.3 Add `activeCount` to billing summary
**Problem:** Summary returns `consultantCount` (all) but not `activeCount` (active only).

**Fix:** Add SQL query counting only active consultants.

**Files:**
- `services/coeff/src/main/java/io/bitnomio/coeff/billing/BillingService.java`

**Size:** [XS]

---

## Phase 2: Reports Frontend (2-3 days)

Largest visible gap — the entire ReportsPage is missing.

### 2.1 Create ReportsPage
**Problem:** 11 report API endpoints exist but no frontend to display them.

**Content:** 11 toggleable sections:
1. Consultant roster table
2. COEF analytics (avg, max, min, count)
3. Billing summary KPIs
4. Bonus breakdown by quarter with subtotals
5. Client financials table
6. Profitability trends chart (line)
7. Revenue vs targets radial charts
8. Per-consultant billing (searchable table)
9. Client timeline selector
10. Role aggregation with peer benchmarks
11. Peer benchmark comparison

Plus: year/date-range filter, CSV export for all sections.

**Files:**
- New: `frontend/src/pages/ReportsPage.tsx` (~1000 lines)
- New: `frontend/src/types.ts` — add 15+ report interfaces
- New: `frontend/src/api.ts` — add 10 report fetch functions
- Update: `frontend/src/routing/app-routing.tsx` — add `/reports` route
- Update: `frontend/src/components/layouts/layout-1/components/sidebar.tsx` — add Reports nav item
- Update: `frontend/src/i18n/en.ts`, `es.ts` — add 75+ report keys

**Size:** [L]

---

## Phase 3: Admin UI in ConfigPage (2 days)

Password change, backup management, and prune are backend-ready but have no frontend.

### 3.1 Add password change form to ConfigPage
**Files:**
- `frontend/src/pages/ConfigPage.tsx` — add form (current password, new password, confirm)
- `frontend/src/i18n/en.ts`, `es.ts` — add 5 config.password* keys

**Size:** [S]

### 3.2 Add backup management tab to ConfigPage
**Content:** List backups, create backup, restore from backup, create dump backup (with password), restore dump, prune database. All backend endpoints exist.

**Files:**
- `frontend/src/pages/ConfigPage.tsx` — add backup tab
- `frontend/src/api.ts` — add backup fetch functions
- `frontend/src/types.ts` — add `BackupFile` interface
- `frontend/src/i18n/en.ts`, `es.ts` — add 20+ config.backup* keys

**Size:** [M]

### 3.3 Update sidebar
**Files:**
- `frontend/src/components/layouts/layout-1/components/sidebar.tsx` — verify all nav items present

**Size:** [XS]

---

## Phase 4: i18n Completeness (1 day)

~270 i18n keys missing across en.ts and es.ts.

### 4.1 Add missing keys
**Categories:**
- `consultants.*` — 23 keys (status, filters, analytics)
- `billing.*` — 17 keys (MoM, bonuses, period)
- `profitability.*` — 4 keys (PROFITABLE, AT_RISK, etc.)
- `config.*` — 31 keys (backup, password, params)
- `setupWizard.*` — 20+ keys
- `simulator.*` — 5+ keys (family situation, meal card, etc.)

Also fix hardcoded English labels in SimulatorPage.tsx (Personal Data, Age, Category, Salary & Pricing, Benefits & Equipment sections).

**Files:**
- `frontend/src/i18n/en.ts` — add ~270 keys
- `frontend/src/i18n/es.ts` — add ~270 keys
- `frontend/src/pages/SimulatorPage.tsx` — replace hardcoded labels with FormattedMessage

**Size:** [M]

---

## Phase 5: Extend BillingSummaryPage (1-2 days)

### 5.1 Add MoM billing display
**Content:** Line chart with dual axes (daily billing + growth %), MoM table per month with projected rows.

**Files:**
- `frontend/src/pages/BillingSummaryPage.tsx` — add MoM section
- `frontend/src/api.ts` — add `fetchMomBilling()`
- `frontend/src/types.ts` — add `MomBillingRow`, `MomBillingResponse`
- `frontend/src/i18n/en.ts`, `es.ts` — add billing.mom* keys

**Size:** [M]

### 5.2 Add bonus breakdown display
**Content:** Bonus breakdown table per month with year filter, refresh button, summary cards (total manager bonus, total tenure, total quarterly).

**Files:**
- `frontend/src/pages/BillingSummaryPage.tsx` — add bonus section
- `frontend/src/api.ts` — add `fetchBonusBreakdown()`, `refreshBonusBreakdown()`
- `frontend/src/types.ts` — add `BonusBreakdownRow`
- `frontend/src/i18n/en.ts`, `es.ts` — add billing.bonus* keys

**Size:** [M]

### 5.3 Add forecast display
**Content:** 5 KPI cards (YTD working days, YTD billing, remaining days, projected remaining, projected total).

**Files:**
- `frontend/src/pages/BillingSummaryPage.tsx` — add forecast cards
- `frontend/src/api.ts` — add `fetchForecast()`
- `frontend/src/types.ts` — add `ForecastResponse`
- `frontend/src/i18n/en.ts`, `es.ts` — add 5+ forecast keys

**Size:** [S]

---

## Phase 6: ProfitabilityStatus UI (1 day)

Status badges and filtering on consultant table.

### 6.1 Create StatusBadge component
**Content:** Color-coded badge for PROFITABLE (green), AT_RISK (amber), BELOW_THRESHOLD (red), INSUFFICIENT_DATA (grey).

**Files:**
- New: `frontend/src/components/consultants/StatusBadge.tsx`
- `frontend/src/pages/ConsultantsPage.tsx` — add status column
- `frontend/src/types.ts` — add profitabilityStatus to Consultant
- `frontend/src/i18n/en.ts`, `es.ts` — add profitability.* keys

**Size:** [S]

### 6.2 Add RevenueLeaderboard component
**Content:** Sortable, searchable, paginated leaderboard table with medal icons.

**Files:**
- New: `frontend/src/components/RevenueLeaderboard.tsx`
- `frontend/src/pages/ConsultantsPage.tsx` — replace inline leaderboard
- `frontend/src/pages/BillingSummaryPage.tsx` — add RevenueLeaderboard

**Size:** [M]

### 6.3 Extract ConsultantTable component
**Content:** Reusable table with status badges, profitability, bonus blur, tariff coloring, sort columns.

**Files:**
- New: `frontend/src/components/consultants/ConsultantTable.tsx`
- New: `frontend/src/components/consultants/ConsultantFilterBar.tsx`
- New: `frontend/src/components/consultants/DropdownInput.tsx`
- `frontend/src/pages/ConsultantsPage.tsx` — use new components

**Size:** [M]

---

## Phase 7: Backend Polish (1-2 days)

### 7.1 Port value objects
**Content:** Create `Money`, `Coef`, `CoefPct`, `Tariff`, `Bonus`, `TaxRate` value objects with validation. Update Consultant domain to use them.

**Files:**
- New: `services/coeff/src/main/java/io/bitnomio/coeff/shared/domain/Money.java`
- New: `services/coeff/src/main/java/io/bitnomio/coeff/shared/domain/Coef.java`
- New: `services/coeff/src/main/java/io/bitnomio/coeff/shared/domain/CoefPct.java`
- New: `services/coeff/src/main/java/io/bitnomio/coeff/shared/domain/Tariff.java`
- New: `services/coeff/src/main/java/io/bitnomio/coeff/shared/domain/Bonus.java`
- New: `services/coeff/src/main/java/io/bitnomio/coeff/shared/domain/TaxRate.java`
- Update: many files that reference raw doubles

**Size:** [L]

### 7.2 Port BillingCalculator
**Content:** 13 static methods for billing calculations currently done inline.

**Files:**
- New: `services/coeff/src/main/java/io/bitnomio/coeff/billing/domain/BillingCalculator.java`

**Size:** [M]

### 7.3 Add seed data
**Content:** Default settings (20+), cost concepts (8), SS categories (7) on first run.

**Files:**
- `services/coeff/src/main/java/io/bitnomio/coeff/shared/db/SqliteConnection.java` — seed defaults after schema init

**Size:** [S]

---

## Dependency Map

```
Phase 1 (Backend fixes) ──────────────────────────────────────┐
                                                               │
Phase 2 (ReportsPage) ── Phase 3 (Admin UI) ── Phase 4 (i18n) │
                                                               │
Phase 5 (BillingSummaryPage) ─── Phase 6 (Profitability UI)   │
                                                               │
                    Phase 7 (Backend polish) ──────────────────┘
```

- Phase 1 is independent and highest priority (fixes wrong data)
- Phases 2-6 are frontend work — can run partially in parallel
- Phase 7 is lowest priority (value objects, BillingCalculator)

## Quick Wins (1-2 hours each)

- 1.3: Add `activeCount` to billing summary
- 4.1: Fix hardcoded English labels in SimulatorPage
- 6.1: Create StatusBadge component
- 3.1: Add password change form
- 1.2: Fix file import validation
