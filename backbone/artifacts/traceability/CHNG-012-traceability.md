# Traceability — CHNG-012: Javalin Parity Phase 5 — Forecast & YoY on BillingSummaryPage

## Implementation Summary

Added Forecast KPI cards and YoY comparison table to BillingSummaryPage. Frontend-only change: `ForecastResponse` and `YoyRow` types already existed in `types.ts`, `fetchForecast` and `fetchYoy` already existed in `api.ts`. Added i18n keys to both `en.ts` and `es.ts`, created Forecast section (2×3 KPI grid + second row with projected total and avg growth rate), and YoY comparison table (11-column table with signed deltas, empty state for no data). Both sections render inline in BillingSummaryPage.

## File Map

| REQ-ID | Files | Status |
|--------|-------|--------|
| REQ-FCAST-UI-001 | `services/coeff/frontend/src/pages/BillingSummaryPage.tsx` (Forecast section container, `fetchForecast` in Promise.all, `forecast` state) | Added |
| REQ-FCAST-UI-002 | `services/coeff/frontend/src/pages/BillingSummaryPage.tsx` (8 KPI cards: current daily billing, YTD working days, YTD billing, YTD growth %, remaining working days, projected remaining, projected total, avg growth rate) | Added |
| REQ-YOY-UI-001 | `services/coeff/frontend/src/pages/BillingSummaryPage.tsx` (YoY table section, `fetchYoy` in Promise.all, `yoy` state) | Added |
| REQ-YOY-UI-002 | `services/coeff/frontend/src/pages/BillingSummaryPage.tsx` (11 table columns: year, headcount, daily, monthly, annual, hires, terminations, avg COEF%, manager bonus, delta, delta %) | Added |
| REQ-YOY-UI-003 | `services/coeff/frontend/src/pages/BillingSummaryPage.tsx` (empty state when `yoy.length === 0`, shows `<FormattedMessage id="report.yoy.empty" />`) | Added |
| REQ-API-001 | `services/coeff/frontend/src/api.ts` (`fetchForecast`, `fetchYoy` — already existed, verified imports used in BillingSummaryPage) | Verified |
| REQ-I18N-001 | `services/coeff/frontend/src/i18n/en.ts`, `services/coeff/frontend/src/i18n/es.ts` (9 forecast + 12 yoy keys added) | Added |

## Files Modified

| File | Change |
|------|--------|
| `services/coeff/frontend/src/i18n/en.ts` | Added 21 i18n keys (`report.forecast.*`, `report.yoy.*`, `billing.forecast`, `billing.yoy`) |
| `services/coeff/frontend/src/i18n/es.ts` | Added 21 i18n keys (Spanish translations) |
| `services/coeff/frontend/src/pages/BillingSummaryPage.tsx` | Added forecast/yoy state, fetch calls in Promise.all, Forecast KPI section, YoY comparison table section |

## Test Files

No test files — frontend has no test infrastructure (no Jest/Vitest/RTL in dependencies). Verified via build.

## Verification Results

- TypeScript: `tsc --noEmit` — SUCCESS (no errors)
