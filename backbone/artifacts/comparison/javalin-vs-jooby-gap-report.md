# Javalin vs Jooby (Coefficiency) — Gap Analysis

**Date:** 2026-06-22
**Source:** `/Users/peter/projects/javalin-coef-calc` (Javalin 7.2.0, Maven)
**Target:** `/Users/peter/projects/coefficiency` (Jooby 4.5.1, Gradle)

---

## ✅ In Sync (Already Ported)

| Feature | Notes |
|---------|-------|
| Auth (login/logout/status/setup/password change) | |
| Consultant CRUD + COEF update | |
| Billing summary + monthly breakdown | |
| Client summaries + financials | |
| CSV file import | |
| Bonus system (tenure_bonuses, quarterly_bonuses, bonus_breakdown_cache) | |
| Report module (11 endpoints) | |
| Admin module (backup/restore/dump/health/prune) | |
| BCrypt password hashing + auto-migration | |
| CORS restricted to localhost | |
| Password min length (8+) | |
| HMAC secret from file | |
| Simulator (26-field input, full calc, save-to-consultant) | |
| TaxEngine with dual-bracket IRPF, family deductions, SS categories | |
| BillingCalculator (monthDaily, currentDaily, ytdBilling, annualProjected, etc.) | |
| ReportsPage frontend (11 sections) | |
| ConfigPage (fiscal params, concepts, backups, password) | |
| AutoLogoutDialog, ConfirmDialog, LanguageSwitcher | |
| Frontend libs: recharts, apexcharts, react-query, react-table, lucide, motion, sonner, zod, hook-form, date-fns | |

---

## ❌ Gaps: Backend

| # | Feature | Javalin | Coeff | Difficulty | Priority |
|---|---------|---------|-------|------------|----------|
| B1 | Typed value objects | `Money`, `Coef`, `CoefPct`, `Tariff`, `Salary`, `Bonus`, `TaxRate` records with validation | Raw `double` fields in Consultant | L (large — touches all layers) | High |
| B2 | MoM billing endpoint | `GET /api/billing/mom` + `MomBillingRow/Response` | ❌ Missing | M | High |
| B3 | Bonus breakdown endpoints | `GET /api/billing/bonus-breakdown`, `POST .../refresh` | ❌ Missing | S | High |
| B4 | Dedicated fiscal endpoints | `PUT /api/fiscal/days`, `/brackets`, `/regional-brackets`, `/ss`, `/params` | Generic `PUT /api/fiscal/{key}` | XS | Medium |
| B5 | Backup upload endpoints | `POST /api/admin/backups/restore-upload`, `dump/restore-upload` | ❌ Missing | XS | Medium |
| B6 | PaginationHelper utility | `shared/util/PaginationHelper.paginate()` | ❌ Missing | XS | Medium |
| B7 | Default DB seeding | 20+ settings, 8 cost concepts, 7 SS categories on init | ❌ Missing | S | Low |
| B8 | OpenAPI/Swagger/ReDoc wiring | Full OpenAPI spec + Swagger UI + ReDoc UI | Dependencies exist, not wired | XS | Low |

## ❌ Gaps: Frontend

| # | Feature | Javalin | Coeff | Difficulty | Priority |
|---|---------|---------|-------|------------|----------|
| F1 | Extracted consultant components | `ConsultantTable`, `ConsultantFilterBar`, `StatusBadge`, `DropdownInput`, `RevenueLeaderboard` | All inline in ConsultantsPage.tsx (878 lines) | M | High |
| F2 | MoM billing chart + table | Line chart (dual axis) + per-month table on BillingSummaryPage | ❌ Missing | M | High |
| F3 | Bonus breakdown table | Year-filtered table with manager/tenure/quarterly breakdown on BillingSummaryPage | ❌ Missing | M | High |
| F4 | Bonus KPI cards | Manager, tenure, quarterly totals on BillingSummaryPage | ❌ Missing | S | High |
| F5 | Dedicated hooks | `useCoefConfig`, `useFiscalConfig`, `useConcepts`, `useBackups`, `useDumpBackups`, `usePasswordForm`, `useCsvExport` (7 hooks) | Only 2 hooks (useIdleTimer, use-file-upload) | M | Medium |
| F6 | Forecast KPI cards | 5 forecast KPIs on BillingSummaryPage | ❌ Missing | S | Medium |
| F7 | YoY comparison table | On BillingSummaryPage | ❌ Missing | S | Medium |
| F8 | SetupWizardPage | Separate first-time setup flow | Handled in LoginPage | XS | Low |

## ❌ Gaps: i18n

| # | Locale | Javalin keys | Coeff keys | Missing |
|---|--------|-------------|------------|---------|
| I1 | English (en.ts) | 583 | 369 | **214** |
| I2 | Spanish (es.ts) | 582 | 368 | **214** |

---

## Recommended Execution Order

### Phase 1: Value Objects + Backend (Foundation)
1. Create `shared/domain/` value objects: `Money.java`, `Coef.java`, `CoefPct.java`, `Tariff.java`, `Salary.java`, `Bonus.java`, `TaxRate.java`
2. Refactor `Consultant` record to use typed VOs
3. Update all service/controller/DTO layers

### Phase 2: MoM Billing (Backend + Frontend)
4. Port `MomBillingRow` and `MomBillingResponse` domain records
5. Create MoM endpoint in BillingController
6. Add `fetchMomBilling()` to api.ts + types
7. Add MoM line chart + table to BillingSummaryPage

### Phase 3: Bonus Breakdown (Backend + Frontend)
8. Port `BonusBreakdownController` (GET + POST refresh)
9. Add `fetchBonusBreakdown()` + `refreshBonusBreakdown()` to api.ts + types
10. Add bonus breakdown table + KPI cards to BillingSummaryPage

### Phase 4: Frontend Component Extraction
11. Extract `ConsultantTable.tsx` from ConsultantsPage
12. Create `StatusBadge.tsx`, `ConsultantFilterBar.tsx`, `DropdownInput.tsx`
13. Create `RevenueLeaderboard.tsx` + add to BillingSummaryPage

### Phase 5: Forecase + YoY (BillingSummaryPage)
14. Add forecast KPI cards section
15. Add YoY comparison table section

### Phase 6: Missing Hooks Extraction
16. Create `useCoefConfig.ts`, `useFiscalConfig.ts`, `useConcepts.ts`
17. Create `useBackups.ts`, `useDumpBackups.ts`, `usePasswordForm.ts`, `useCsvExport.ts`

### Phase 7: i18n Completeness
18. Add all 214 missing keys to en.ts and es.ts

### Phase 8: Minor Backend Polish
19. Port dedicated fiscal endpoints
20. Port backup upload endpoints
21. Port PaginationHelper
22. Add default DB seeding
23. Wire OpenAPI/Swagger/ReDoc
24. Create SetupWizardPage
