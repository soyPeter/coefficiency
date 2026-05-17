import { useEffect, useState, useCallback, useMemo } from 'react';
import { Plus, Trash2, UserCheck } from 'lucide-react';
import { FormattedMessage, useIntl } from 'react-intl';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Button } from '@/components/ui/button';
import { request } from '@/api';

interface CostRow { id: string; concept: string; cost: number; type: 'monthly' | 'yearly'; }
interface Concept { id: number; name: string; type: string; defaultValue: number; }
interface SimResult {
  coefPercentage: number; monthlyMargin: number; monthlyFees: number;
  managerBonus: number;
  breakdown: { salary: number; irpf: number; socialSecurity: number; totalCost: number; annualFees: number };
}
interface ConsultantBrief { id: number; name: string; client: string; }

export default function SimulatorPage({ embedded, initialConsultantId, onCoefSaved }: {
  embedded?: boolean;
  initialConsultantId?: number | null;
  onCoefSaved?: () => void;
}) {
  const intl = useIntl();
  const [concepts, setConcepts] = useState<Concept[]>([]);
  const [costRows, setCostRows] = useState<CostRow[]>([]);
  const [result, setResult] = useState<SimResult | null>(null);
  const [defaults, setDefaults] = useState<any>(null);
  const [coefDaysMonth, setCoefDaysMonth] = useState(21);
  const [consultants, setConsultants] = useState<ConsultantBrief[]>([]);
  const [selectedConsultantId, setSelectedConsultantId] = useState<number | null>(null);
  const [saving, setSaving] = useState(false);
  const [savedMsg, setSavedMsg] = useState('');

  const [dailyRate, setDailyRate] = useState(300);
  const [annualWorkdays, setAnnualWorkdays] = useState(231);
  const [grossSalary, setGrossSalary] = useState(30000);
  const [category, setCategory] = useState('Ingenieros y Licenciados');
  const [age, setAge] = useState(30);
  const [children, setChildren] = useState(0);
  const [ascendants, setAscendants] = useState(0);
  const [disability, setDisability] = useState(0);

  useEffect(() => {
    request<any>('/simulator/defaults').then(setDefaults).catch(() => {});
    request<any[]>('/concepts').then(setConcepts).catch(() => {});
    request<any>('/fiscal').then(d => {
      if (d.workingDays && d.workingDays.length) {
        const total = d.workingDays.reduce((a: number, b: number) => a + b, 0);
        setAnnualWorkdays(total);
      }
      if (d.coefDaysMonth) setCoefDaysMonth(d.coefDaysMonth);
    }).catch(() => {});
    request<any>('/consultants').then(r => setConsultants(r.items || [])).catch(() => {});
  }, []);

  // Pre-select consultant and load their data when opened from consultant detail view
  useEffect(() => {
    if (initialConsultantId == null) return;
    setSelectedConsultantId(initialConsultantId);
    request<any>(`/consultants/${initialConsultantId}`)
      .then(c => {
        if (c.fees && c.fees > 0) {
          setDailyRate(Math.round(c.fees / coefDaysMonth));
        } else if (c.tariff) {
          setDailyRate(c.tariff);
        }
        if (c.simulationInputs) {
          try {
            const saved = typeof c.simulationInputs === 'string'
              ? JSON.parse(c.simulationInputs)
              : c.simulationInputs;
            if (saved.grossAnnualSalary != null) setGrossSalary(saved.grossAnnualSalary);
            if (saved.category != null) setCategory(saved.category);
            if (saved.age != null) setAge(saved.age);
            if (saved.children != null) setChildren(saved.children);
            if (saved.ascendants != null) setAscendants(saved.ascendants);
            if (saved.disability != null) setDisability(saved.disability);
            if (saved.dailyRate != null) setDailyRate(saved.dailyRate);
            if (saved.costRows && Array.isArray(saved.costRows)) setCostRows(saved.costRows);
          } catch {}
        }
      })
      .catch(() => {});
  }, [initialConsultantId, coefDaysMonth]);

  const addCostRow = (type: 'monthly' | 'yearly') => {
    setCostRows(prev => [...prev, { id: Date.now().toString(), concept: '', cost: 0, type }]);
  };

  const removeCostRow = (id: string) => {
    setCostRows(prev => prev.filter(r => r.id !== id));
  };

  const updateCostRow = (id: string, field: 'concept' | 'cost', value: string | number) => {
    setCostRows(prev => prev.map(r => r.id === id ? { ...r, [field]: value } : r));
  };

  const totalMonthly = costRows.filter(r => r.type === 'monthly').reduce((s, r) => s + (r.cost || 0), 0);
  const totalYearly = costRows.filter(r => r.type === 'yearly').reduce((s, r) => s + (r.cost || 0), 0);
  const totalYearlyMonthly = totalYearly / 12;
  const feesCalc = dailyRate * coefDaysMonth;

  const simulatorInput = useMemo(() => ({
    fees: feesCalc, annualWorkdays, age, category, grossAnnualSalary: grossSalary,
    dailyRate, costRows,
    dailyMealCard: 0, annualPerformanceBonus: 0,
    bonusCalendar: 'Anual (Dic)', annualChildSupport: 0, annualTraining: 0,
    hasLaptop: false, monthlyLaptop: 0, hasHealthInsurance: false, monthlyHealthInsurance: 0,
    monthlyExtraIT: 0, monthlyLicenses: 0, otherCosts: totalMonthly * 12 + totalYearly,
    workingDays: [20,19,23,19,21,22,21,22,22,20,21,19],
    children, ascendants, disability,
  }), [feesCalc, grossSalary, category, age, children, ascendants, disability, totalMonthly, totalYearly, costRows, dailyRate, annualWorkdays]);

  const calc = useCallback(() => {
    request<any>('/simulator/calculate', {
      method: 'POST',
      body: JSON.stringify({
        salary: grossSalary,
        dailyRate,
        category,
        age,
        fixedCosts: totalMonthly * 12 + totalYearly,
        benefits: 0,
        deductions: { children, ascendants, disabilities: disability },
      }),
    }).then(d => {
      const r = d;
      if (r) {
        setResult({
          coefPercentage: r.coefPercentage ?? 0,
          monthlyMargin: r.monthlyMargin ?? 0,
          monthlyFees: r.monthlyFees ?? 0,
          managerBonus: r.managerBonus ?? 0,
          breakdown: r.breakdown ?? { salary: 0, irpf: 0, socialSecurity: 0, totalCost: 0, annualFees: 0 },
        });
      }
    });
  }, [grossSalary, dailyRate, category, age, children, ascendants, disability, totalMonthly, totalYearly]);

  useEffect(() => { calc(); }, [calc]);

  const handleSaveToConsultant = async () => {
    if (!selectedConsultantId || !result) return;
    setSaving(true);
    setSavedMsg('');
    try {
      const token = localStorage.getItem('token');
      const res = await fetch(`/api/consultants/${selectedConsultantId}/coef`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json', ...(token ? { 'Authorization': `Bearer ${token}` } : {}) },
        body: JSON.stringify({
          fees: feesCalc,
          coefPercentage: result.coefPercentage,
          coefMargin: result.monthlyMargin,
          managerBonus: result.managerBonus,
          tariff: dailyRate,
          inputs: JSON.stringify(simulatorInput),
        }),
      });
      if (res.ok) {
        setSavedMsg('Guardado');
        setTimeout(() => setSavedMsg(''), 2000);
        if (onCoefSaved) onCoefSaved();
      } else {
        const err = await res.json().catch(() => ({ error: 'Error' }));
        setSavedMsg(err.error || 'Error');
      }
    } catch {
      setSavedMsg('Error de conexión');
    } finally {
      setSaving(false);
    }
  };

  const selectedConsultant = consultants.find(c => c.id === selectedConsultantId);

  const fmt = (n: number) => n.toLocaleString('es-ES', { minimumFractionDigits: 2 });
  const pct = (n: number) => (n * 100).toFixed(2);

  return (
    <div className={embedded ? '' : 'p-5'}>
      {!embedded && <h1 className="text-xl font-semibold mb-4"><FormattedMessage id="simulator.title" /></h1>}

      {/* -- Sticky KPI bar -- */}
      <div className="sticky top-0 z-10 bg-background pt-1 pb-3 mb-6 border-b">
        <div className="grid grid-cols-3 gap-3">
          <Card className="bg-emerald-50 dark:bg-emerald-950/20 border-emerald-200">
            <CardContent className="p-3 text-center">
              <p className="text-xs text-muted-foreground"><FormattedMessage id="simulator.coefPct" /></p>
              <p className="text-2xl font-bold text-emerald-700">
                {result ? `${pct(result.coefPercentage)}%` : '\u2014'}
              </p>
            </CardContent>
          </Card>
          <Card className="bg-blue-50 dark:bg-blue-950/20 border-blue-200">
            <CardContent className="p-3 text-center">
              <p className="text-xs text-muted-foreground"><FormattedMessage id="simulator.margin" /></p>
               <p className="text-2xl font-bold text-blue-700">
                {result ? `€${fmt(result.monthlyMargin)}` : '\u2014'}
              </p>
            </CardContent>
          </Card>
          <Card className="bg-amber-50 dark:bg-amber-950/20 border-amber-200">
            <CardContent className="p-3 text-center">
              <p className="text-xs text-muted-foreground"><FormattedMessage id="simulator.managerBonus" /></p>
              <p className="text-2xl font-bold text-amber-700">
                {result ? `€${result.managerBonus.toFixed(2)}` : '\u2014'}
              </p>
            </CardContent>
          </Card>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* -- Inputs column -- */}
        <div className="space-y-4">
          {/* -- Consultant selector -- */}
          <Card>
            <CardHeader className="pb-2"><CardTitle className="text-sm"><FormattedMessage id="simulator.consultant" /></CardTitle></CardHeader>
            <CardContent className="space-y-3">
              <select value={selectedConsultantId ?? ''} onChange={e => {
                const id = e.target.value ? parseInt(e.target.value) : null;
                setSelectedConsultantId(id);
                setSavedMsg('');
              }}
                className="flex h-8.5 w-full rounded-md border border-input bg-background px-3 py-1 text-sm">
                <option value="">{intl.formatMessage({ id: 'simulator.selectConsultant' })}</option>
                {consultants.map(c => (
                  <option key={c.id} value={c.id}>{c.name} — {c.client}</option>
                ))}
              </select>
              <div className="flex gap-2">
                <Button onClick={handleSaveToConsultant} disabled={!selectedConsultantId || !result || saving} size="sm" className="flex-1">
                  <UserCheck className="size-3.5 mr-1" />
                  {selectedConsultant ? `Guardar en ${selectedConsultant.name}` : intl.formatMessage({ id: 'simulator.saveToConsultant' })}
                </Button>
              </div>
              {savedMsg && (
                <div className={`text-xs text-center rounded p-1.5 ${savedMsg === 'Guardado' ? 'bg-emerald-50 text-emerald-700' : 'bg-red-50 text-red-700'}`}>
                  {savedMsg}
                </div>
              )}
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="pb-2"><CardTitle className="text-sm"><FormattedMessage id="simulator.consultantData" /></CardTitle></CardHeader>
            <CardContent className="space-y-3">
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <Label><FormattedMessage id="simulator.age" /></Label>
                  <Input type="number" value={age} onChange={e => setAge(parseInt(e.target.value)||0)} />
                </div>
                <div>
                  <Label><FormattedMessage id="simulator.category" /></Label>
                  <select value={category} onChange={e => setCategory(e.target.value)}
                    className="flex h-8.5 w-full rounded-md border border-input bg-background px-3 py-1 text-sm">
                    {defaults?.categories?.map((c: string) => <option key={c} value={c}>{c}</option>)}
                  </select>
                </div>
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="pb-2"><CardTitle className="text-sm"><FormattedMessage id="simulator.salaryPrice" /></CardTitle></CardHeader>
            <CardContent className="space-y-3">
              <div>
                <Label><FormattedMessage id="simulator.grossAnnual" /></Label>
                  <Input type="number" value={grossSalary} onChange={e => setGrossSalary(parseFloat(e.target.value)||0)} />
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <Label><FormattedMessage id="simulator.priceDay" /></Label>
                  <Input type="number" value={dailyRate} onChange={e => setDailyRate(parseFloat(e.target.value)||0)} />
                </div>
                <div>
                  <Label><FormattedMessage id="simulator.workdays" /></Label>
                  <Input type="number" value={coefDaysMonth} disabled className="bg-muted" />
                </div>
              </div>
              <div className="bg-muted/50 p-3 rounded-md">
                <div className="flex justify-between items-center">
                  <span className="text-xs text-muted-foreground"><FormattedMessage id="simulator.fees" /></span>
                  <span className="text-sm font-semibold">€{fmt(feesCalc)}</span>
                </div>
                <div className="text-xs text-muted-foreground mt-1">
                  <FormattedMessage id="simulator.formula" values={{ price: dailyRate, days: coefDaysMonth }} />
                </div>
              </div>
              {result && (
                <div className="grid grid-cols-2 gap-2 mt-2">
                  <div className="bg-green-50 dark:bg-green-950/20 border border-green-200 rounded-md p-2">
                    <p className="text-xs text-muted-foreground"><FormattedMessage id="simulator.netMonthly" /></p>
                    <p className="text-sm font-bold text-green-700">€{fmt(result.breakdown.salary - result.breakdown.irpf - result.breakdown.socialSecurity)}</p>
                  </div>
                  <div className="bg-slate-50 dark:bg-slate-800 border border-slate-200 rounded-md p-2">
                    <p className="text-xs text-muted-foreground"><FormattedMessage id="simulator.totalCost" /></p>
                    <p className="text-sm font-bold">€{fmt(result.breakdown.totalCost)}</p>
                  </div>
                  <div className="bg-blue-50 dark:bg-blue-950/20 border border-blue-200 rounded-md p-2">
                    <p className="text-xs text-muted-foreground"><FormattedMessage id="simulator.irpf" /></p>
                    <p className="text-sm font-bold text-blue-700">€{fmt(result.breakdown.irpf)}</p>
                  </div>
                  <div className="bg-purple-50 dark:bg-purple-950/20 border border-purple-200 rounded-md p-2">
                    <p className="text-xs text-muted-foreground"><FormattedMessage id="simulator.socialSecurity" /></p>
                    <p className="text-sm font-bold text-purple-700">€{fmt(result.breakdown.socialSecurity)}</p>
                  </div>
                </div>
              )}
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="pb-2"><CardTitle className="text-sm"><FormattedMessage id="simulator.familyDeductions" /></CardTitle></CardHeader>
            <CardContent className="grid grid-cols-3 gap-3">
              <div>
                <Label><FormattedMessage id="simulator.children" /></Label>
                <Input type="number" value={children} onChange={e => setChildren(parseInt(e.target.value)||0)} />
              </div>
              <div>
                <Label><FormattedMessage id="simulator.parents" /></Label>
                <Input type="number" value={ascendants} onChange={e => setAscendants(parseInt(e.target.value)||0)} />
              </div>
              <div>
                <Label><FormattedMessage id="simulator.disability" /></Label>
                <Input type="number" value={disability} onChange={e => setDisability(parseInt(e.target.value)||0)} />
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="pb-2"><CardTitle className="text-sm"><FormattedMessage id="simulator.monthlyCosts" /></CardTitle></CardHeader>
            <CardContent className="space-y-2">
              {costRows.filter(r => r.type === 'monthly').map(row => (
                <CostRowInput key={row.id} row={row} concepts={concepts} onUpdate={updateCostRow} onRemove={removeCostRow} />
              ))}
              <Button variant="outline" size="sm" onClick={() => addCostRow('monthly')}>
                <Plus className="size-3.5 mr-1" /> <FormattedMessage id="simulator.addMonthly" />
              </Button>
              <div className="text-xs text-muted-foreground text-right">
                <FormattedMessage id="simulator.totalMonth" values={{ value: totalMonthly.toFixed(2) }} />
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="pb-2"><CardTitle className="text-sm"><FormattedMessage id="simulator.yearlyCosts" /></CardTitle></CardHeader>
            <CardContent className="space-y-2">
              {costRows.filter(r => r.type === 'yearly').map(row => (
                <CostRowInput key={row.id} row={row} concepts={concepts} onUpdate={updateCostRow} onRemove={removeCostRow} />
              ))}
              <Button variant="outline" size="sm" onClick={() => addCostRow('yearly')}>
                <Plus className="size-3.5 mr-1" /> <FormattedMessage id="simulator.addYearly" />
              </Button>
              <div className="text-xs text-muted-foreground text-right">
                <FormattedMessage id="simulator.totalYear" values={{ value: totalYearly.toFixed(2), monthly: totalYearlyMonthly.toFixed(2) }} />
              </div>
            </CardContent>
          </Card>
        </div>

        {/* -- Right column -- */}
        <div className="space-y-4">
          <Card>
            <CardHeader className="pb-2"><CardTitle className="text-sm"><FormattedMessage id="simulator.breakdown" /></CardTitle></CardHeader>
            <CardContent className="space-y-3">
              <div className="grid grid-cols-2 gap-2 text-xs">
                <div className="flex justify-between p-2 bg-muted/30 rounded">
                  <span className="text-muted-foreground"><FormattedMessage id="simulator.grossAnnual" /></span>
                  <span className="font-semibold">€{fmt(grossSalary)}</span>
                </div>
                <div className="flex justify-between p-2 bg-muted/30 rounded">
                  <span className="text-muted-foreground"><FormattedMessage id="simulator.fees" /></span>
                  <span className="font-semibold">€{fmt(feesCalc)}</span>
                </div>
              </div>
              {result && (
                <>
                  <div className="grid grid-cols-2 gap-2 text-xs">
                    <div className="flex justify-between p-2 bg-muted/30 rounded">
                      <span className="text-muted-foreground"><FormattedMessage id="simulator.netMonthly" /></span>
                      <span className="font-semibold">€{fmt(result.breakdown.salary - result.breakdown.irpf - result.breakdown.socialSecurity)}</span>
                    </div>
                    <div className="flex justify-between p-2 bg-muted/30 rounded">
                      <span className="text-muted-foreground"><FormattedMessage id="simulator.totalCost" /></span>
                      <span className="font-semibold">€{fmt(result.breakdown.totalCost)}</span>
                    </div>
                    <div className="flex justify-between p-2 bg-muted/30 rounded">
                      <span className="text-muted-foreground"><FormattedMessage id="simulator.irpf" /></span>
                      <span className="font-semibold">€{fmt(result.breakdown.irpf)}</span>
                    </div>
                    <div className="flex justify-between p-2 bg-muted/30 rounded">
                      <span className="text-muted-foreground"><FormattedMessage id="simulator.socialSecurity" /></span>
                      <span className="font-semibold">€{fmt(result.breakdown.socialSecurity)}</span>
                    </div>
                  </div>
                  <div className="border-t pt-2 mt-1">
                    <div className="flex justify-between items-center">
                      <span className="text-xs text-muted-foreground"><FormattedMessage id="simulator.coefPct" /></span>
                      <span className="text-xl font-bold text-emerald-700">{pct(result.coefPercentage)}%</span>
                    </div>
                    <div className="flex justify-between items-center mt-1">
                      <span className="text-xs text-muted-foreground"><FormattedMessage id="simulator.margin" /></span>
                      <span className="text-sm font-semibold">€{fmt(result.monthlyMargin)}</span>
                    </div>
                    <div className="flex justify-between items-center mt-1">
                      <span className="text-xs text-muted-foreground"><FormattedMessage id="simulator.managerBonus" /></span>
                      <span className="text-sm font-semibold text-amber-700">€{result.managerBonus.toFixed(2)}</span>
                    </div>
                  </div>
                </>
              )}
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}

function CostRowInput({ row, concepts, onUpdate, onRemove }: {
  row: CostRow; concepts: Concept[];
  onUpdate: (id: string, field: 'concept'|'cost', value: string|number) => void;
  onRemove: (id: string) => void;
}) {
  const intl = useIntl();
  const [open, setOpen] = useState(false);
  const [search, setSearch] = useState(row.concept);

  const filtered = useMemo(() => {
    const matches = concepts.filter(c => c.type === row.type && c.name.toLowerCase().includes(search.toLowerCase()));
    if (search && !matches.find(m => m.name === search)) {
      matches.unshift({ id: -1, name: search, type: row.type, defaultValue: 0 });
    }
    return matches;
  }, [concepts, search, row.type]);

  return (
    <div className="flex gap-2 items-start">
      <div className="relative flex-1">
        <Input placeholder={intl.formatMessage({ id: 'simulator.concept' })} value={search} onChange={e => { setSearch(e.target.value); onUpdate(row.id, 'concept', e.target.value); }}
          onFocus={() => setOpen(true)} onBlur={() => setTimeout(() => setOpen(false), 200)} />
        {open && filtered.length > 0 && (
          <div className="absolute z-10 w-full mt-1 bg-background border rounded-md shadow-lg max-h-32 overflow-auto">
            {filtered.map((c, i) => (
              <div key={i} className="px-3 py-1.5 text-sm cursor-pointer hover:bg-muted"
                onMouseDown={() => { onUpdate(row.id, 'concept', c.name); onUpdate(row.id, 'cost', c.defaultValue); setSearch(c.name); setOpen(false); }}>
                {c.name}{c.id === -1 ? '' : ` (€${c.defaultValue})`}
              </div>
            ))}
          </div>
        )}
      </div>
      <Input type="number" placeholder="€" className="w-24" value={row.cost || ''}
        onChange={e => onUpdate(row.id, 'cost', parseFloat(e.target.value)||0)} />
      <Button variant="ghost" size="sm" onClick={() => onRemove(row.id)}><Trash2 className="size-3.5" /></Button>
    </div>
  );
}
