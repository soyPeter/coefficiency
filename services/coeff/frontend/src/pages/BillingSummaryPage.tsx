import { useEffect, useState, useMemo } from 'react';
import { Euro, BarChart3, LineChart, TrendingUp } from 'lucide-react';
import { FormattedMessage, FormattedNumber, useIntl } from 'react-intl';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { fetchBillingSummary, fetchBillingMonthly, fetchConsultants } from '@/api';
import type { BillingSummary } from '@/types';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, ScatterChart, Scatter, ReferenceLine } from 'recharts';

interface MonthlyRow { month: string; hires: number; terminations: number; avgCoef: number; totalBonus: number; }
interface ConsultantBrief { id: number; name: string; tariff: number; coefPercentage: number; position: string; coefMargin: number; managerBonus: number; fees: number; client: string; }

const F = (n: number) => n.toLocaleString('es-ES', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
const P = (n: number) => (n * 100).toFixed(1);

export default function BillingSummaryPage() {
  const intl = useIntl();
  const [data, setData] = useState<BillingSummary | null>(null);
  const [monthly, setMonthly] = useState<MonthlyRow[]>([]);
  const [consultants, setConsultants] = useState<ConsultantBrief[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    Promise.all([fetchBillingSummary().then(setData), fetchBillingMonthly().then(setMonthly), fetchConsultants().then(setConsultants)])
      .finally(() => setLoading(false));
  }, []);

  const tariffBuckets = useMemo(() => {
    const b: Record<string, number> = { '100-200': 0, '200-300': 0, '300-400': 0, '400-500': 0, '500+': 0 };
    consultants.forEach(c => { const t = c.tariff; if (t < 200) b['100-200']++; else if (t < 300) b['200-300']++; else if (t < 400) b['300-400']++; else if (t < 500) b['400-500']++; else b['500+']++; });
    return Object.entries(b).map(([r, c]) => ({ range: r, count: c }));
  }, [consultants]);

  const scatterData = consultants.map(c => ({ name: c.name, tariff: c.tariff, fees: c.fees, margin: c.coefMargin, position: c.position }));
  const leaderboard = useMemo(() => [...consultants].sort((a, b) => b.fees - a.fees), [consultants]);
  const coefData = monthly.map(m => ({ month: m.month, coef: +(m.avgCoef * 100).toFixed(1) }));
  const bonusData = monthly.map(m => ({ month: m.month, bonus: m.totalBonus }));

  if (loading) return <div className="p-5"><p className="text-muted-foreground"><FormattedMessage id="billing.loading" /></p></div>;
  if (!data) return <div className="p-5"><p className="text-muted-foreground"><FormattedMessage id="billing.noData" /></p></div>;

  return (
    <div className="p-5">
      <h1 className="text-2xl font-bold mb-6"><FormattedMessage id="stats.title" /></h1>

      {/* Aggregates */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        {[
          [intl.formatMessage({ id: 'billing.totalFees' }), `€${F(data.totalFees)}`, 'text-foreground'],
          [intl.formatMessage({ id: 'billing.avgCoef' }), `${P(data.avgCoefPct)}%`, 'text-emerald-700'],
          [intl.formatMessage({ id: 'billing.totalCoefMargin' }), `€${F(data.totalCoefMargin)}`, 'text-foreground'],
          [intl.formatMessage({ id: 'billing.totalManagerBonus' }), `€${F(data.totalManagerBonus * 12)}`, 'text-amber-700'],
        ].map(([label, value, color], i) => (
          <Card key={i}><CardContent className="p-4"><p className="text-xs text-muted-foreground">{label}</p><p className={`text-xl font-bold ${color}`}>{value}</p></CardContent></Card>
        ))}
      </div>

      {/* Billing Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
        {[['billing.daily', 'emerald', data.daily, data.coefDaysMonth], ['billing.monthly', 'blue', data.monthly, data.coefDaysYear], ['billing.annual', 'purple', data.annual, null]].map(([id, color, value, day], i) => (
          <Card key={i} className={`bg-${color}-50 dark:bg-${color}-950/20 border-${color}-200`}>
            <CardContent className="p-5"><div className="flex items-center gap-2 mb-1"><Euro className={`size-4 text-${color}-600`} /><p className={`text-sm font-medium text-${color}-700`}><FormattedMessage id={id as string} /></p></div><p className={`text-3xl font-bold text-${color}-700`}>€<FormattedNumber value={value} minimumFractionDigits={2} maximumFractionDigits={2} /></p></CardContent>
          </Card>
        ))}
      </div>

      {/* Charts Row */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
        <Card><CardHeader className="pb-2"><CardTitle className="text-base flex items-center gap-2"><LineChart className="size-4 text-blue-600" /><FormattedMessage id="billing.coefPerMonth" /></CardTitle></CardHeader>
          <CardContent><ResponsiveContainer width="100%" height={240}><BarChart data={coefData}><CartesianGrid strokeDasharray="3 3" className="stroke-muted" /><XAxis dataKey="month" tick={{ fontSize: 11 }} /><YAxis tick={{ fontSize: 11 }} unit="%" /><Tooltip formatter={(v: number) => `${v}%`} /><Bar dataKey="coef" fill="#3b82f6" radius={[4,4,0,0]} /></BarChart></ResponsiveContainer></CardContent></Card>
        <Card><CardHeader className="pb-2"><CardTitle className="text-base flex items-center gap-2"><BarChart3 className="size-4 text-amber-600" /><FormattedMessage id="billing.bonusPerMonth" /></CardTitle></CardHeader>
          <CardContent><ResponsiveContainer width="100%" height={240}><BarChart data={bonusData}><CartesianGrid strokeDasharray="3 3" className="stroke-muted" /><XAxis dataKey="month" tick={{ fontSize: 11 }} /><YAxis tick={{ fontSize: 11 }} /><Tooltip formatter={(v: number) => `€${F(v)}`} /><Bar dataKey="bonus" fill="#f59e0b" radius={[4,4,0,0]} /></BarChart></ResponsiveContainer></CardContent></Card>
      </div>

      {/* Scatter + Tariff */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
        <Card><CardHeader className="pb-2"><CardTitle className="text-sm"><FormattedMessage id="billing.tariffDistribution" /></CardTitle></CardHeader>
          <CardContent><ResponsiveContainer width="100%" height={220}><BarChart data={tariffBuckets}><CartesianGrid strokeDasharray="3 3" className="stroke-muted" /><XAxis dataKey="range" tick={{ fontSize: 11 }} /><YAxis allowDecimals={false} tick={{ fontSize: 11 }} /><Tooltip /><Bar dataKey="count" fill="#8b5cf6" radius={[4,4,0,0]} /></BarChart></ResponsiveContainer></CardContent></Card>
        <Card><CardHeader className="pb-2"><CardTitle className="text-sm"><FormattedMessage id="billing.tariffVsCoef" /></CardTitle></CardHeader>
          <CardContent><ResponsiveContainer width="100%" height={220}><ScatterChart margin={{ top: 5, right: 20, bottom: 5, left: 0 }}><CartesianGrid strokeDasharray="3 3" className="stroke-muted" /><XAxis type="number" dataKey="tariff" unit="€" tick={{ fontSize: 11 }} /><YAxis type="number" dataKey="fees" unit="€" tick={{ fontSize: 11 }} /><Tooltip /><Scatter data={scatterData} fill="#6366f1" /></ScatterChart></ResponsiveContainer></CardContent></Card>
      </div>

      {/* Leaderboard */}
      <Card>
        <CardHeader className="pb-2"><CardTitle className="text-base flex items-center gap-2"><TrendingUp className="size-4 text-amber-600" /><FormattedMessage id="billing.leaderboard" /></CardTitle></CardHeader>
        <CardContent className="p-0"><div className="overflow-auto"><table className="w-full text-xs">
          <thead><tr className="border-b bg-muted/30"><th className="text-left p-2 w-8">#</th><th className="text-left p-2"><FormattedMessage id="consultants.name" /></th><th className="text-left p-2"><FormattedMessage id="consultants.client" /></th><th className="text-right p-2"><FormattedMessage id="consultants.dailyRate" /></th><th className="text-right p-2"><FormattedMessage id="billing.totalFees" /></th><th className="text-right p-2"><FormattedMessage id="consultants.coefPct" /></th><th className="text-right p-2"><FormattedMessage id="common.margin" /></th></tr></thead>
          <tbody>{leaderboard.map((c, i) => (
            <tr key={c.id} className="border-b hover:bg-muted/30"><td className="p-2 text-center text-base">{i === 0 ? '🥇' : i === 1 ? '🥈' : i === 2 ? '🥉' : <span className="text-muted-foreground">{i + 1}</span>}</td><td className="p-2 font-medium">{c.name}</td><td className="p-2 text-muted-foreground">{c.client}</td><td className="p-2 text-right">{c.tariff}€</td><td className="p-2 text-right font-semibold">{F(c.fees)}€</td><td className="p-2 text-right">{P(c.coefPercentage)}%</td><td className="p-2 text-right">{F(c.coefMargin)}€</td></tr>
          ))}</tbody></table></div></CardContent>
      </Card>
    </div>
  );
}
