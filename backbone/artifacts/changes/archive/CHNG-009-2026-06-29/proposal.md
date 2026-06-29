# CHNG-009: Javalin parity phase 2 MoM billing

**What:** Add Month-over-Month billing page and API endpoint to the coefficiency project, matching the existing Javalin reference implementation at `javalin-coef-calc`.

**Why:** The billing summary currently lacks MoM growth visibility. The Javalin reference has a `/api/billing/mom` endpoint that returns per-month daily billing, monthly billing, deltas, and growth percentages with future-month projection. This parity gap blocks users from seeing billing trends and projected annual billing based on trailing averages.

**Scope:**
- `services/coeff/src/main/java/io/bitnomio/coeff/billing/domain/MomBillingRow.java` (create)
- `services/coeff/src/main/java/io/bitnomio/coeff/billing/domain/MomBillingResponse.java` (create)
- `services/coeff/src/main/java/io/bitnomio/coeff/billing/BillingController.java` (modify)
- `services/coeff/src/main/java/io/bitnomio/coeff/billing/BillingService.java` (modify)
- `services/coeff/src/main/java/io/bitnomio/coeff/billing/domain/BillingCalculator.java` (modify)
- `services/coeff/frontend/src/api.ts` (modify)
- `services/coeff/frontend/src/types.ts` (modify)
- `services/coeff/frontend/src/pages/BillingSummaryPage.tsx` (modify)

## Requirements

- **REQ-MOM-DOMAIN-001** The system shall define an `MomBillingRow` record with fields: month (String), dailyBilling (double), workingDays (int), monthlyBilling (double), billingDelta (Double, nullable), momGrowthPct (Double, nullable), projected (boolean).
- **REQ-MOM-DOMAIN-002** The system shall define an `MomBillingResponse` record with fields: year (int), rows (List of MomBillingRow).
- **REQ-MOM-DOMAIN-003** When `MomBillingRow` is constructed with negative workingDays, the system shall throw IllegalArgumentException.
- **REQ-MOM-CALC-001** The system shall compute `monthDaily` as the sum of tariffs for all active consultants in a given month (month/year).
- **REQ-MOM-CALC-002** The system shall compute `billingDelta` as the difference between current month's monthlyBilling and the previous month's monthlyBilling.
- **REQ-MOM-CALC-003** The system shall compute `momGrowthPct` as the percentage change between consecutive months' monthlyBilling, rounded to 1 decimal place.
- **REQ-MOM-CALC-004** The system shall compute `trailingAvg` as the arithmetic mean of an array of daily billing values.
- **REQ-MOM-CALC-005** The system shall compute `avgGrowthRate` as the average month-over-month growth rate from a trailing array, capped at ±50%.
- **REQ-MOM-PROJ-001** The system shall project future months (after the current month) using the trailing average daily rate compounded by monthly avgGrowthRate.
- **REQ-MOM-PROJ-002** The system shall mark projected rows with `projected = true`.
- **REQ-MOM-ENDPOINT-001** The system shall expose `GET /api/billing/mom` with optional query param `year` (Integer).
- **REQ-MOM-ENDPOINT-002** When `year` is provided, the system shall return MoM rows for that specific year only.
- **REQ-MOM-ENDPOINT-003** When `year` is omitted, the system shall return MoM rows for all years from the earliest consultant start year through the current year.
- **REQ-MOM-FRONT-001** The billing summary page shall fetch MoM data for the current year and display a line chart with monthly billing (left axis) and MoM growth percentage (right axis).
- **REQ-MOM-FRONT-002** The billing summary page shall fetch MoM data for the previous year and overlay it on the same chart for year-over-year comparison.
- **REQ-MOM-FRONT-003** The billing summary page shall display a year-selectable MoM table with columns: Month, Daily Billing (€), Monthly (€), MoM Δ (€).
- **REQ-MOM-FRONT-004** The billing summary page shall show summary cards for Avg Daily Billing, Total Billing, and Avg MoM Growth.

### Acceptance Criteria
- **AC-REQ-MOM-DOMAIN-001.1:** When MomBillingRow receives workingDays = -1, constructor throws IllegalArgumentException.
- **AC-REQ-MOM-CALC-001.1:** Given consultants A (500€ tariff) and B (400€ tariff) active in June, monthDaily returns 900.
- **AC-REQ-MOM-CALC-005.1:** Given trail [100, 110, 121], avgGrowthRate returns 0.10 (10%).
- **AC-REQ-MOM-CALC-005.2:** Given trail [1000, 100, 200], avgGrowthRate returns no more than 0.5 (50% cap).
- **AC-REQ-MOM-PROJ-001.1:** When current month is June (June being complete), response includes rows for Jul–Dec with projected=true.
- **AC-REQ-MOM-ENDPOINT-002.1:** GET /api/billing/mom?year=2025 returns rows only for 2025 months.
- **AC-REQ-MOM-ENDPOINT-003.1:** GET /api/billing/mom (no year) returns rows spanning earliest consultant start year through current year.
- **AC-REQ-MOM-FRONT-001.1:** BillingSummaryPage renders a dual-axis line chart (monthly billing + MoM growth %).
- **AC-REQ-MOM-FRONT-002.1:** The line chart includes both current year and previous year data series.
- **REQ-CLOSE-001**: All tasks completed and change archived.
