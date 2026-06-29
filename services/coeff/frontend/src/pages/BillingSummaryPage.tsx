import { useEffect, useState, useMemo } from 'react';
import { Euro, BarChart3, TrendingUp, CalendarDays, ArrowRight, Goal, ArrowUpFromLine, RefreshCw } from 'lucide-react';
import { FormattedMessage, FormattedNumber, useIntl } from 'react-intl';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { fetchBillingSummary, fetchBillingMonthly, fetchConsultants, fetchMomBilling, fetchBonusBreakdown, refreshBonusBreakdown, fetchForecast, fetchYoy } from '@/api';
import type { BillingSummary, MomBillingResponse, BonusBreakdownRow, ForecastResponse, YoyRow } from '@/types';
import RevenueLeaderboard from '@/components/RevenueLeaderboard';
import { BarChart, Bar, LineChart, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, ScatterChart, Scatter, Line } from 'recharts';

interface MonthlyRow { month: string; hires: number; terminations: number; avgCoef: number; totalBonus: number; tenureBonuses: number; tenureBonusAmount: number; quarterlyBonusAmount: number; }
interface ConsultantBrief { id: number; name: string; tariff: number; coefPercentage: number; position: string; coefMargin: number; managerBonus: number; fees: number; client: string; }

const F = (n: number) => n.toLocaleString('es-ES', { minimumFractionDigits: 2, maximumFractionDigits: 2 });

const MONTH_NAMES = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

export default function BillingSummaryPage() {
  const intl = useIntl();
  const now = new Date();
  const currentYear = now.getFullYear();
  const currentMonthIdx = now.getMonth();
  const [data, setData] = useState<BillingSummary | null>(null);
  const [monthly, setMonthly] = useState<MonthlyRow[]>([]);
  const [consultants, setConsultants] = useState<ConsultantBrief[]>([]);
  const [loading, setLoading] = useState(true);
  const [momData, setMomData] = useState<MomBillingResponse | null>(null);
  const [chartMomData, setChartMomData] = useState<MomBillingResponse | null>(null);
  const [chartMomLastYearData, setChartMomLastYearData] = useState<MomBillingResponse | null>(null);
  const [momYear, setMomYear] = useState<number>(currentYear);

  // REQ-BBD-001, REQ-BBD-003, REQ-BBD-004
  const [bonusRows, setBonusRows] = useState<BonusBreakdownRow[]>([]);
  const [bonusLoading, setBonusLoading] = useState(true);
  const [bonusYear, setBonusYear] = useState<number | undefined>(currentYear);
  const [refreshingBonus, setRefreshingBonus] = useState(false);

  // REQ-FCAST-UI-001, REQ-FCAST-UI-002
  const [forecast, setForecast] = useState<ForecastResponse | null>(null);
  // REQ-YOY-UI-001, REQ-YOY-UI-002
  const [yoy, setYoy] = useState<YoyRow[]>([]);

  useEffect(() => {
    Promise.all([
      fetchBillingSummary().then(setData),
      fetchBillingMonthly().then(setMonthly),
      fetchConsultants().then(setConsultants),
      fetchForecast().then(setForecast),
      fetchYoy().then(setYoy),
    ]).finally(() => setLoading(false));
  }, []);

  useEffect(() => {
    fetchMomBilling(currentYear).then(setChartMomData);
    fetchMomBilling(currentYear - 1).then(setChartMomLastYearData);
  }, [currentYear]);

  useEffect(() => {
    fetchMomBilling(momYear).then(setMomData);
  }, [momYear]);

  // REQ-BBD-001, REQ-BBD-003
  useEffect(() => {
    setBonusLoading(true);
    fetchBonusBreakdown(bonusYear).then(setBonusRows).finally(() => setBonusLoading(false));
  }, [bonusYear]);

  // REQ-BBD-002
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

  const tariffBuckets = useMemo(() => {
    const b: Record<string, number> = { '100-200': 0, '200-300': 0, '300-400': 0, '400-500': 0, '500+': 0 };
    consultants.forEach(c => { const t = c.tariff; if (t < 200) b['100-200']++; else if (t < 300) b['200-300']++; else if (t < 400) b['300-400']++; else if (t < 500) b['400-500']++; else b['500+']++; });
    return Object.entries(b).map(([r, c]) => ({ range: r, count: c }));
  }, [consultants]);

  const scatterData = consultants.map(c => ({ name: c.name, tariff: c.tariff, fees: c.fees, margin: c.coefMargin, position: c.position }));

  const thisMonthLabel = `${MONTH_NAMES[currentMonthIdx]} ${currentYear}`;
  const thisMonthBonus = useMemo(() => {
    const row = monthly.find(m => m.month === thisMonthLabel);
    return row ? row.totalBonus : 0;
  }, [monthly, thisMonthLabel]);
  const qtdBonus = useMemo(() => {
    const qStart = Math.floor(currentMonthIdx / 3) * 3;
    const labels = MONTH_NAMES.slice(qStart, currentMonthIdx + 1).map(m => `${m} ${currentYear}`);
    return monthly.filter(m => labels.includes(m.month)).reduce((s, r) => s + r.totalBonus, 0);
  }, [monthly, currentMonthIdx, currentYear]);
  const ytdBonus = useMemo(() => {
    const labels = MONTH_NAMES.slice(0, currentMonthIdx + 1).map(m => `${m} ${currentYear}`);
    return monthly.filter(m => labels.includes(m.month)).reduce((s, r) => s + r.totalBonus, 0);
  }, [monthly, currentMonthIdx, currentYear]);

  const bonusData = monthly.map(m => ({ month: m.month, bonus: m.totalBonus, tenureBonuses: m.tenureBonusAmount, quarterlyBonuses: m.quarterlyBonusAmount }));

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
    const totalBilling = momYear === currentYear && forecast != null
      ? forecast.projectedTotal
      : rows.reduce((s, r) => s + r.monthlyBilling, 0);
    const growthValues = rows.map(r => r.momGrowthPct).filter((v): v is number => v != null);
    const avgGrowth = growthValues.length > 0 ? growthValues.reduce((s, v) => s + v, 0) / growthValues.length : null;
    return { avgDaily, totalBilling, avgGrowth };
  }, [momData, momYear, currentYear, forecast]);

  // REQ-BBD-005
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

  // REQ-BBD-003
  const availableYears = useMemo(() => {
    const years = new Set<number>();
    monthly.forEach(m => {
      const parts = m.month.split(' ');
      if (parts.length > 1) years.add(parseInt(parts[parts.length - 1]));
    });
    return Array.from(years).sort((a, b) => b - a);
  }, [monthly]);

  const yoyChartData = useMemo(() => {
    if (!yoy?.length) return [];
    return yoy.map(r => ({ year: String(r.year), annual: r.annual, headcount: r.headcount }));
  }, [yoy]);

  const nextYearProjection = useMemo(() => {
    if (!yoy?.length) return null;
    const last = yoy[yoy.length - 1];
    const growthRate = last.deltaPct != null ? last.deltaPct : 0;
    return {
      year: last.year + 1,
      daily: +(last.daily * (1 + growthRate)).toFixed(2),
      monthly: +(last.monthly * (1 + growthRate)).toFixed(2),
      annual: +(last.annual * (1 + growthRate)).toFixed(2),
      headcount: last.headcount,
      avgCoefPct: last.avgCoefPct,
    };
  }, [yoy]);

  if (loading) return <div className="p-5"><p className="text-muted-foreground"><FormattedMessage id="billing.loading" /></p></div>;
  if (!data) return <div className="p-5"><p className="text-muted-foreground"><FormattedMessage id="billing.noData" /></p></div>;

  return (
    <div className="p-5">
      {/* Cards Row */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4 mb-6">
        <Card className="border-l-4 border-l-amber-400">
          <CardContent className="p-5">
            <div className="flex items-start justify-between mb-3">
              <p className="text-xs font-medium text-amber-600 uppercase tracking-wider"><FormattedMessage id="billing.managerBonus"/></p>
              <div className="p-2 rounded-lg bg-amber-50"><Euro className="size-4 text-amber-600"/></div>
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div className="flex flex-col items-center justify-center border-r border-amber-200/60 pr-4">
                <p className="text-2xl font-bold">{F(thisMonthBonus)} €</p>
                <p className="text-[10px] text-muted-foreground">este mes</p>
              </div>
              <div className="flex flex-col justify-center gap-2 pl-2">
                <div>
                  <p className="text-lg font-bold">{F(qtdBonus)} €</p>
                  <p className="text-[9px] text-muted-foreground">QTD</p>
                </div>
                <div className="border-t border-amber-200/60 pt-2">
                  <p className="text-lg font-bold">{F(ytdBonus)} €</p>
                  <p className="text-[9px] text-muted-foreground">YTD</p>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card className="border-l-4 border-l-blue-400">
          <CardContent className="p-5">
            <div className="flex items-start justify-between mb-3">
              <p className="text-xs font-medium text-blue-600 uppercase tracking-wider"><FormattedMessage id="billing.title"/></p>
              <div className="p-2 rounded-lg bg-blue-50"><Euro className="size-4 text-blue-600"/></div>
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div className="flex flex-col items-center justify-center border-r border-blue-200/60 pr-4">
                <p className="text-2xl font-bold">€<FormattedNumber value={data.annual} minimumFractionDigits={2} maximumFractionDigits={2} /></p>
                <p className="text-[10px] text-muted-foreground"><FormattedMessage id="billing.annual"/></p>
              </div>
              <div className="flex flex-col justify-center gap-2 pl-2">
                <div>
                  <p className="text-lg font-bold">€<FormattedNumber value={data.daily} minimumFractionDigits={2} maximumFractionDigits={2} /></p>
                  <p className="text-[9px] text-muted-foreground"><FormattedMessage id="billing.daily"/></p>
                </div>
                <div className="border-t border-blue-200/60 pt-2">
                  <p className="text-lg font-bold">€<FormattedNumber value={data.monthly} minimumFractionDigits={2} maximumFractionDigits={2} /></p>
                  <p className="text-[9px] text-muted-foreground"><FormattedMessage id="billing.monthly"/></p>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Annual Forecast Cards */}
      {forecast && (
        <div className="grid grid-cols-1 sm:grid-cols-3 lg:grid-cols-8 gap-4 mb-6">
          <Card className="border-l-4 border-l-indigo-400 shadow-sm lg:col-span-1">
            <CardContent className="p-4">
              <div className="flex items-start justify-between mb-2">
                <p className="text-[10px] font-medium text-indigo-600 uppercase tracking-wider"><FormattedMessage id="report.forecast.currentDailyBilling" /></p>
                <div className="p-1.5 rounded-lg bg-indigo-50"><Euro className="size-3.5 text-indigo-600" /></div>
              </div>
              <p className="text-2xl font-bold">€{F(forecast.currentDailyBilling)}</p>
            </CardContent>
          </Card>
          <Card className="border-l-4 border-l-sky-400 shadow-sm lg:col-span-1">
            <CardContent className="p-4">
              <div className="flex items-start justify-between mb-2">
                <p className="text-[10px] font-medium text-sky-600 uppercase tracking-wider"><FormattedMessage id="report.forecast.ytdWorkingDays" /></p>
                <div className="p-1.5 rounded-lg bg-sky-50"><CalendarDays className="size-3.5 text-sky-600" /></div>
              </div>
              <p className="text-2xl font-bold">{forecast.ytdWorkingDays}</p>
            </CardContent>
          </Card>
          <Card className="border-l-4 border-l-emerald-400 shadow-sm lg:col-span-2">
            <CardContent className="p-4">
              <div className="flex items-start justify-between mb-2">
                <p className="text-[10px] font-medium text-emerald-600 uppercase tracking-wider"><FormattedMessage id="report.forecast.ytdBilling" /></p>
                <div className="p-1.5 rounded-lg bg-emerald-50"><Euro className="size-3.5 text-emerald-600" /></div>
              </div>
              <p className="text-2xl font-bold">€{forecast.ytdBilling.toLocaleString(undefined, { minimumFractionDigits: 0, maximumFractionDigits: 0 })}</p>
              {forecast.ytdGrowthPct != null && (
                <div className={`inline-flex items-center gap-0.5 mt-1 text-xs font-semibold px-1.5 py-0.5 rounded ${forecast.ytdGrowthPct >= 0 ? 'bg-emerald-100 text-emerald-700' : 'bg-red-100 text-red-700'}`}>
                  <ArrowUpFromLine className={`size-3 ${forecast.ytdGrowthPct >= 0 ? '' : 'rotate-180'}`} />
                  {forecast.ytdGrowthPct >= 0 ? '+' : ''}{forecast.ytdGrowthPct.toFixed(1)}%
                </div>
              )}
            </CardContent>
          </Card>
          <Card className="border-l-4 border-l-amber-400 shadow-sm lg:col-span-1">
            <CardContent className="p-4">
              <div className="flex items-start justify-between mb-2">
                <p className="text-[10px] font-medium text-amber-600 uppercase tracking-wider"><FormattedMessage id="report.forecast.remainingDays" /></p>
                <div className="p-1.5 rounded-lg bg-amber-50"><ArrowRight className="size-3.5 text-amber-600" /></div>
              </div>
              <p className="text-2xl font-bold">{forecast.remainingWorkingDays}</p>
            </CardContent>
          </Card>
          <Card className="border-l-4 border-l-violet-400 shadow-sm lg:col-span-2">
            <CardContent className="p-4">
              <div className="flex items-start justify-between mb-2">
                <p className="text-[10px] font-medium text-violet-600 uppercase tracking-wider"><FormattedMessage id="report.forecast.projectedRemaining" /></p>
                <div className="p-1.5 rounded-lg bg-violet-50"><TrendingUp className="size-3.5 text-violet-600" /></div>
              </div>
              <p className="text-xl font-bold">€{forecast.projectedRemaining.toLocaleString(undefined, { minimumFractionDigits: 0, maximumFractionDigits: 0 })}</p>
              <p className="text-[10px] text-violet-500 mt-0.5 font-medium">
                <ArrowUpFromLine className="size-2.5 inline mr-0.5" />
                avg {forecast.avgGrowthRatePct != null ? (forecast.avgGrowthRatePct >= 0 ? '+' : '') + forecast.avgGrowthRatePct.toFixed(1) : '0.0'}% MoM
              </p>
            </CardContent>
          </Card>
          <Card className="border-l-4 border-l-emerald-500 shadow-sm bg-emerald-50/40 lg:col-span-1">
            <CardContent className="p-4">
              <div className="flex items-start justify-between mb-2">
                <p className="text-[10px] font-medium text-emerald-700 uppercase tracking-wider"><FormattedMessage id="report.forecast.projectedTotal" /></p>
                <div className="p-1.5 rounded-lg bg-emerald-100"><Goal className="size-3.5 text-emerald-700" /></div>
              </div>
              <p className="text-2xl font-bold text-emerald-700">€{forecast.projectedTotal.toLocaleString(undefined, { minimumFractionDigits: 0, maximumFractionDigits: 0 })}</p>
            </CardContent>
          </Card>
        </div>
      )}

      {/* Charts Row */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
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
                <Tooltip
                  formatter={(value: number, name: string) => {
                    if (name === 'momGrowthPct') return [`${value >= 0 ? '+' : ''}${value.toFixed(1)}%`, 'MoM Δ'];
                    return [`€${F(value)}`, 'Monthly Billing'];
                  }}
                />
                <Line yAxisId="left" type="monotone" dataKey="monthlyBilling" stroke="#10b981" strokeWidth={2.5} dot={true} name="monthlyBilling" />
                <Line yAxisId="right" type="monotone" dataKey="momGrowthPct" stroke="#f59e0b" strokeWidth={2} dot={false} name="momGrowthPct" connectNulls />
              </LineChart>
            ) : <p className="text-sm text-muted-foreground text-center py-10">No billing data</p>}
          </ResponsiveContainer></CardContent></Card>
        <Card><CardHeader className="pb-2"><CardTitle className="text-base flex items-center gap-2"><BarChart3 className="size-4 text-amber-600" /><FormattedMessage id="billing.bonusPerMonth" /></CardTitle></CardHeader>
          <CardContent><ResponsiveContainer width="100%" height={240}><BarChart data={bonusData}><CartesianGrid strokeDasharray="3 3" className="stroke-muted" /><XAxis dataKey="month" tick={{ fontSize: 11 }} /><YAxis tick={{ fontSize: 11 }} /><Tooltip formatter={(v: number) => `€${F(v)}`} /><Bar dataKey="bonus" fill="#f59e0b" radius={[4,4,0,0]} stackId="bonus" name="Manager Bonus" /><Bar dataKey="tenureBonuses" fill="#10b981" radius={[4,4,0,0]} stackId="bonus" name="Tenure Bonuses" /><Bar dataKey="quarterlyBonuses" fill="#0ea5e9" radius={[4,4,0,0]} stackId="bonus" name="Quarterly Bonuses" /></BarChart></ResponsiveContainer></CardContent></Card>
        <Card><CardHeader className="pb-2"><CardTitle className="text-sm"><FormattedMessage id="billing.tariffDistribution" /></CardTitle></CardHeader>
          <CardContent><ResponsiveContainer width="100%" height={220}><BarChart data={tariffBuckets}><CartesianGrid strokeDasharray="3 3" className="stroke-muted" /><XAxis dataKey="range" tick={{ fontSize: 11 }} /><YAxis allowDecimals={false} tick={{ fontSize: 11 }} /><Tooltip /><Bar dataKey="count" fill="#8b5cf6" radius={[4,4,0,0]} /></BarChart></ResponsiveContainer></CardContent></Card>
        <Card><CardHeader className="pb-2"><CardTitle className="text-sm"><FormattedMessage id="billing.tariffVsCoef" /> — <FormattedMessage id="billing.allTime" /></CardTitle></CardHeader>
          <CardContent><ResponsiveContainer width="100%" height={220}><ScatterChart margin={{ top: 5, right: 20, bottom: 5, left: 0 }}><CartesianGrid strokeDasharray="3 3" className="stroke-muted" /><XAxis type="number" dataKey="tariff" unit="€" tick={{ fontSize: 11 }} /><YAxis type="number" dataKey="fees" unit="€" tick={{ fontSize: 11 }} /><Tooltip /><Scatter data={scatterData} fill="#6366f1" /></ScatterChart></ResponsiveContainer></CardContent></Card>
      </div>

      {/* MoM Billing + Bonus Breakdown side by side */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">

        {/* MoM Billing Increment */}
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
                      <p className="text-xs text-amber-700 font-medium">Avg Daily Billing{momYear === currentYear && momData?.rows.some(r => r.projected) ? ' (proj.)' : ''}</p>
                      <p className="text-lg font-bold text-amber-800">€{F(momSummary.avgDaily)}</p>
                    </div>
                    <div className="bg-emerald-50 rounded-md p-3 border border-emerald-200">
                      <p className="text-xs text-emerald-700 font-medium">Total Billing{momYear === currentYear && momData?.rows.some(r => r.projected) ? ' (proj.)' : ''}</p>
                      <p className="text-lg font-bold text-emerald-800">€{F(momSummary.totalBilling)}</p>
                    </div>
                    <div className="bg-sky-50 rounded-md p-3 border border-sky-200">
                      <p className="text-xs text-sky-700 font-medium">Avg MoM Growth{momYear === currentYear && momData?.rows.some(r => r.projected) ? ' (proj.)' : ''}</p>
                      <p className={`text-lg font-bold ${momSummary.avgGrowth != null && momSummary.avgGrowth >= 0 ? 'text-emerald-800' : 'text-red-700'}`}>
                        {momSummary.avgGrowth != null ? `${momSummary.avgGrowth >= 0 ? '+' : ''}${momSummary.avgGrowth.toFixed(1)}%` : '-'}
                      </p>
                    </div>
                  </div>
                )}
                <div className="overflow-auto mt-4">
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

        {/* Bonus Breakdown — REQ-BBD-001 through REQ-BBD-006 */}
        <Card>
          <CardHeader className="pb-3">
            <CardTitle className="text-base flex items-center gap-2">
              <BarChart3 className="size-4 text-amber-600" />
              <FormattedMessage id="billing.bonusBreakdown" />
              <button
                onClick={handleRefreshBonus}
                disabled={refreshingBonus}
                className="ml-auto mr-2 p-1 rounded hover:bg-muted/50 disabled:opacity-50"
                title="Refresh breakdown data"
              >
                <RefreshCw className={`size-3.5 ${refreshingBonus ? 'animate-spin' : ''}`} />
              </button>
              <select
                className="ml-2 border rounded px-2 py-1 text-xs bg-background"
                value={bonusYear ?? ''}
                onChange={e => setBonusYear(e.target.value ? Number(e.target.value) : undefined)}
              >
                <option value=""><FormattedMessage id="billing.allYears" /></option>
                {availableYears.map(y => (
                  <option key={y} value={y}>{y}</option>
                ))}
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
                          <>{r.tenureAmount > 0 && <span>€${F(r.tenureAmount)}</span>}{r.projectedTenureAmount > 0 && <><span className="text-amber-600"> + €${F(r.projectedTenureAmount)}</span></>}</>
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

      </div>

      {/* YoY Table + Chart + Projection */}
      {yoy.length > 0 && (
        <Card className="mt-6">
          <CardHeader className="pb-3">
            <CardTitle className="text-base"><FormattedMessage id="report.section.yoy" /></CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              {yoyChartData.length > 1 && (
                <div className="h-full min-h-[260px]">
                  <ResponsiveContainer width="100%" height={300}>
                    <BarChart data={yoyChartData}>
                      <CartesianGrid strokeDasharray="3 3" className="stroke-muted" />
                      <XAxis dataKey="year" tick={{ fontSize: 11 }} />
                      <YAxis tick={{ fontSize: 11 }} />
                      <Tooltip formatter={(v: number) => `€${F(v)}`} />
                      <Bar dataKey="annual" fill="#3b82f6" radius={[4,4,0,0]} name="Annual Revenue" />
                    </BarChart>
                  </ResponsiveContainer>
                </div>
              )}
              <div className="overflow-auto max-h-[300px]">
                <table className="w-full text-sm">
                  <thead>
                    <tr className="border-b bg-muted/50">
                      <th className="text-left p-3 font-medium"><FormattedMessage id="report.yoy.year" /></th>
                      <th className="text-right p-3 font-medium"><FormattedMessage id="report.yoy.headcount" /></th>
                      <th className="text-right p-3 font-medium"><FormattedMessage id="report.yoy.daily" /></th>
                      <th className="text-right p-3 font-medium"><FormattedMessage id="report.yoy.monthly" /></th>
                      <th className="text-right p-3 font-medium"><FormattedMessage id="report.yoy.annual" /></th>
                      <th className="text-right p-3 font-medium"><FormattedMessage id="report.yoy.hires" /></th>
                      <th className="text-right p-3 font-medium"><FormattedMessage id="report.yoy.terminations" /></th>
                      <th className="text-right p-3 font-medium"><FormattedMessage id="report.yoy.avgCoef" /></th>
                      <th className="text-right p-3 font-medium"><FormattedMessage id="report.yoy.managerBonus" /></th>
                      <th className="text-right p-3 font-medium"><FormattedMessage id="report.yoy.delta" /></th>
                      <th className="text-right p-3 font-medium"><FormattedMessage id="report.yoy.deltaPct" /></th>
                    </tr>
                  </thead>
                  <tbody>
                    {yoy.map((r) => (
                      <tr key={r.year} className={`border-b hover:bg-muted/30 ${r.delta != null && r.delta >= 0 ? 'text-emerald-600' : r.delta != null ? 'text-red-500' : ''}`}>
                        <td className="p-3 font-medium whitespace-nowrap">{r.year}</td>
                        <td className="p-3 text-right whitespace-nowrap">{r.headcount}</td>
                        <td className="p-3 text-right whitespace-nowrap">€{r.daily.toFixed(2)}</td>
                        <td className="p-3 text-right whitespace-nowrap">€{r.monthly.toFixed(2)}</td>
                        <td className="p-3 text-right font-semibold whitespace-nowrap">€{r.annual.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</td>
                        <td className="p-3 text-right whitespace-nowrap">{r.hires}</td>
                        <td className="p-3 text-right whitespace-nowrap">{r.terminations}</td>
                        <td className="p-3 text-right whitespace-nowrap">{(r.avgCoefPct * 100).toFixed(2)}%</td>
                        <td className="p-3 text-right whitespace-nowrap">{r.totalManagerBonus != null && r.totalManagerBonus > 0 ? `€${r.totalManagerBonus.toFixed(2)}` : '—'}</td>
                        <td className="p-3 text-right font-medium whitespace-nowrap">{r.delta != null ? `€${r.delta.toFixed(2)}` : '—'}</td>
                        <td className="p-3 text-right font-medium whitespace-nowrap">{r.deltaPct != null ? `${(r.deltaPct * 100).toFixed(2)}%` : '—'}</td>
                      </tr>
                    ))}
                    {nextYearProjection && (
                      <tr className="border-t-2 font-semibold bg-primary/5 text-primary">
                        <td className="p-3 font-medium whitespace-nowrap">{nextYearProjection.year} (proj.)</td>
                        <td className="p-3 text-right whitespace-nowrap">{nextYearProjection.headcount}</td>
                        <td className="p-3 text-right whitespace-nowrap">€{nextYearProjection.daily.toFixed(2)}</td>
                        <td className="p-3 text-right whitespace-nowrap">€{nextYearProjection.monthly.toFixed(2)}</td>
                        <td className="p-3 text-right font-semibold whitespace-nowrap">€{nextYearProjection.annual.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</td>
                        <td className="p-3 text-right whitespace-nowrap" colSpan={6}></td>
                      </tr>
                    )}
                  </tbody>
                </table>
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      <RevenueLeaderboard consultants={consultants} onRowClick={() => { window.location.hash = '#/consultants'; }} />
    </div>
  );
}
