# CHNG-010: Design — Javalin parity phase 3 bonus breakdown

## Decisions

| Decision | Rationale |
|----------|-----------|
| Add `BonusBreakdownRow` interface in existing `types.ts` | All API response types live in one file; no reason to split |
| Add `fetchBonusBreakdown`/`refreshBonusBreakdown` in existing `api.ts` | All API functions are in `api.ts` using the `request<T>` helper |
| Use existing 2-column layout (MoM billing + bonus breakdown) | Mirrors Javalan's `grid-cols-1 lg:grid-cols-2` structure |
| Derive `availableYears` from `monthly` data | The monthly rows span all years; no separate years endpoint needed |
| Use `useMemo` for bonusSummary | Prevents re-computation on every render |

## Data Model

No new backend tables or records. `BonusBreakdownRow` is a frontend-only TypeScript type:

```typescript
interface BonusBreakdownRow {
  id: number;
  year: number;
  month: string;
  managerBonus: number;
  tenureCount: number;
  tenureAmount: number;
  projectedTenureCount: number;
  projectedTenureAmount: number;
  quarterlyCount: number;
  quarterlyAmount: number;
  totalBonus: number;
}
```

## Interfaces

### API

```
GET  /api/billing/bonus-breakdown?year=<number>  → BonusBreakdownRow[]
POST /api/billing/bonus-breakdown/refresh         → { ok: true, status: "rebuilding" }
```

### Frontend functions

```
fetchBonusBreakdown(year?: number): Promise<BonusBreakdownRow[]>
refreshBonusBreakdown(): Promise<void>
```

### BillingSummaryPage state

```typescript
const [bonusRows, setBonusRows] = useState<BonusBreakdownRow[]>([]);
const [bonusLoading, setBonusLoading] = useState(true);
const [bonusYear, setBonusYear] = useState<number | undefined>(currentYear);
const [refreshingBonus, setRefreshingBonus] = useState(false);
```

## C4 Model

No new containers or components. The bonus breakdown uses the existing:
- **Frontend** (`BillingSummaryPage.tsx`) → `fetchBonusBreakdown` (api.ts) → `GET /api/billing/bonus-breakdown`
- **Backend** (`BonusBreakdownController`) → `BonusBreakdownCacheService` → `bonus_breakdown_cache` table

This is purely a frontend integration change; the backend (controller, service, DB table) already exists and is registered in `CoeffApplication.java`.

## Files

| File | Change | REQ |
|------|--------|-----|
| `frontend/src/types.ts` | Add `BonusBreakdownRow` interface | BBD-001 |
| `frontend/src/api.ts` | Add `fetchBonusBreakdown()` and `refreshBonusBreakdown()` | BBD-001, BBD-002 |
| `frontend/src/pages/BillingSummaryPage.tsx` | Import new types/api; add state, useEffects, useMemo for summary; render bonus breakdown card with KPI cards + table next to MoM card | BBD-001 through BBD-006 |
| `frontend/src/i18n/en.ts` | Add `billing.bonusBreakdown`, `billing.totalManagerBonus`, `billing.totalTenureBonuses`, `billing.totalQuarterlyBonuses`, `billing.tenureBonus`, `billing.quarterlyBonus`, `billing.allYears`, `common.month` | BBD-007 |
| `frontend/src/i18n/es.ts` | Add Spanish translations for the same keys | BBD-007 |
