# CHNG-010: Javalin parity phase 3 bonus breakdown

**What:** Add `BonusBreakdownRow` type, `fetchBonusBreakdown`/`refreshBonusBreakdown` API functions, and bonus breakdown table + KPI cards to `BillingSummaryPage`.

**Why:** The Javalin reference app shows a per-month bonus breakdown table (manager, tenure, quarterly, projected tenure) with three KPI cards (total manager bonus, tenure bonuses, quarterly bonuses). The coefficiency backend already has the controller and cache service — the frontend gap needs closing.

**Scope:**
- `services/coeff/frontend/src/types.ts` — add `BonusBreakdownRow` interface
- `services/coeff/frontend/src/api.ts` — add `fetchBonusBreakdown()` + `refreshBonusBreakdown()`
- `services/coeff/frontend/src/pages/BillingSummaryPage.tsx` — add bonus breakdown section (year filter, refresh button, KPI cards, detail table)
- `services/coeff/frontend/src/i18n/en.ts` — add `billing.bonusBreakdown` i18n keys
- `services/coeff/frontend/src/i18n/es.ts` — add Spanish translations

## Requirements

- **REQ-BBD-001** When the user navigates to BillingSummaryPage, the system shall fetch bonus breakdown rows from `GET /api/billing/bonus-breakdown` and display them.
- **REQ-BBD-002** When the user clicks the refresh button, the system shall call `POST /api/billing/bonus-breakdown/refresh`, wait 500ms, then refetch the rows.
- **REQ-BBD-003** When the user selects a year from the dropdown, the system shall filter the bonus breakdown by year via the `?year=` query param.
- **REQ-BBD-004** When bonus data is loading, the system shall show a loading indicator in the table area.
- **REQ-BBD-005** When bonus breakdown rows are loaded, the system shall compute and display three KPI cards: total manager bonus, total tenure bonuses (with projected), and total quarterly bonuses.
- **REQ-BBD-006** When bonus breakdown rows are loaded, the system shall render a per-month detail table with columns: month, manager bonus, tenure bonus (with projected), quarterly bonus, and total.

### Acceptance Criteria

- **AC-BBD-001:** `BonusBreakdownRow` type matches the backend record shape: `id`, `year`, `month`, `managerBonus`, `tenureCount`, `tenureAmount`, `projectedTenureCount`, `projectedTenureAmount`, `quarterlyCount`, `quarterlyAmount`, `totalBonus`.
- **AC-BBD-002:** `fetchBonusBreakdown(year?)` calls `GET /api/billing/bonus-breakdown` and returns `BonusBreakdownRow[]`.
- **AC-BBD-003:** `refreshBonusBreakdown()` calls `POST /api/billing/bonus-breakdown/refresh` and returns `void`.
- **AC-BBD-004:** The bonus breakdown card sits next to the MoM billing card in a two-column grid.
- **AC-BBD-005:** The year dropdown defaults to the current year with an "All years" option.
- **AC-BBD-006:** KPI totals are computed via `useMemo` from the loaded `bonusRows`.
- **AC-BBD-007:** i18n keys are added for both `en.ts` and `es.ts` with matching IDs.
