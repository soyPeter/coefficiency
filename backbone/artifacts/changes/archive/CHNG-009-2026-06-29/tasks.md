# CHNG-009: Tasks

## Granularity Rules
- ONE file per task
- ONE method per task
- ONE endpoint/route per task
- ONE test scenario per task
- Size tags: [XS] single item, [S] method/query/test, [M] complex orchestration
- Concrete verbs only: add, fix, remove, configure, validate, create, update, extract, refactor
- NO vague verbs: implement, build, develop, do, make, setup
- NO "and" in task titles
- NO [L]
- NO PLACEHOLDERS — every step must contain complete code
- COMPLETE CODE — every implementation step must show the actual code to write

## Tasks

### Phase 1: Backend domain records

## [x] Add MomBillingRow record with validation to billing/domain/
**Parent:** REQ-MOM-DOMAIN-001, REQ-MOM-DOMAIN-003
**Size:** [XS]
**File:** `services/coeff/src/main/java/io/bitnomio/coeff/billing/domain/MomBillingRow.java`
**Code:**
```java
package io.bitnomio.coeff.billing.domain;

public record MomBillingRow(
    String month,
    double dailyBilling,
    int workingDays,
    double monthlyBilling,
    Double billingDelta,
    Double momGrowthPct,
    boolean projected
) {
    public MomBillingRow {
        if (workingDays < 0) throw new IllegalArgumentException("workingDays must be non-negative");
    }
}
```

## [x] Add MomBillingResponse record to billing/domain/
**Parent:** REQ-MOM-DOMAIN-002
**Size:** [XS]
**File:** `services/coeff/src/main/java/io/bitnomio/coeff/billing/domain/MomBillingResponse.java`
**Code:**
```java
package io.bitnomio.coeff.billing.domain;

import java.util.List;

public record MomBillingResponse(int year, List<MomBillingRow> rows) {}
```

### Phase 2: Backend service logic

## [x] Add readCoefDaysMonth() helper to BillingService
**Parent:** REQ-MOM-CALC-001
**Size:** [XS]
**File:** `services/coeff/src/main/java/io/bitnomio/coeff/billing/BillingService.java`
**Code:** Add after `getConsultantRecords()`:
```java
private int readCoefDaysMonth() {
    return SettingsHelper.readIntOrDefault(jdbi, "fiscal.coefDaysMonth", 21);
}
```

## [x] Add buildActualMomRow() method to BillingService
**Parent:** REQ-MOM-CALC-001, REQ-MOM-CALC-002, REQ-MOM-CALC-003
**Size:** [S]
**File:** `services/coeff/src/main/java/io/bitnomio/coeff/billing/BillingService.java`
**Code:** Add after `readCoefDaysMonth()`:
```java
private MomBillingRow buildActualMomRow(List<Map<String, Object>> rows, int year, int month, int cm, MomBillingRow prev) {
    var consultants = rows.stream().map(r -> new BillingCalculator.RawConsultant(
        ((Number) r.get("id")).intValue(), (String) r.get("name"), (String) r.get("client"),
        (String) r.get("position"), ((Number) r.get("coef")).doubleValue(),
        ((Number) r.get("tariff")).doubleValue(), (String) r.get("start_date"),
        (String) r.get("end_date"),
        r.get("fees") != null ? ((Number) r.get("fees")).doubleValue() : null,
        r.get("coef_percentage") != null ? ((Number) r.get("coef_percentage")).doubleValue() : null,
        r.get("coef_margin") != null ? ((Number) r.get("coef_margin")).doubleValue() : null,
        r.get("manager_bonus") != null ? ((Number) r.get("manager_bonus")).doubleValue() : null)).toList();

    double dailyBilling = RoundingUtil.round2(BillingCalculator.monthDaily(consultants, year, month));
    double monthlyBilling = RoundingUtil.round2(dailyBilling * cm);
    Double billingDelta = prev != null ? RoundingUtil.round2(monthlyBilling - prev.monthlyBilling()) : null;
    Double momGrowthPct = prev != null && prev.monthlyBilling() != 0
        ? Math.round(((monthlyBilling - prev.monthlyBilling()) / prev.monthlyBilling()) * 1000.0) / 10.0
        : null;
    String label = MONTHS[month - 1] + " " + year;
    return new MomBillingRow(label, dailyBilling, cm, monthlyBilling, billingDelta, momGrowthPct, false);
}
```

## [x] Add getMomBilling(int year) with projection to BillingService
**Parent:** REQ-MOM-CALC-004, REQ-MOM-CALC-005, REQ-MOM-PROJ-001, REQ-MOM-PROJ-002, REQ-MOM-ENDPOINT-002
**Size:** [M]
**File:** `services/coeff/src/main/java/io/bitnomio/coeff/billing/BillingService.java`
**Code:** Add after `monthly()`:
```java
public MomBillingResponse getMomBilling(int year) {
    var rows = jdbi.withHandle(h ->
        h.createQuery("SELECT id, name, client, position, coef, tariff, start_date, end_date, fees, coef_percentage, coef_margin, manager_bonus FROM consultants")
         .mapToMap().list());

    List<MomBillingRow> result = new ArrayList<>();
    MomBillingRow prev = null;
    int cm = readCoefDaysMonth();
    int currentMonth = LocalDate.now().getMonthValue();
    int currentYear = LocalDate.now().getYear();
    boolean isCurrentYear = year == currentYear;

    int maxMonth = isCurrentYear ? currentMonth : 12;
    for (int month = 1; month <= maxMonth; month++) {
        var row = buildActualMomRow(rows, year, month, cm, prev);
        result.add(row);
        prev = row;
    }

    if (isCurrentYear) {
        int lookback = Math.min(3, result.size());
        double[] trail = new double[lookback];
        for (int i = 0; i < lookback; i++) {
            trail[i] = result.get(result.size() - lookback + i).dailyBilling();
        }
        double trailingAvg = BillingCalculator.trailingAvg(trail);
        double avgGrowth = BillingCalculator.avgGrowthRate(trail);

        double projectedDaily = trailingAvg;
        for (int month = currentMonth + 1; month <= 12; month++) {
            projectedDaily *= (1 + avgGrowth);
            projectedDaily = RoundingUtil.round2(projectedDaily);

            double monthlyBilling = RoundingUtil.round2(projectedDaily * cm);
            Double bd = prev != null ? RoundingUtil.round2(monthlyBilling - prev.monthlyBilling()) : null;
            Double mgp = prev != null && prev.monthlyBilling() != 0
                ? Math.round(((monthlyBilling - prev.monthlyBilling()) / prev.monthlyBilling()) * 1000.0) / 10.0
                : null;
            String label = MONTHS[month - 1] + " " + year;
            var row = new MomBillingRow(label, projectedDaily, cm, monthlyBilling, bd, mgp, true);
            result.add(row);
            prev = row;
        }
    }

    return new MomBillingResponse(year, result);
}
```

## [x] Add getMomBilling() no-arg overload to BillingService
**Parent:** REQ-MOM-ENDPOINT-003
**Size:** [S]
**File:** `services/coeff/src/main/java/io/bitnomio/coeff/billing/BillingService.java`
**Code:** Add after `getMomBilling(int year)`:
```java
public MomBillingResponse getMomBilling() {
    var rows = jdbi.withHandle(h ->
        h.createQuery("SELECT id, name, client, position, coef, tariff, start_date, end_date, fees, coef_percentage, coef_margin, manager_bonus FROM consultants")
         .mapToMap().list());

    int currentYear = LocalDate.now().getYear();
    int earliestYear = rows.stream()
        .mapToInt(r -> r.get("start_date") != null ? LocalDate.parse((String) r.get("start_date")).getYear() : currentYear)
        .min().orElse(currentYear);

    List<MomBillingRow> allRows = new ArrayList<>();
    MomBillingRow prev = null;
    int cm = readCoefDaysMonth();

    for (int year = earliestYear; year <= currentYear; year++) {
        int maxMonth = year == currentYear ? LocalDate.now().getMonthValue() : 12;
        for (int month = 1; month <= maxMonth; month++) {
            var row = buildActualMomRow(rows, year, month, cm, prev);
            allRows.add(row);
            prev = row;
        }
    }

    return new MomBillingResponse(0, allRows);
}
```

### Phase 3: Backend controller

## [x] Add GET /api/billing/mom endpoint to BillingController
**Parent:** REQ-MOM-ENDPOINT-001, REQ-MOM-ENDPOINT-002, REQ-MOM-ENDPOINT-003
**Size:** [S]
**File:** `services/coeff/src/main/java/io/bitnomio/coeff/billing/BillingController.java`
**Code:** Add after the `/monthly` endpoint:
```java
    @GET @Path("/mom")
    public MomBillingResponse mom(@QueryParam("year") Integer year) {
        return year != null ? billingService.getMomBilling(year) : billingService.getMomBilling();
    }
```
Add import: `import io.jooby.annotation.QueryParam;` and `import io.bitnomio.coeff.billing.domain.MomBillingResponse;`
Remove unused import `java.util.Map` if present (check after edit).

### Phase 4: Frontend types and API

## [x] Add MomBillingRow and MomBillingResponse interfaces to types.ts
**Parent:** REQ-MOM-FRONT-001
**Size:** [XS]
**File:** `services/coeff/frontend/src/types.ts`
**Code:** Add before the final `BenchmarkRow` interface:
```typescript
export interface MomBillingRow {
  month: string;
  dailyBilling: number;
  workingDays: number;
  monthlyBilling: number;
  billingDelta: number | null;
  momGrowthPct: number | null;
  projected: boolean;
}

export interface MomBillingResponse {
  year: number;
  rows: MomBillingRow[];
}
```

## [x] Add fetchMomBilling() function to api.ts
**Parent:** REQ-MOM-FRONT-001
**Size:** [XS]
**File:** `services/coeff/frontend/src/api.ts`
**Code:** Add after `fetchBillingMonthly()`:
```typescript
export async function fetchMomBilling(year?: number): Promise<MomBillingResponse> {
  const query = year ? `?year=${year}` : '';
  return request<MomBillingResponse>(`/billing/mom${query}`);
}
```
Add `MomBillingResponse` to the import from `@/types`.

### Phase 5: Frontend page

## [x] Add MoM chart with dual-axis line chart to BillingSummaryPage
**Parent:** REQ-MOM-FRONT-001, REQ-MOM-FRONT-002
**Size:** [M]
**File:** `services/coeff/frontend/src/pages/BillingSummaryPage.tsx`
**Code:**
- Add `fetchMomBilling` to the import from `@/api`:
```typescript
import { fetchBillingSummary, fetchBillingMonthly, fetchConsultants, fetchMomBilling } from '@/api';
```
- Add `MomBillingResponse` to the import from `@/types`:
```typescript
import type { BillingSummary, MomBillingResponse } from '@/types';
```
- Add `LineChart` and `Line` to the recharts import:
```typescript
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, ScatterChart, Scatter, LineChart, Line } from 'recharts';
```
- Add state variables after the existing state declarations:
```typescript
const [momData, setMomData] = useState<MomBillingResponse | null>(null);
const [chartMomData, setChartMomData] = useState<MomBillingResponse | null>(null);
const [chartMomLastYearData, setChartMomLastYearData] = useState<MomBillingResponse | null>(null);
const [momYear, setMomYear] = useState<number>(currentYear);
```
- Add fetch effects after the existing `useEffect`:
```typescript
useEffect(() => {
  fetchMomBilling(currentYear).then(setChartMomData);
  fetchMomBilling(currentYear - 1).then(setChartMomLastYearData);
}, [currentYear]);

useEffect(() => {
  fetchMomBilling(momYear).then(setMomData);
}, [momYear]);
```
- Add computed data transformations before the loading check:
```typescript
const combinedMomData = useMemo(() => {
  if (!chartMomData) return null;
  const rows = chartMomLastYearData ? [...chartMomLastYearData.rows, ...chartMomData.rows] : chartMomData.rows;
  return { year: currentYear, rows };
}, [chartMomData, chartMomLastYearData, currentYear]);

const momChartData = useMemo(() => {
  if (!combinedMomData) return [];
  return combinedMomData.rows.map(r => ({
    month: r.month,
    momGrowthPct: r.momGrowthPct,
    monthlyBilling: r.monthlyBilling,
  }));
}, [combinedMomData]);

const momSummary = useMemo(() => {
  if (!momData || momData.rows.length === 0) return null;
  const rows = momData.rows;
  const avgDaily = rows.reduce((s, r) => s + r.dailyBilling, 0) / rows.length;
  const totalBilling = rows.reduce((s, r) => s + r.monthlyBilling, 0);
  const growthValues = rows.map(r => r.momGrowthPct).filter((v): v is number => v != null);
  const avgGrowth = growthValues.length > 0 ? growthValues.reduce((s, v) => s + v, 0) / growthValues.length : null;
  return { avgDaily, totalBilling, avgGrowth };
}, [momData]);
```
- Add the MoM chart card before the "Charts Row" comment, or replace the existing first card in the charts row with:
```tsx
<Card><CardHeader className="pb-2"><CardTitle className="text-base flex items-center gap-2">
    <TrendingUp className="size-4 text-emerald-600" /><FormattedMessage id="billing.mom" />
    <span className="text-xs text-muted-foreground font-normal">{currentYear - 1}–{currentYear}</span>
  </CardTitle></CardHeader>
  <CardContent><ResponsiveContainer width="100%" height={280}>
    {combinedMomData && combinedMomData.rows.length > 0 && momChartData.length > 0 ? (
      <LineChart data={momChartData} margin={{ top: 12, right: 24, bottom: 8, left: 0 }}>
        <CartesianGrid strokeDasharray="3 3" className="stroke-muted" />
        <XAxis dataKey="month" tick={{ fontSize: 11 }} interval={1} />
        <YAxis yAxisId="left" tick={{ fontSize: 11 }} />
        <YAxis yAxisId="right" orientation="right" tick={{ fontSize: 10 }} tickFormatter={(v: number) => `${v}%`} />
        <Tooltip formatter={(value: number, name: string) => {
          if (name === 'momGrowthPct') return [`${value >= 0 ? '+' : ''}${value.toFixed(1)}%`, 'MoM Δ'];
          return [`€${F(value)}`, 'Monthly Billing'];
        }} />
        <Line yAxisId="left" type="monotone" dataKey="monthlyBilling" stroke="#10b981" strokeWidth={2.5} dot={true} name="monthlyBilling" />
        <Line yAxisId="right" type="monotone" dataKey="momGrowthPct" stroke="#f59e0b" strokeWidth={2} dot={false} name="momGrowthPct" connectNulls />
      </LineChart>
    ) : <p className="text-sm text-muted-foreground text-center py-10">No billing data</p>}
  </ResponsiveContainer></CardContent></Card>
```

## [x] Add MoM summary cards and table with year selector to BillingSummaryPage
**Parent:** REQ-MOM-FRONT-003, REQ-MOM-FRONT-004
**Size:** [M]
**File:** `services/coeff/frontend/src/pages/BillingSummaryPage.tsx`
**Code:** Add after the charts row and before the leaderboard section:
```tsx
{/* MoM Billing */}
<Card>
  <CardHeader className="pb-3">
    <CardTitle className="text-base flex items-center gap-2">
      <TrendingUp className="size-4 text-emerald-600" />
      <FormattedMessage id="billing.mom" />
      <select className="ml-auto border rounded px-2 py-1 text-xs bg-background" value={momYear} onChange={e => setMomYear(Number(e.target.value))}>
        {(() => { const ys = new Set<number>(); monthly.forEach(m => { const p = m.month.split(' '); if (p.length > 1) ys.add(parseInt(p[p.length - 1])); }); return Array.from(ys).sort((a, b) => b - a).map(y => (<option key={y} value={y}>{y}</option>)); })()}
      </select>
    </CardTitle>
  </CardHeader>
  <CardContent>
    {momData && momData.rows.length > 0 && (
      <>
        {momSummary && (
          <div className="grid grid-cols-1 md:grid-cols-3 gap-3 mb-4">
            <div className="bg-amber-50 rounded-md p-3 border border-amber-200">
              <p className="text-xs text-amber-700 font-medium">Avg Daily Billing{momData.rows.some(r => r.projected) ? ' (proj.)' : ''}</p>
              <p className="text-lg font-bold text-amber-800">€{F(momSummary.avgDaily)}</p>
            </div>
            <div className="bg-emerald-50 rounded-md p-3 border border-emerald-200">
              <p className="text-xs text-emerald-700 font-medium">Total Billing{momData.rows.some(r => r.projected) ? ' (proj.)' : ''}</p>
              <p className="text-lg font-bold text-emerald-800">€{F(momSummary.totalBilling)}</p>
            </div>
            <div className="bg-sky-50 rounded-md p-3 border border-sky-200">
              <p className="text-xs text-sky-700 font-medium">Avg MoM Growth{momData.rows.some(r => r.projected) ? ' (proj.)' : ''}</p>
              <p className={`text-lg font-bold ${momSummary.avgGrowth != null && momSummary.avgGrowth >= 0 ? 'text-emerald-800' : 'text-red-700'}`}>
                {momSummary.avgGrowth != null ? `${momSummary.avgGrowth >= 0 ? '+' : ''}${momSummary.avgGrowth.toFixed(1)}%` : '-'}
              </p>
            </div>
          </div>
        )}
        <div className="overflow-auto">
          <table className="w-full text-xs">
            <thead>
              <tr className="border-b bg-muted/30">
                <th className="text-left p-2">Month</th>
                <th className="text-right p-2">Daily Billing (€)</th>
                <th className="text-right p-2">Monthly (€)</th>
                <th className="text-right p-2">MoM Δ (€)</th>
              </tr>
            </thead>
            <tbody>
              {momData.rows.map((r, i) => (
                <tr key={i} className="border-b hover:bg-muted/30">
                  <td className="p-2 font-medium">{r.month}</td>
                  <td className="p-2 text-right">€{F(r.dailyBilling)}</td>
                  <td className="p-2 text-right font-semibold">€{F(r.monthlyBilling)}</td>
                  <td className={`p-2 text-right ${r.billingDelta != null ? (r.billingDelta >= 0 ? 'text-emerald-600' : 'text-red-500') : 'text-muted-foreground'}`}>
                    {r.billingDelta != null ? `${r.billingDelta >= 0 ? '+' : ''}€${F(r.billingDelta)}` : '-'}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </>
    )}
    {(!momData || momData.rows.length === 0) && (
      <p className="text-sm text-muted-foreground">No billing data for this year.</p>
    )}
  </CardContent>
</Card>
```
