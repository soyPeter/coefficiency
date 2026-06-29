# CHNG-010: Decision Log

## Decisions

| # | Topic | Decision | Rationale | Alternatives | Type |
|---|-------|----------|-----------|--------------|------|
| 1 | Backend scope | No backend changes — controller, cache service, DB table already exist | Phase 1 (CHNG-008) and early platform tasks already created `bonus_breakdown_cache`, `BonusBreakdownRow`, `BonusBreakdownController`, `BonusBreakdownCacheService` | Creating another backend layer | auto |
| 2 | Available years source | Derive from `monthly` data via `useMemo` | The monthly response spans all years; adding a dedicated years endpoint or extracting years from bonus data would add complexity with no benefit | Dedicated `/billing/years` endpoint | auto |
| 3 | Year filter null semantics | `undefined` year = no `?year=` param = server returns all rows | Backend `findByYear(null)` already runs `findAll`-equivalent; `undefined` is cleanest sentinel | Using `null` or `-1` sentinel | auto |
| 4 | Refresh delay | 500ms pause after `refreshBonusBreakdown` before refetch | Async rebuild may not persist to DB instantly; 500ms is a pragmatic heuristic | Polling on status endpoint | auto |
| 5 | Bonus row type shape | Match backend record exactly (11 fields) | Backend returns all fields; frontend needs them all for table + KPI cards | Separate DTO | auto |
| 6 | No frontend tests | No test infrastructure exists (no Vitest/Jest/RTL in package.json) | Adding test infra would bloat scope far beyond the feature | Adding test deps + config | two-way |
| 7 | i18n key placement | Added to existing `billing.*` namespace | Follows existing pattern for billing-related keys | New namespace `bonusBreakdown.*` | two-way |
| 8 | `common.month` didn't exist in i18n | Had to add it to both en.ts and es.ts for the bonus table header | Reusing existing `common.bonus` and `common.total` keys | Adding new keys | two-way |
