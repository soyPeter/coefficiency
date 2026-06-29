import { useEffect, useState, Fragment } from 'react';
import { FormattedMessage } from 'react-intl';
import { Download, Building2, TrendingUp, AlertTriangle } from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { fetchClientSummaries, fetchClientFinancial, fetchConsultants } from '@/api';
import type { ClientSummary, Consultant } from '@/types';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';

interface ClientFinancial { client: string; consultants: number; daily: number; monthly: number; annual: number; fees: number; avgCoef: number; margin: number; bonus: number; avgTenureDays: number; maxTenureDays: number; }

const F = (n: number) => n.toLocaleString('es-ES', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
const P = (n: number) => (n * 100).toFixed(1);

const fmtC = (n: number, d = 2) => n.toFixed(d).replace('.', ',');
const exportRevenueCsv = (data: ClientFinancial[], totalD: number) => {
  const h = 'Client;Consultants;€/Consultant;Daily;Monthly;Fees;AvgCOEF;Margin;Margin%;AvgTenureDays;Bonus;%ofTotalDaily\n';
  const csv = '\uFEFF' + h + data.map(d => {
    const perCap = d.consultants > 0 ? d.daily / d.consultants : 0;
    const margPct = d.daily > 0 ? (d.margin / d.daily) * 100 : 0;
    const concPct = totalD > 0 ? (d.daily / totalD) * 100 : 0;
    return `${d.client};${d.consultants};${fmtC(perCap)};${fmtC(d.daily)};${fmtC(d.monthly)};${fmtC(d.fees)};${fmtC(d.avgCoef * 100, 1)};${fmtC(d.margin)};${fmtC(margPct, 1)};${Math.round(d.avgTenureDays)};${fmtC(d.bonus)};${fmtC(concPct, 1)}`;
  }).join('\n');
  const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a'); a.href = url; a.download = 'revenue-concentration.csv'; a.click(); URL.revokeObjectURL(url);
};

export default function ClientsPage() {
  const [clients, setClients] = useState<ClientSummary[]>([]);
  const [financial, setFinancial] = useState<ClientFinancial[]>([]);
  const [consultants, setConsultants] = useState<Consultant[]>([]);
  const [loading, setLoading] = useState(true);
  const [expandedClient, setExpandedClient] = useState<string | null>(null);
  const [threshold, setThreshold] = useState(0.15);

  useEffect(() => {
    Promise.all([fetchClientSummaries().then(setClients), fetchClientFinancial().then(setFinancial), fetchConsultants().then(setConsultants)])
      .finally(() => setLoading(false));
    import('@/api').then(({ request }) => request<any>('/fiscal').then(d => setThreshold(d.coefAlertThreshold ?? 0.15)).catch(() => {}));
  }, []);

  if (loading) return <div className="p-5"><p><FormattedMessage id="clients.loading" /></p></div>;

  return (
    <div className="p-5">
      <div className="flex items-center justify-between mb-6">
        <div><h1 className="text-2xl font-bold"><FormattedMessage id="clients.title" /></h1><p className="text-sm text-muted-foreground"><FormattedMessage id="clients.subtitle" /></p></div>
        {financial.length > 0 && <Button variant="outline" size="sm" onClick={() => {
          const totalD = financial.reduce((s, f) => s + f.daily, 0);
          exportRevenueCsv(financial, totalD);
        }}><Download className="size-3.5 mr-1" /> <FormattedMessage id="common.exportCsv" /></Button>}
      </div>

      {financial.length > 0 && (
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-4 mb-6">
          <Card className="border-l-4 border-l-blue-400">
            <CardContent className="p-5">
              <div className="flex items-start justify-between mb-2">
                <p className="text-xs font-medium text-blue-600 uppercase tracking-wider"><FormattedMessage id="clients.client"/></p>
                <div className="p-2 rounded-lg bg-blue-50"><Building2 className="size-4 text-blue-600"/></div>
              </div>
              <p className="text-2xl font-bold">{financial.length}</p>
              <p className="text-xs text-muted-foreground mt-1">{financial.reduce((s, f) => s + f.consultants, 0)} consultores</p>
            </CardContent>
          </Card>
          <Card className="border-l-4 border-l-emerald-400">
            <CardContent className="p-5">
              <div className="flex items-start justify-between mb-2">
                <p className="text-xs font-medium text-emerald-600 uppercase tracking-wider">Margen Medio</p>
                <div className="p-2 rounded-lg bg-emerald-50"><TrendingUp className="size-4 text-emerald-600"/></div>
              </div>
              <p className="text-2xl font-bold">{(financial.reduce((s, f) => s + (f.daily > 0 ? (f.margin / f.daily) * 100 : 0), 0) / financial.length).toFixed(1)}%</p>
              <p className="text-xs text-muted-foreground mt-1">{financial.filter(f => f.daily > 0 && (f.margin / f.daily) * 100 >= 25).length} clientes sobre 25%</p>
            </CardContent>
          </Card>
          <Card className="border-l-4 border-l-amber-400">
            <CardContent className="p-5">
              <div className="flex items-start justify-between mb-2">
                <p className="text-xs font-medium text-amber-600 uppercase tracking-wider">Top Cliente</p>
                <div className="p-2 rounded-lg bg-amber-50"><AlertTriangle className="size-4 text-amber-600"/></div>
              </div>
              {(() => {
                const top = [...financial].sort((a, b) => b.daily - a.daily)[0];
                const totalD = financial.reduce((s, f) => s + f.daily, 0);
                const pct = totalD > 0 ? (top.daily / totalD) * 100 : 0;
                return <><p className="text-lg font-bold truncate">{top.client}</p><p className="text-xs text-muted-foreground mt-1">{F(top.daily)}€/día ({pct.toFixed(0)}% del total)</p></>;
              })()}
            </CardContent>
          </Card>
        </div>
      )}

      {financial.length > 0 && (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
          <Card><CardHeader className="pb-2"><CardTitle className="text-sm"><FormattedMessage id="clients.dailyBillingByClient" /></CardTitle></CardHeader>
            <CardContent><ResponsiveContainer width="100%" height={280}><BarChart data={[...financial].sort((a,b)=>b.daily-a.daily)} layout="vertical"><CartesianGrid strokeDasharray="3 3" className="stroke-muted" /><XAxis type="number" tick={{ fontSize: 11 }} /><YAxis type="category" dataKey="client" tick={{ fontSize: 11 }} width={80} /><Tooltip formatter={(v: number) => `€${F(v)}`} /><Bar dataKey="daily" fill="#6366f1" radius={[0,4,4,0]} /></BarChart></ResponsiveContainer></CardContent></Card>
          <Card><CardHeader className="pb-2"><CardTitle className="text-sm"><FormattedMessage id="clients.coefByClient" /></CardTitle></CardHeader>
            <CardContent><ResponsiveContainer width="100%" height={280}><BarChart data={[...financial].sort((a,b)=>b.avgCoef-a.avgCoef)} layout="vertical"><CartesianGrid strokeDasharray="3 3" className="stroke-muted" /><XAxis type="number" tick={{ fontSize: 11 }} unit="%" tickFormatter={v=>`${(v*100).toFixed(0)}%`} /><YAxis type="category" dataKey="client" tick={{ fontSize: 11 }} width={80} /><Tooltip formatter={(v: number) => `${P(v)}%`} /><Bar dataKey="avgCoef" fill="#10b981" radius={[0,4,4,0]} /></BarChart></ResponsiveContainer></CardContent></Card>
        </div>
      )}

      <Card>
        <CardHeader className="pb-2"><CardTitle className="text-sm"><FormattedMessage id="clients.revenueConcentration" /></CardTitle></CardHeader>
        <CardContent>
          <div className="overflow-auto"><table className="w-full text-xs">
            <thead><tr className="border-b bg-muted/30"><th className="text-left p-2"><FormattedMessage id="clients.client" /></th><th className="text-right p-2"><FormattedMessage id="clients.consultants" /></th><th className="text-right p-2">€/Cons.</th><th className="text-right p-2"><FormattedMessage id="billing.daily" /></th><th className="text-right p-2"><FormattedMessage id="common.monthly" /></th><th className="text-right p-2"><FormattedMessage id="common.fees" /></th><th className="text-right p-2"><FormattedMessage id="billing.avgCoef" /></th><th className="text-right p-2"><FormattedMessage id="common.margin" /></th><th className="text-right p-2">Margen%</th><th className="text-right p-2">Antig.</th><th className="text-right p-2"><FormattedMessage id="billing.managerBonus" /></th></tr></thead>
            <tbody>{[...financial].sort((a,b) => b.daily - a.daily || b.consultants - a.consultants).map((f,i) => {
              const perCap = f.consultants > 0 ? f.daily / f.consultants : 0;
              const marginPct = f.daily > 0 ? (f.margin / f.daily) * 100 : 0;
              const color = marginPct > 25 ? 'bg-emerald-100' : marginPct > 15 ? 'bg-emerald-50/50' : '';
              return (<Fragment key={f.client}>
                <tr className={`border-b hover:bg-muted/30 cursor-pointer ${color}`} onClick={() => setExpandedClient(expandedClient === f.client ? null : f.client)}>
                  <td className="p-2 font-medium">{f.client}</td><td className="p-2 text-right">{f.consultants}</td><td className="p-2 text-right">{F(perCap)}€</td><td className="p-2 text-right">{F(f.daily)}€</td><td className="p-2 text-right">{F(f.monthly)}€</td><td className="p-2 text-right">{F(f.fees)}€</td><td className="p-2 text-right">{P(f.avgCoef)}%</td><td className="p-2 text-right">{F(f.margin)}€</td><td className="p-2 text-right font-semibold">{marginPct.toFixed(1)}%</td><td className="p-2 text-right">{f.avgTenureDays > 0 ? `${Math.round(f.avgTenureDays)}d` : '-'}</td><td className="p-2 text-right">{F(f.bonus)}€</td>
                </tr>
                {expandedClient === f.client && <tr><td colSpan={11} className="p-0"><div className="bg-muted/20 p-3"><table className="w-full text-xs">
                  <thead><tr className="border-b"><th className="text-left p-1"><FormattedMessage id="consultants.name" /></th><th className="text-left p-1"><FormattedMessage id="consultants.position" /></th><th className="text-right p-1"><FormattedMessage id="consultants.dailyRate" /></th><th className="text-right p-1"><FormattedMessage id="consultants.coefPct" /></th><th className="text-right p-1"><FormattedMessage id="common.margin" /></th></tr></thead>
                  <tbody>{consultants.filter(co=>co.client===f.client).map(co => (<tr key={co.id} className="border-b"><td className="p-1 font-medium">{co.name}</td><td className="p-1">{co.position}</td><td className="p-1 text-right">{co.tariff}€</td><td className="p-1 text-right">{co.coefPercentage > 0 ? P(co.coefPercentage) : (co.coef * 100).toFixed(1)}%</td><td className="p-1 text-right">{F(co.coefMargin)}€</td></tr>))}</tbody>
                </table></div></td></tr>}
              </Fragment>);
            })}</tbody></table></div>
        </CardContent>
      </Card>
    </div>
  );
}
