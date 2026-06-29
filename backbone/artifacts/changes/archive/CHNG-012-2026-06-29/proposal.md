# CHNG-012: Javalin Parity Phase 5 — Forecast & YoY on BillingSummaryPage

## Overview
Add forecast KPI cards and YoY comparison table to the existing BillingSummaryPage. The backend endpoints `/api/report/forecast` and `/api/report/yoy` already exist in coeff with types `ForecastResponse` and `YoyRow`. This change wires the frontend: api.ts calls, UI cards, and a data table.

## EARS Requirements

### REQ-FCAST-UI-001 (Ubiquitous)
The BillingSummaryPage SHALL display a Forecast section after the existing billing cards, using data from `fetchForecast()`.

### REQ-FCAST-UI-002 (Ubiquitous)
The Forecast section SHALL render KPI cards for: current daily billing, YTD billing, YTD growth %, projected remaining, projected total, and avg growth rate.

### REQ-YOY-UI-001 (Ubiquitous)
The BillingSummaryPage SHALL display a YoY comparison table after the Forecast section, using data from `fetchYoy()`.

### REQ-YOY-UI-002 (Ubiquitous)
The YoY table SHALL include columns: year, headcount, daily, monthly, annual, hires, terminations, avg COEF%, manager bonus, delta (annual), delta %.

### REQ-YOY-UI-003 (Event-driven)
When the YoY data set is empty, the component SHALL render an empty-state message instead of an empty table.

### REQ-API-001 (Ubiquitous)
The `api.ts` file SHALL export `fetchForecast` (already exists) used by the Forecast section, and re-verify that `fetchYoy` (already exists) is used by the YoY section.

### REQ-I18N-001 (Ubiquitous)
The i18n keys used by the new UI SHALL already exist in both en.ts and es.ts under the `report.forecast.*` and `report.yoy.*` namespaces.

## Scope
- **In scope:** BillingSummaryPage.tsx (new sections), no other files changed.
- **Out of scope:** Backend endpoints (they exist). i18n keys (they exist from Javalin parity).

- **REQ-ARCHIVE:** Completed and archived.
- **REQ-CLOSE-001**: All tasks completed and change archived.
