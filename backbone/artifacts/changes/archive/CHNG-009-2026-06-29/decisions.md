# CHNG-009: Decision Log

## Format

| # | Topic | Decision | Rationale | Alternatives | Type |
|---|-------|----------|-----------|--------------|------|
| 1 | <!-- What was decided --> | <!-- The choice --> | <!-- Why --> | <!-- What else was considered --> | auto | human |

- **Type:** `auto` = two-way door, cheap to reverse | `human` = one-way door, expensive to unwind
- Record decisions as they happen, not at the end

## Decisions

| # | Topic | Decision | Rationale | Alternatives | Type |
|---|-------|----------|-----------|--------------|------|
| 1 | Query param binding | Use `@QueryParam Integer year` Jooby annotation | Coefficiency uses Jooby; Javalin uses `ctx.queryParam()`. The Jooby annotation is the idiomatic way for this codebase. | Manually parsing from request | auto |
| 2 | `buildActualMomRow` signature | Accept `List<Map<String,Object>> rows` + re-map to `RawConsultant` | Coefficiency's `BillingService.monthly()` already loads raw maps and maps to `RawConsultant` inline. Reusing this pattern avoids adding a consultant repository dependency and keeps the method self-contained. | Pass `List<Consultant>` domain objects (requires repository refactor) | auto |
| 3 | `workingDays` value | Use `fiscal.coefDaysMonth` setting directly | The Javalin reference computes `coef_days_month` from a `working_days` JSON array. Coefficiency stores `fiscal.coefDaysMonth` as a flat setting. Using `SettingsHelper.readIntOrDefault` matches existing coefficiency patterns. | Computing from `working_days` JSON (would require adding a new setting) | auto |
| 4 | BillingCalculator changes | No changes needed — `monthDaily`, `trailingAvg`, `avgGrowthRate`, `projectedRemaining` already exist | These methods were added during previous forecasting work (CHNG-005). The MoM service can reuse them directly. | Duplicating logic in BillingService | auto |
| 5 | Projection lookback window | 3 months (same as Javalin) | Provides a stable trailing average without being too responsive to single-month anomalies. Matches existing reference implementation behavior. | 1-month, 6-month, 12-month | auto |
| 6 | Growth rate cap | ±50% (same as Javalin's `BillingCalculator.avgGrowthRate`) | Prevents unrealistically explosive projection values when a single month has extreme growth (e.g., a new large client starting mid-year). | No cap, ±25% | auto |
| 7 | MoM chart placement | Full-width card before Charts Row | The MoM chart is the most important visualization for billing trends. Placing it above the COEF% and bonus charts gives it primary visual weight. | Replacing first chart card, placing in sidebar | auto |
| 8 | TDD approach | Tests for domain records + BillingCalculator methods | Core domain logic (MomBillingRow validation, trailingAvg, avgGrowthRate, monthDaily, projectedRemaining) is testable without Jdbi. Service-level methods depend on Jdbi and are tested via integration. | Mocking Jdbi for unit tests | auto |
