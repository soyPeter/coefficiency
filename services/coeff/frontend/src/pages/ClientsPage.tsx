import { useEffect, useState, Fragment } from 'react';
import { FormattedMessage } from 'react-intl';
import { Download } from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { fetchClientSummaries, fetchClientFinancial, fetchConsultants } from '@/api';
import type { ClientSummary, Consultant } from '@/types';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart, Pie, Cell } from 'recharts';

interface ClientFinancial { client: string; consultants: number; daily: number; monthly: number; annual: number; fees: number; avgCoef: number; margin: number; bonus: number; avgTenureDays: number; maxTenureDays: number; }

const F = (n: number) => n.toLocaleString('es-ES', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
const P = (n: number) => (n * 100).toFixed(1);
const COLORS = ['#6366f1','#8b5cf6','#ec4899','#06b6d4','#10b981','#f59e0b','#ef4444','#3b82f6'];

const exportCSV = (data: ClientFinancial[]) => {
  const h = 'Client;Consultants;Daily;Monthly;Annual;Fees;AvgCOEF;Margin;Bonus;AvgTenure;MaxTenure\n';
  const u = window.URL.createObjectURL(new Blob([h + data.map(d => `${d.client};${d.consultants};€${F(d.daily)};€${F(d.monthly)};€${F(d.annual)};€${F(d.fees)};${P(d.avgCoef)}%;€${F(d.margin)};€${F(d.bonus)};${Math.round(d.avgTenureDays)};${d.maxTenureDays}`).join('\n')], { type: 'text/csv' }));
  const a = document.createElement('a'); a.href = u; a.download = 'client-financials.csv'; a.click(); window.URL.revokeObjectURL(u);
};

export default function ClientsPage() {
  const [clients, setClients] = useState<ClientSummary[]>([]);
  const [financial, setFinancial] = useState<ClientFinancial[]>([]);
  const [consultants, setConsultants] = useState<Consultant[]>([]);
  const [loading, setLoading] = useState(true);
  const [expandedClient, setExpandedClient] = useState<string | null>(null);

  useEffect(() => {
    Promise.all([fetchClientSummaries().then(setClients), fetchClientFinancial().then(setFinancial), fetchConsultants().then(setConsultants)])
      .finally(() => setLoading(false));
  }, []);

  if (loading) return <div className="p-5"><p><FormattedMessage id="clients.loading" /></p></div>;

  return (
    <div className="p-5">
      <div className="flex items-center justify-between mb-6">
        <div><h1 className="text-2xl font-bold"><FormattedMessage id="clients.title" /></h1><p className="text-sm text-muted-foreground"><FormattedMessage id="clients.subtitle" /></p></div>
        {financial.length > 0 && <Button variant="outline" size="sm" onClick={() => exportCSV(financial)}><Download className="size-3.5 mr-1" /> <FormattedMessage id="common.exportCsv" /></Button>}
      </div>

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
            <thead><tr className="border-b bg-muted/30"><th className="text-left p-2"><FormattedMessage id="clients.client" /></th><th className="text-right p-2"><FormattedMessage id="clients.consultants" /></th><th className="text-right p-2"><FormattedMessage id="billing.daily" /></th><th className="text-right p-2"><FormattedMessage id="common.monthly" /></th><th className="text-right p-2"><FormattedMessage id="common.fees" /></th><th className="text-right p-2"><FormattedMessage id="billing.avgCoef" /></th><th className="text-right p-2"><FormattedMessage id="common.margin" /></th><th className="text-right p-2"><FormattedMessage id="billing.managerBonus" /></th></tr></thead>
            <tbody>{financial.sort((a,b)=>b.margin-a.margin).map((f,i) => {
              const c = (f.avgCoef || 0);
              const color = c > 0.15 ? 'bg-emerald-50' : c > 0.08 ? 'bg-amber-50' : 'bg-red-50';
              return (<Fragment key={f.client}>
                <tr className={`border-b hover:bg-muted/30 cursor-pointer ${color}`} onClick={() => setExpandedClient(expandedClient === f.client ? null : f.client)}>
                  <td className="p-2 font-medium">{f.client}</td><td className="p-2 text-right">{f.consultants}</td><td className="p-2 text-right">{F(f.daily)}€</td><td className="p-2 text-right">{F(f.monthly)}€</td><td className="p-2 text-right">{F(f.fees)}€</td><td className="p-2 text-right">{P(c)}%</td><td className="p-2 text-right">{F(f.margin)}€</td><td className="p-2 text-right">{F(f.bonus)}€</td>
                </tr>
                {expandedClient === f.client && <tr><td colSpan={8} className="p-0"><div className="bg-muted/20 p-3"><table className="w-full text-xs">
                  <thead><tr className="border-b"><th className="text-left p-1"><FormattedMessage id="consultants.name" /></th><th className="text-left p-1"><FormattedMessage id="consultants.position" /></th><th className="text-right p-1"><FormattedMessage id="consultants.dailyRate" /></th><th className="text-right p-1"><FormattedMessage id="consultants.coefPct" /></th><th className="text-right p-1"><FormattedMessage id="common.margin" /></th></tr></thead>
                  <tbody>{consultants.filter(co=>co.client===f.client).map(co => (<tr key={co.id} className="border-b"><td className="p-1 font-medium">{co.name}</td><td className="p-1">{co.position}</td><td className="p-1 text-right">{co.tariff}€</td><td className="p-1 text-right">{P(co.coefPercentage)}%</td><td className="p-1 text-right">{F(co.coefMargin)}€</td></tr>))}</tbody>
                </table></div></td></tr>}
              </Fragment>);
            })}</tbody></table></div>
        </CardContent>
      </Card>
    </div>
  );
}
