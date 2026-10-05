# ADR-005: Bonus breakdown as a frontend-only integration

## Status
Accepted

## Date
Before 2026-10-05 (migrated from decision D-010; the original date was not recorded)

## Context
The backend for the bonus breakdown (`BonusBreakdownController`, `BonusBreakdownCacheService`, the `bonus_breakdown_cache` table) already existed from earlier platform work. The Javalin reference app showed a per-month bonus breakdown that the coefficiency frontend had to replicate.

## Decision
No backend changes. The frontend gained:
- a `BonusBreakdownRow` interface;
- `fetchBonusBreakdown` and `refreshBonusBreakdown` API functions;
- a bonus breakdown card on `BillingSummaryPage`, with KPI cards, a year filter, a refresh button and a detail table.

`availableYears` is derived from the monthly data with `useMemo` instead of a separate endpoint, and an `undefined` year means "all years". After a refresh, the page waits 500 ms before refetching, a pragmatic heuristic for the asynchronous rebuild.

## Alternatives considered
- A separate years endpoint: one more API surface for data the page already has.
- Polling or push for the rebuild status: correct, but more complexity than the use justified.

## Consequences
- The 500 ms delay is a heuristic. If the rebuild becomes slower, the page can show stale data until the next refetch.
- The feature reuses the existing `request<T>` helper and `useMemo` patterns.
