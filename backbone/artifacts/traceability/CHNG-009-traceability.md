# Traceability — CHNG-009: Javalin Parity Phase 2: MoM Billing

## Implementation Summary

Added Month-over-Month billing endpoints, domain records, and frontend UI. Backend additions include `MomBillingRow`/`MomBillingResponse` records, `getMomBilling(year)` with projection logic, and `getMomBilling()` no-arg for all-years mode. Frontend adds dual-axis line chart overlaying current+previous year, plus summary cards and year-selectable table.

## File Map

| REQ-ID | Files | Status |
|--------|-------|--------|
| REQ-MOM-DOMAIN-001 | `services/coeff/.../billing/domain/MomBillingRow.java` | Created |
| REQ-MOM-DOMAIN-002 | `services/coeff/.../billing/domain/MomBillingResponse.java` | Created |
| REQ-MOM-DOMAIN-003 | `MomBillingRow.java` (compact ctor validation) | Created |
| REQ-MOM-CALC-001 | `BillingService.java` — `readCoefDaysMonth()`, `buildActualMomRow()` | Added |
| REQ-MOM-CALC-002 | `BillingService.java` — `buildActualMomRow()` computes billingDelta | Added |
| REQ-MOM-CALC-003 | `BillingService.java` — `buildActualMomRow()` computes momGrowthPct | Added |
| REQ-MOM-CALC-004 | `BillingCalculator.trailingAvg()` (pre-existing, tested) | Verified |
| REQ-MOM-CALC-005 | `BillingCalculator.avgGrowthRate()` (pre-existing, tested) | Verified |
| REQ-MOM-PROJ-001 | `BillingService.getMomBilling(int year)` projection loop | Added |
| REQ-MOM-PROJ-002 | Projected rows marked `projected = true` in projection loop | Added |
| REQ-MOM-ENDPOINT-001 | `BillingController.mom(@QueryParam("year"))` | Added |
| REQ-MOM-ENDPOINT-002 | `getMomBilling(int year)` — single year | Added |
| REQ-MOM-ENDPOINT-003 | `getMomBilling()` — all years | Added |
| REQ-MOM-FRONT-001 | `types.ts` (interfaces), `api.ts` (fetch), `BillingSummaryPage.tsx` (chart) | Added |
| REQ-MOM-FRONT-002 | `BillingSummaryPage.tsx` — previous year overlay | Added |
| REQ-MOM-FRONT-003 | `BillingSummaryPage.tsx` — year-selectable table | Added |
| REQ-MOM-FRONT-004 | `BillingSummaryPage.tsx` — summary cards (avg daily, total, avg growth) | Added |

## Test Files

| Test File | Tests |
|-----------|-------|
| `MomBillingRowTest.java` | 5 tests (valid values, null delta, delta+growth, negative workingDays, zero workingDays) |
| `BillingCalculatorMomTest.java` | 14 tests (trailingAvg, avgGrowthRate caps, monthDaily active/excluded, projectedRemaining) |

## Verification Results

- Build: `./gradlew :services:coeff:compileJava` — SUCCESS
- Tests: `./gradlew :services:coeff:test` — ALL PASSING (78+ tests, including pre-existing)
- Frontend: `tsc && vite build` — SUCCESS (2549 modules, 999KB JS bundle)
