# CHNG-012: Forecast & YoY — Design

## Architecture
No new components. Both sections render inline within BillingSummaryPage.tsx using existing Card primitives.

## Data Flow
```
BillingSummaryPage mount
  ├── fetchBillingSummary  → data            (existing)
  ├── fetchBillingMonthly  → monthly         (existing)
  ├── fetchConsultants     → consultants     (existing)
  ├── fetchForecast        → forecast        (NEW)
  └── fetchYoy             → yoy             (NEW)
```

Both new calls run in parallel with existing calls via `Promise.all`.

## Forecast Section Layout
- 2×3 grid of KPI cards inside a `Forecast` Card wrapper:
  1. Current Daily Billing (€, formatted)
  2. YTD Working Days (number)
  3. YTD Billing (€)
  4. YTD Growth % (percentage, or "—" if null)
  5. Remaining Working Days (number)
  6. Projected Remaining (€)
- Second row: Projected Total (€, bold), Avg Growth Rate (%)

## YoY Section Layout
- `<table>` inside a Card with `border-collapse`
- Columns match javalin's YoY display exactly
- Empty state: `intl.formatMessage(...)` with a muted paragraph
- Data rows mapped from `YoyRow[]` with `delta` and `deltaPct` formatted as signed values

## Types
Both `ForecastResponse` and `YoyRow` already exist in `types.ts`. No new type definitions needed.

## Decisions

### ADR-012-001: Inline rendering vs separate components
- **Decision:** Inline within BillingSummaryPage (same pattern as existing tariff/scatter/leaderboard sections).
- **Rationale:** The page already renders 7+ distinct sections inline. Extracting would add complexity without benefit — no section is reused.
- **Type:** Two-way door (easy to extract later).

### ADR-012-002: Conditional YTD growth display
- **Decision:** Show "—" when `ytdGrowthPct` is null (no previous year data).
- **Rationale:** YTD growth requires prior-year data. A null-safe render prevents UI gaps.
- **Type:** Two-way door.

## Traceability
| REQ-ID | File | Element |
|--------|------|---------|
| REQ-FCAST-UI-001 | BillingSummaryPage.tsx | Forecast section container |
| REQ-FCAST-UI-002 | BillingSummaryPage.tsx | 8 KPI cards |
| REQ-YOY-UI-001 | BillingSummaryPage.tsx | YoY table |
| REQ-YOY-UI-002 | BillingSummaryPage.tsx | Table columns |
| REQ-YOY-UI-003 | BillingSummaryPage.tsx | Empty state |
| REQ-API-001 | api.ts | fetchForecast, fetchYoy imports |
