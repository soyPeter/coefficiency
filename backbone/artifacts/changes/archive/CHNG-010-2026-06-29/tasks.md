# CHNG-010: Tasks

## Tasks

### Phase 1: Frontend types and API

- [x] [XS] Add `BonusBreakdownRow` interface to `services/coeff/frontend/src/types.ts`
  **File:** `services/coeff/frontend/src/types.ts`
  **Detail:** Add after `BenchmarkRow`:
  ```typescript
  export interface BonusBreakdownRow {
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

- [x] [XS] Add `fetchBonusBreakdown` function to `services/coeff/frontend/src/api.ts`
  **File:** `services/coeff/frontend/src/api.ts`
  **Detail:** Add before `fetchReportClients`:
  ```typescript
  export async function fetchBonusBreakdown(year?: number): Promise<BonusBreakdownRow[]> {
    const query = year ? `?year=${year}` : '';
    return request<BonusBreakdownRow[]>(`/billing/bonus-breakdown${query}`);
  }
  ```
  Add `BonusBreakdownRow` to the import from `@/types`.

- [x] [XS] Add `refreshBonusBreakdown` function to `services/coeff/frontend/src/api.ts`
  **File:** `services/coeff/frontend/src/api.ts`
  **Detail:** Add after `fetchBonusBreakdown`:
  ```typescript
  export async function refreshBonusBreakdown(): Promise<void> {
    await request<void>('/billing/bonus-breakdown/refresh', { method: 'POST' });
  }
  ```

### Phase 2: BillingSummaryPage — logic

- [x] [S] Add bonus breakdown state variables, loading effect, and refresh handler to `BillingSummaryPage.tsx`
  **File:** `services/coeff/frontend/src/pages/BillingSummaryPage.tsx`
  **Detail:** Add state:
  ```typescript
  const [bonusRows, setBonusRows] = useState<BonusBreakdownRow[]>([]);
  const [bonusLoading, setBonusLoading] = useState(true);
  const [bonusYear, setBonusYear] = useState<number | undefined>(currentYear);
  const [refreshingBonus, setRefreshingBonus] = useState(false);
  ```
  Add `bonusYear` useEffect (after the existing useEffects):
  ```typescript
  useEffect(() => {
    setBonusLoading(true);
    fetchBonusBreakdown(bonusYear).then(setBonusRows).finally(() => setBonusLoading(false));
  }, [bonusYear]);
  ```
  Add refresh handler (after the `currentYear` useEffect):
  ```typescript
  const handleRefreshBonus = async () => {
    setRefreshingBonus(true);
    try {
      await refreshBonusBreakdown();
      await new Promise(r => setTimeout(r, 500));
      const rows = await fetchBonusBreakdown(bonusYear);
      setBonusRows(rows);
    } finally {
      setRefreshingBonus(false);
    }
  };
  ```
  Update the import line to add `fetchBonusBreakdown, refreshBonusBreakdown` and `BonusBreakdownRow`.

- [x] [S] Add `bonusSummary` and `availableYears` useMemo to `BillingSummaryPage.tsx`
  **File:** `services/coeff/frontend/src/pages/BillingSummaryPage.tsx`
  **Detail:** Add after the `ytdBonus` useMemo:
  ```typescript
  const bonusSummary = useMemo(() => {
    const totalManagerBonus = bonusRows.reduce((s, r) => s + r.managerBonus, 0);
    const totalTenureAmount = bonusRows.reduce((s, r) => s + r.tenureAmount, 0);
    const totalTenureCount = bonusRows.reduce((s, r) => s + r.tenureCount, 0);
    const totalProjectedCount = bonusRows.reduce((s, r) => s + r.projectedTenureCount, 0);
    const totalProjectedAmount = bonusRows.reduce((s, r) => s + r.projectedTenureAmount, 0);
    const totalQuarterlyAmount = bonusRows.reduce((s, r) => s + r.quarterlyAmount, 0);
    const totalQuarterlyCount = bonusRows.reduce((s, r) => s + r.quarterlyCount, 0);
    return { totalManagerBonus, totalTenureAmount, totalTenureCount, totalProjectedCount, totalProjectedAmount, totalQuarterlyAmount, totalQuarterlyCount };
  }, [bonusRows]);
  ```
  Add after the `bonusData` const:
  ```typescript
  const availableYears = useMemo(() => {
    const years = new Set<number>();
    monthly.forEach(m => {
      const parts = m.month.split(' ');
      if (parts.length > 1) years.add(parseInt(parts[parts.length - 1]));
    });
    return Array.from(years).sort((a, b) => b - a);
  }, [monthly]);
  ```

### Phase 3: BillingSummaryPage — UI

- [x] [S] Add bonus breakdown card JSX with KPI cards and detail table to `BillingSummaryPage.tsx`
  **File:** `services/coeff/frontend/src/pages/BillingSummaryPage.tsx`
  **Detail:** After the MoM Billing `</Card>` (around line 375), add a second card:
  ```tsx
  <Card>
    <CardHeader className="pb-3">
      <CardTitle className="text-base flex items-center gap-2">
        <BarChart3 className="size-4 text-amber-600" />
        <FormattedMessage id="billing.bonusBreakdown" />
        <button onClick={handleRefreshBonus} disabled={refreshingBonus}
          className="ml-auto mr-2 p-1 rounded hover:bg-muted/50 disabled:opacity-50" title="Refresh breakdown data">
          <RefreshCw className={`size-3.5 ${refreshingBonus ? 'animate-spin' : ''}`} />
        </button>
        <select className="ml-2 border rounded px-2 py-1 text-xs bg-background"
          value={bonusYear ?? ''} onChange={e => setBonusYear(e.target.value ? Number(e.target.value) : undefined)}>
          <option value=""><FormattedMessage id="billing.allYears" /></option>
          {availableYears.map(y => (<option key={y} value={y}>{y}</option>))}
        </select>
      </CardTitle>
    </CardHeader>
    <CardContent>
      <div className="grid grid-cols-1 md:grid-cols-3 gap-3 mb-4">
        <div className="bg-amber-50 rounded-md p-3 border border-amber-200">
          <p className="text-xs text-amber-700 font-medium"><FormattedMessage id="billing.totalManagerBonus" /></p>
          <p className="text-lg font-bold text-amber-800">€{F(bonusSummary.totalManagerBonus)}</p>
        </div>
        <div className="bg-emerald-50 rounded-md p-3 border border-emerald-200">
          <p className="text-xs text-emerald-700 font-medium"><FormattedMessage id="billing.totalTenureBonuses" /></p>
          <p className="text-lg font-bold text-emerald-800">€{F(bonusSummary.totalTenureAmount)}{bonusSummary.totalProjectedAmount > 0 && <span className="text-amber-600 font-bold"> + €{F(bonusSummary.totalProjectedAmount)}</span>}</p>
          <p className="text-[10px] text-emerald-500">{bonusSummary.totalTenureCount} earned{bonusSummary.totalProjectedCount > 0 ? <span className="text-amber-600">, {bonusSummary.totalProjectedCount} projected</span> : ''}</p>
        </div>
        <div className="bg-sky-50 rounded-md p-3 border border-sky-200">
          <p className="text-xs text-sky-700 font-medium"><FormattedMessage id="billing.totalQuarterlyBonuses" /></p>
          <p className="text-lg font-bold text-sky-800">€{F(bonusSummary.totalQuarterlyAmount)}</p>
          <p className="text-[10px] text-sky-500">{bonusSummary.totalQuarterlyCount} earned</p>
        </div>
      </div>
      <div className="overflow-auto">
        {bonusLoading ? (
          <p className="text-sm text-muted-foreground p-2"><FormattedMessage id="billing.loading" /></p>
        ) : (
          <table className="w-full text-xs">
            <thead>
              <tr className="border-b bg-muted/30">
                <th className="text-left p-2"><FormattedMessage id="common.month" /></th>
                <th className="text-right p-2"><FormattedMessage id="common.bonus" /> (Mng)</th>
                <th className="text-right p-2"><FormattedMessage id="billing.tenureBonus" /></th>
                <th className="text-right p-2"><FormattedMessage id="billing.quarterlyBonus" /></th>
                <th className="text-right p-2 font-semibold"><FormattedMessage id="common.total" /></th>
              </tr>
            </thead>
            <tbody>
              {bonusRows.length === 0 ? (
                <tr><td colSpan={5} className="p-2 text-center text-muted-foreground">No bonus data.</td></tr>
              ) : bonusRows.map((r, i) => (
                <tr key={i} className="border-b hover:bg-muted/30">
                  <td className="p-2 font-medium">{r.month}</td>
                  <td className="p-2 text-right text-amber-700">{r.managerBonus > 0 ? `€${F(r.managerBonus)}` : '-'}</td>
                  <td className="p-2 text-right text-emerald-700">{r.tenureCount > 0 || r.projectedTenureCount > 0 ? (
                    <>{r.tenureAmount > 0 && <span>€{F(r.tenureAmount)}</span>}{r.projectedTenureAmount > 0 && <><span className="text-amber-600"> + €{F(r.projectedTenureAmount)}</span></>}</>
                  ) : '-'}</td>
                  <td className="p-2 text-right text-sky-700">{r.quarterlyAmount > 0 ? `€${F(r.quarterlyAmount)}` : '-'}</td>
                  <td className="p-2 text-right font-semibold">€{F(r.totalBonus)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </CardContent>
  </Card>
  ```
  Add imports: `RefreshCw` from `lucide-react`, `fetchBonusBreakdown, refreshBonusBreakdown` from `@/api`, `BonusBreakdownRow` from `@/types`.

### Phase 4: i18n

- [x] [XS] Add bonus breakdown i18n keys to `services/coeff/frontend/src/i18n/en.ts`
  **File:** `services/coeff/frontend/src/i18n/en.ts`
  **Detail:** Add before the `billing.tariffDistribution` key:
  ```
  'billing.bonusBreakdown': 'Bonus Breakdown',
  'billing.totalManagerBonus': 'Total Manager Bonus',
  'billing.totalTenureBonuses': 'Tenure Bonuses',
  'billing.totalQuarterlyBonuses': 'Quarterly Bonuses',
  'billing.tenureBonus': 'Tenure',
  'billing.quarterlyBonus': 'Quarterly',
  'billing.allYears': 'All years',
  'common.month': 'Month',
  ```

- [x] [XS] Add Spanish bonus breakdown i18n keys to `services/coeff/frontend/src/i18n/es.ts`
  **File:** `services/coeff/frontend/src/i18n/es.ts`
  **Detail:** Add before the `billing.tariffDistribution` key:
  ```
  'billing.bonusBreakdown': 'Desglose de Bonificaciones',
  'billing.totalTenureBonuses': 'Bonif. Antigüedad',
  'billing.totalQuarterlyBonuses': 'Bonif. Trimestrales',
  'billing.tenureBonus': 'Antigüedad',
  'billing.quarterlyBonus': 'Trimestral',
  'billing.allYears': 'Todos los años',
  'common.month': 'Mes',
  ```
  Note: `billing.totalManagerBonus` already exists in es.ts.
