import { useEffect, useState, useCallback } from 'react';
import { FormattedMessage } from 'react-intl';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import {
  fetchReportYears, fetchReport, fetchProfitability, fetchTargets,
  fetchReportClients, fetchClientTimeline, fetchRoleAggregation,
  fetchPerConsultant, fetchForecast, fetchYoy, fetchBenchmarks
} from '@/api';
import type {
  ReportSection, ProfitabilityRow, TargetsResponse, ClientTimelineRow,
  RoleAggregationRow, PerConsultantRow, ForecastResponse, YoyRow, BenchmarkRow
} from '@/types';

const SECTIONS = [
  'Consultants', 'COEF Analytics', 'Billing Summary', 'Client Financials',
  'Profitability', 'Targets', 'Per Consultant', 'Forecast',
  'Year over Year', 'Role Aggregation', 'Benchmarks'
];

export default function ReportsPage() {
  const [visible, setVisible] = useState<Set<string>>(new Set(SECTIONS));
  const [year, setYear] = useState<number | undefined>();
  const [from, setFrom] = useState('');
  const [to, setTo] = useState('');
  const [years, setYears] = useState<number[]>([]);
  const [reportData, setReportData] = useState<ReportSection[]>([]);
  const [profitability, setProfitability] = useState<ProfitabilityRow[]>([]);
  const [targets, setTargets] = useState<TargetsResponse | null>(null);
  const [clients, setClients] = useState<string[]>([]);
  const [clientTimeline, setClientTimeline] = useState<ClientTimelineRow[]>([]);
  const [selectedClient, setSelectedClient] = useState('');
  const [roleAgg, setRoleAgg] = useState<RoleAggregationRow[]>([]);
  const [perConsultant, setPerConsultant] = useState<PerConsultantRow[]>([]);
  const [pcSearch, setPcSearch] = useState('');
  const [forecast, setForecast] = useState<ForecastResponse | null>(null);
  const [yoy, setYoy] = useState<YoyRow[]>([]);
  const [benchmarks, setBenchmarks] = useState<BenchmarkRow[]>([]);

  useEffect(() => {
    fetchReportYears().then(setYears).catch(() => {});
    fetchReportClients().then(setClients).catch(() => {});
    fetchForecast().then(setForecast).catch(() => {});
    fetchYoy().then(setYoy).catch(() => {});
    fetchBenchmarks().then(setBenchmarks).catch(() => {});
  }, []);

  const loadReport = useCallback(() => {
    fetchReport(year, from || undefined, to || undefined).then(setReportData).catch(() => {});
    fetchProfitability(year, from || undefined, to || undefined).then(setProfitability).catch(() => {});
    fetchTargets(year).then(setTargets).catch(() => {});
    fetchRoleAggregation().then(setRoleAgg).catch(() => {});
    fetchPerConsultant().then(setPerConsultant).catch(() => {});
    if (selectedClient) {
      fetchClientTimeline(selectedClient, year).then(setClientTimeline).catch(() => {});
    }
  }, [year, from, to, selectedClient]);

  useEffect(() => { loadReport(); }, [loadReport]);

  const toggle = (s: string) => {
    setVisible(prev => {
      const next = new Set(prev);
      if (next.has(s)) next.delete(s); else next.add(s);
      return next;
    });
  };

  const fmt = (n: number | null | undefined) => n != null ? n.toLocaleString('es-ES', { minimumFractionDigits: 2 }) : '0.00';
  const pct = (n: number | null | undefined) => n != null ? (n * 100).toFixed(2) : '0.00';

  const getSection = (name: string) => reportData.find(s => s.section === name)?.data;

  return (
    <div className="p-5 space-y-4">
      <div className="flex items-center justify-between mb-4">
        <h1 className="text-2xl font-bold"><FormattedMessage id="report.title" /></h1>
        <div className="flex gap-3 items-center">
          <select value={year || ''} onChange={e => setYear(e.target.value ? parseInt(e.target.value) : undefined)}
            className="flex h-8.5 rounded-md border border-input bg-background px-3 py-1 text-sm">
            <option value=""><FormattedMessage id="report.allYears" /></option>
            {years.map(y => <option key={y} value={y}>{y}</option>)}
          </select>
          <div>
            <Label className="text-xs"><FormattedMessage id="report.dateFrom" /></Label>
            <Input type="date" value={from} onChange={e => setFrom(e.target.value)} className="h-8 w-36" />
          </div>
          <div>
            <Label className="text-xs"><FormattedMessage id="report.dateTo" /></Label>
            <Input type="date" value={to} onChange={e => setTo(e.target.value)} className="h-8 w-36" />
          </div>
          <Button size="sm" onClick={loadReport}><FormattedMessage id="common.retry" /></Button>
        </div>
      </div>

      <div className="flex flex-wrap gap-2 mb-4">
        {SECTIONS.map(s => (
          <Button key={s} variant={visible.has(s) ? 'default' : 'outline'} size="sm" onClick={() => toggle(s)}>{s}</Button>
        ))}
      </div>

      {visible.has('Consultants') && getSection('consultants') && (
        <Card>
          <CardHeader><CardTitle className="text-sm">Consultant Roster</CardTitle></CardHeader>
          <CardContent>
            <div className="overflow-auto max-h-80">
              <table className="w-full text-xs">
                <thead><tr className="bg-muted/50">{['Name','Client','Position','Coef','Tariff','Fees','Margin','Bonus'].map(h => <th key={h} className="text-left p-1.5">{h}</th>)}</tr></thead>
                <tbody>
                  {getSection('consultants').map((c: any, i: number) => (
                    <tr key={i} className="border-t hover:bg-muted/20">
                      <td className="p-1.5">{c.name}</td>
                      <td className="p-1.5">{c.client}</td>
                      <td className="p-1.5">{c.position}</td>
                      <td className="p-1.5">{c.coef}</td>
                      <td className="p-1.5">€{fmt(c.tariff)}</td>
                      <td className="p-1.5">{c.fees != null ? '€' + fmt(c.fees) : '-'}</td>
                      <td className="p-1.5">{c.coef_margin != null ? '€' + fmt(c.coef_margin) : '-'}</td>
                      <td className="p-1.5">{c.manager_bonus != null ? '€' + fmt(c.manager_bonus) : '-'}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </CardContent>
        </Card>
      )}

      {visible.has('COEF Analytics') && getSection('summary') && (
        <Card>
          <CardHeader><CardTitle className="text-sm">COEF Analytics</CardTitle></CardHeader>
          <CardContent>
            <div className="grid grid-cols-4 gap-3 text-xs">
              {[
                ['Avg COEF%', pct(getSection('summary')?.avgCoefPct || 0) + '%'],
                ['Total Margin', '€' + fmt(getSection('summary')?.totalCoefMargin || 0)],
                ['Total Fees', '€' + fmt(getSection('summary')?.totalFees || 0)],
                ['Consultants', String(getSection('summary')?.consultantCount || 0)],
              ].map(([l, v]) => (
                <div key={l} className="bg-muted/30 p-3 rounded text-center">
                  <p className="text-muted-foreground">{l}</p>
                  <p className="text-lg font-bold">{v}</p>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      )}

      {visible.has('Billing Summary') && getSection('summary') && (
        <Card>
          <CardHeader><CardTitle className="text-sm">Billing Summary</CardTitle></CardHeader>
          <CardContent>
            <div className="grid grid-cols-3 gap-3 text-xs">
              {[['Daily', '€' + fmt(getSection('summary')?.daily || 0)],
                ['Monthly', '€' + fmt(getSection('summary')?.monthly || 0)],
                ['Annual', '€' + fmt(getSection('summary')?.annual || 0)],
                ['Hires', String(getSection('summary')?.hires || 0)],
                ['Terminations', String(getSection('summary')?.terminations || 0)],
                ['Net Change', String((getSection('summary')?.hires || 0) - (getSection('summary')?.terminations || 0))],
              ].map(([l, v]) => (
                <div key={l} className="bg-muted/30 p-2 rounded text-center">
                  <p className="text-muted-foreground">{l}</p>
                  <p className="font-bold">{v}</p>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      )}

      {visible.has('Client Financials') && getSection('clients') && (
        <Card>
          <CardHeader><CardTitle className="text-sm">Client Financials</CardTitle></CardHeader>
          <CardContent>
            <div className="overflow-auto max-h-60">
              <table className="w-full text-xs">
                <thead><tr className="bg-muted/50">{['Client','Consultants','Daily','Margin','Avg Tenure'].map(h => <th key={h} className="text-left p-1.5">{h}</th>)}</tr></thead>
                <tbody>
                  {getSection('clients').map((c: any, i: number) => (
                    <tr key={i} className="border-t hover:bg-muted/20">
                      <td className="p-1.5 font-medium">{c.client}</td>
                      <td className="p-1.5">{c.consultants}</td>
                      <td className="p-1.5">€{fmt(c.daily)}</td>
                      <td className="p-1.5">€{fmt(c.margin)}</td>
                      <td className="p-1.5">{c.avgTenureDays}d</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </CardContent>
        </Card>
      )}

      {visible.has('Profitability') && profitability.length > 0 && (
        <Card>
          <CardHeader><CardTitle className="text-sm">Profitability Trends</CardTitle></CardHeader>
          <CardContent>
            <div className="overflow-auto max-h-60">
              <table className="w-full text-xs">
                <thead><tr className="bg-muted/50">{['Month','Margin %','Total Fees','Avg COEF%'].map(h => <th key={h} className="text-left p-1.5">{h}</th>)}</tr></thead>
                <tbody>
                  {profitability.map((r, i) => (
                    <tr key={i} className="border-t hover:bg-muted/20">
                      <td className="p-1.5">{r.month}</td>
                      <td className="p-1.5">{r.marginPct.toFixed(2)}%</td>
                      <td className="p-1.5">€{fmt(r.totalFees)}</td>
                      <td className="p-1.5">{r.avgCoefPct.toFixed(2)}%</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </CardContent>
        </Card>
      )}

      {visible.has('Targets') && targets && (
        <Card>
          <CardHeader><CardTitle className="text-sm">Revenue vs Targets</CardTitle></CardHeader>
          <CardContent>
            <div className="grid grid-cols-2 gap-4 text-xs">
              <div className="bg-muted/30 p-3 rounded text-center">
                <p className="text-muted-foreground">Revenue Target</p>
                <p className="text-lg font-bold">€{fmt(targets.targetRevenue)}</p>
              </div>
              <div className="bg-muted/30 p-3 rounded text-center">
                <p className="text-muted-foreground">Actual Revenue</p>
                <p className="text-lg font-bold">€{fmt(targets.actualRevenue)}</p>
              </div>
              <div className="bg-muted/30 p-3 rounded text-center">
                <p className="text-muted-foreground">Margin Target</p>
                <p className="text-lg font-bold">{targets.targetMarginPct.toFixed(1)}%</p>
              </div>
              <div className="bg-muted/30 p-3 rounded text-center">
                <p className="text-muted-foreground">Actual Margin</p>
                <p className="text-lg font-bold">{targets.actualMarginPct.toFixed(1)}%</p>
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      {visible.has('Per Consultant') && (
        <Card>
          <CardHeader className="flex flex-row items-center justify-between">
            <CardTitle className="text-sm">Per-Consultant Billing</CardTitle>
            <Input placeholder="Search..." value={pcSearch} onChange={e => {
              setPcSearch(e.target.value);
              fetchPerConsultant(e.target.value || undefined).then(setPerConsultant).catch(() => {});
            }} className="w-48 h-8 text-xs" />
          </CardHeader>
          <CardContent>
            <div className="overflow-auto max-h-60">
              <table className="w-full text-xs">
                <thead><tr className="bg-muted/50">{['Name','Client','Position','Tariff','Fees','Margin','Bonus'].map(h => <th key={h} className="text-left p-1.5">{h}</th>)}</tr></thead>
                <tbody>
                  {perConsultant.map((r, i) => (
                    <tr key={i} className="border-t hover:bg-muted/20">
                      <td className="p-1.5 font-medium">{r.name}</td>
                      <td className="p-1.5">{r.client}</td>
                      <td className="p-1.5">{r.position}</td>
                      <td className="p-1.5">€{fmt(r.tariff)}</td>
                      <td className="p-1.5">€{fmt(r.fees)}</td>
                      <td className="p-1.5">€{fmt(r.coefMargin)}</td>
                      <td className="p-1.5">€{fmt(r.managerBonus)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </CardContent>
        </Card>
      )}

      {visible.has('Forecast') && forecast && (
        <Card>
          <CardHeader><CardTitle className="text-sm">Annual Forecast {forecast.currentYear}</CardTitle></CardHeader>
          <CardContent>
            <div className="grid grid-cols-5 gap-2 text-xs">
              {[
                ['YTD Working Days', String(forecast.ytdWorkingDays)],
                ['YTD Billing', '€' + fmt(forecast.ytdBilling)],
                ['Remaining Days', String(forecast.remainingWorkingDays)],
                ['Projected Remaining', '€' + fmt(forecast.projectedRemaining)],
                ['Projected Total', '€' + fmt(forecast.projectedTotal)],
              ].map(([l, v]) => (
                <div key={l} className="bg-muted/30 p-2 rounded text-center">
                  <p className="text-muted-foreground">{l}</p>
                  <p className="font-bold">{v}</p>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      )}

      {visible.has('Year over Year') && yoy.length > 0 && (
        <Card>
          <CardHeader><CardTitle className="text-sm">Year-over-Year Comparison</CardTitle></CardHeader>
          <CardContent>
            <div className="overflow-auto">
              <table className="w-full text-xs">
                <thead><tr className="bg-muted/50">{['Year','Headcount','Daily','Monthly','Annual','Hires','Terms','Avg COEF%','Bonus','Delta'].map(h => <th key={h} className="text-left p-1.5">{h}</th>)}</tr></thead>
                <tbody>
                  {yoy.map((r, i) => (
                    <tr key={i} className="border-t hover:bg-muted/20">
                      <td className="p-1.5 font-medium">{r.year}</td>
                      <td className="p-1.5">{r.headcount}</td>
                      <td className="p-1.5">€{fmt(r.daily)}</td>
                      <td className="p-1.5">€{fmt(r.monthly)}</td>
                      <td className="p-1.5">€{fmt(r.annual)}</td>
                      <td className="p-1.5">{r.hires}</td>
                      <td className="p-1.5">{r.terminations}</td>
                      <td className="p-1.5">{pct(r.avgCoefPct)}%</td>
                      <td className="p-1.5">€{fmt(r.totalManagerBonus)}</td>
                      <td className="p-1.5">{r.delta != null ? '€' + fmt(r.delta) : '-'}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </CardContent>
        </Card>
      )}

      {visible.has('Role Aggregation') && roleAgg.length > 0 && (
        <Card>
          <CardHeader><CardTitle className="text-sm">Role Aggregation</CardTitle></CardHeader>
          <CardContent>
            <div className="overflow-auto max-h-60">
              <table className="w-full text-xs">
                <thead><tr className="bg-muted/50">{['Role','Count','Daily','Avg COEF%','Margin','Peers','P25','P50','P75'].map(h => <th key={h} className="text-left p-1.5">{h}</th>)}</tr></thead>
                <tbody>
                  {roleAgg.map((r, i) => (
                    <tr key={i} className="border-t hover:bg-muted/20">
                      <td className="p-1.5 font-medium">{r.role}</td>
                      <td className="p-1.5">{r.consultantCount}</td>
                      <td className="p-1.5">€{fmt(r.totalDaily)}</td>
                      <td className="p-1.5">{pct(r.avgCoefPct)}%</td>
                      <td className="p-1.5">€{fmt(r.totalMargin)}</td>
                      <td className="p-1.5">{r.peerCount ?? '-'}</td>
                      <td className="p-1.5">{r.p25 != null ? '€' + fmt(r.p25) : '-'}</td>
                      <td className="p-1.5">{r.p50 != null ? '€' + fmt(r.p50) : '-'}</td>
                      <td className="p-1.5">{r.p75 != null ? '€' + fmt(r.p75) : '-'}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </CardContent>
        </Card>
      )}

      {visible.has('Benchmarks') && benchmarks.length > 0 && (
        <Card>
          <CardHeader><CardTitle className="text-sm">Peer Benchmarks</CardTitle></CardHeader>
          <CardContent>
            <div className="overflow-auto max-h-60">
              <table className="w-full text-xs">
                <thead><tr className="bg-muted/50">{['Role','P25','P50 (Median)','P75','Peers'].map(h => <th key={h} className="text-left p-1.5">{h}</th>)}</tr></thead>
                <tbody>
                  {benchmarks.map((b, i) => (
                    <tr key={i} className="border-t hover:bg-muted/20">
                      <td className="p-1.5 font-medium">{b.role}</td>
                      <td className="p-1.5">€{fmt(b.p25)}</td>
                      <td className="p-1.5 font-bold">€{fmt(b.p50)}</td>
                      <td className="p-1.5">€{fmt(b.p75)}</td>
                      <td className="p-1.5">{b.peerCount}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </CardContent>
        </Card>
      )}

      {visible.has('Client Timeline') && clients.length > 0 && (
        <Card>
          <CardHeader className="flex flex-row items-center justify-between">
            <CardTitle className="text-sm">Client Timeline</CardTitle>
            <select value={selectedClient} onChange={e => setSelectedClient(e.target.value)}
              className="flex h-8 rounded-md border border-input bg-background px-3 py-1 text-sm w-48">
              <option value="">Select client...</option>
              {clients.map(c => <option key={c} value={c}>{c}</option>)}
            </select>
          </CardHeader>
          {selectedClient && clientTimeline.length > 0 && (
            <CardContent>
              <div className="overflow-auto max-h-60">
                <table className="w-full text-xs">
                  <thead><tr className="bg-muted/50">{['Month','Fees','Margin','Active'].map(h => <th key={h} className="text-left p-1.5">{h}</th>)}</tr></thead>
                  <tbody>
                    {clientTimeline.map((r, i) => (
                      <tr key={i} className="border-t hover:bg-muted/20">
                        <td className="p-1.5">{r.month}</td>
                        <td className="p-1.5">€{fmt(r.fees)}</td>
                        <td className="p-1.5">€{fmt(r.margin)}</td>
                        <td className="p-1.5">{r.activeConsultants}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </CardContent>
          )}
        </Card>
      )}
    </div>
  );
}
