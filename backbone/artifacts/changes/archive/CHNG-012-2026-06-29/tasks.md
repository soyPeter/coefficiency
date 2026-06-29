# CHNG-012: Tasks

## Task List

### [S] T-001: Add forecast state + fetch call to BillingSummaryPage
Add `useState<ForecastResponse | null>(null)` for forecast data. Add `fetchForecast().then(setForecast)` to the existing `Promise.all` in `useEffect`.
- **File:** BillingSummaryPage.tsx
- **Verification:** Build succeeds, data loads from `/api/report/forecast`.

### [S] T-002: Add yoy state + fetch call to BillingSummaryPage
Add `useState<YoyRow[]>([])` for yoy data. Add `fetchYoy().then(setYoy)` to `Promise.all`. Add early return rendering for yoy empty state.
- **File:** BillingSummaryPage.tsx
- **Verification:** Two new entries in Promise.all.

### [M] T-003: Render Forecast KPI card grid
Add a new Card section after the billing cards (line ~64). Inside, render a 2-column grid (lg:grid-cols-3) with 6 KPI cards showing: currentDailyBilling, ytdWorkingDays, ytdBilling, ytdGrowthPct (or "—"), remainingWorkingDays, projectedRemaining. Below that, a second row with projectedTotal and avgGrowthRate in a 2-column grid.
- **File:** BillingSummaryPage.tsx
- **I18n keys used:** `report.forecast.*`
- **Verification:** Visual check shows 8 data points in correct layout.

### [M] T-004: Render YoY comparison table
Add a new Card after forecast. Render an HTML table with columns: year, headcount, daily, monthly, annual, hires, terminations, avgCoef, managerBonus, delta, deltaPct. Format delta/deltaPct with sign prefix. Show "—" for null values.
- **File:** BillingSummaryPage.tsx
- **I18n keys used:** `report.yoy.*`
- **Verification:** Table renders with data from `/api/report/yoy`.

### [XS] T-005: Verify forecast/yoy data loads in loading/error paths
Confirm that if forecast API fails, the page still renders (the useEffect already uses `.finally()`). YoY empty array passes the empty-state check.
- **File:** BillingSummaryPage.tsx
- **Verification:** No crashes on API failure.
