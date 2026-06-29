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
  grossMonthlySalary: number; netMonthlySalary: number; netAnnualSalary: number;
  monthlySSC: number; monthlyIRPF: number; irpfRate: number; ssRate: number;
  totalConsultantCost: number; coef: number; coefMargin: number; managerBonus: number;
  monthlyProjection?: any;
}
interface ConsultantBrief { id: number; name: string; client: string; }

interface SimDefaults {
  categories: string[]; schedules: string[]; coefDaysMonth: number;
  coefDaysYear: number; workingDays: number[];
}

export default function SimulatorPage({ embedded, initialConsultantId, onCoefSaved }: {
  embedded?: boolean;
  initialConsultantId?: number | null;
  onCoefSaved?: () => void;
}) {
  const intl = useIntl();
  const [defaults, setDefaults] = useState<SimDefaults | null>(null);
  const [coefDaysMonth, setCoefDaysMonth] = useState(21);
  const [coefDaysYear, setCoefDaysYear] = useState(252);
  const [consultants, setConsultants] = useState<ConsultantBrief[]>([]);
  const [selectedConsultantId, setSelectedConsultantId] = useState<number | null>(null);
  const [saving, setSaving] = useState(false);
  const [savedMsg, setSavedMsg] = useState('');

  const [dailyRate, setDailyRate] = useState(300);
  const [grossSalary, setGrossSalary] = useState(30000);
  const [category, setCategory] = useState('Ingenieros y Licenciados');
  const [age, setAge] = useState(30);
  const [children, setChildren] = useState(0);
  const [ascendants, setAscendants] = useState(0);
  const [disability, setDisability] = useState(0);
  const [familySituation, setFamilySituation] = useState('single');
  const [dailyMealCard, setDailyMealCard] = useState(0);
  const [annualBonus, setAnnualBonus] = useState(0);
  const [bonusCalendar, setBonusCalendar] = useState('Anual (Dic)');
  const [annualChildSupport, setAnnualChildSupport] = useState(0);
  const [annualTraining, setAnnualTraining] = useState(0);
  const [hasLaptop, setHasLaptop] = useState(false);
  const [monthlyLaptop, setMonthlyLaptop] = useState(0);
  const [hasHealthInsurance, setHasHealthInsurance] = useState(false);
  const [monthlyHealthInsurance, setMonthlyHealthInsurance] = useState(0);
  const [monthlyExtraIT, setMonthlyExtraIT] = useState(0);
  const [monthlyLicenses, setMonthlyLicenses] = useState(0);
  const [otherIncomeIRPF, setOtherIncomeIRPF] = useState(0);
  const [otherIncomeSS, setOtherIncomeSS] = useState(0);
  const [taxFreeRemuneration, setTaxFreeRemuneration] = useState(0);
  const [costRows, setCostRows] = useState<CostRow[]>([]);
  const [concepts, setConcepts] = useState<Concept[]>([]);
  const [result, setResult] = useState<SimResult | null>(null);

  useEffect(() => {
    request<any>('/simulator/defaults').then((d: SimDefaults) => {
      setDefaults(d);
      if (d.coefDaysMonth) setCoefDaysMonth(d.coefDaysMonth);
      if (d.coefDaysYear) setCoefDaysYear(d.coefDaysYear);
    }).catch(() => {});
    request<any[]>('/concepts').then(setConcepts).catch(() => {});
    request<any>('/consultants').then(r => setConsultants(r.items || [])).catch(() => {});
  }, []);

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
            const s = typeof c.simulationInputs === 'string'
              ? JSON.parse(c.simulationInputs) : c.simulationInputs;
            if (s.grossAnnualSalary != null) setGrossSalary(s.grossAnnualSalary);
            if (s.category != null) setCategory(s.category);
            if (s.age != null) setAge(s.age);
            if (s.children != null) setChildren(s.children);
            if (s.ascendants != null) setAscendants(s.ascendants);
            if (s.disability != null) setDisability(s.disability);
            if (s.dailyRate != null) setDailyRate(s.dailyRate);
            if (s.costRows && Array.isArray(s.costRows)) setCostRows(s.costRows);
            if (s.familySituation != null) setFamilySituation(s.familySituation);
            if (s.dailyMealCard != null) setDailyMealCard(s.dailyMealCard);
            if (s.annualPerformanceBonus != null) setAnnualBonus(s.annualPerformanceBonus);
            if (s.annualChildSupport != null) setAnnualChildSupport(s.annualChildSupport);
            if (s.annualTraining != null) setAnnualTraining(s.annualTraining);
            if (s.hasLaptop != null) setHasLaptop(s.hasLaptop);
            if (s.monthlyLaptop != null) setMonthlyLaptop(s.monthlyLaptop);
            if (s.hasHealthInsurance != null) setHasHealthInsurance(s.hasHealthInsurance);
            if (s.monthlyHealthInsurance != null) setMonthlyHealthInsurance(s.monthlyHealthInsurance);
            if (s.monthlyExtraIT != null) setMonthlyExtraIT(s.monthlyExtraIT);
            if (s.monthlyLicenses != null) setMonthlyLicenses(s.monthlyLicenses);
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

  const calc = useCallback(() => {
    const workingDays = defaults?.workingDays || [20,19,23,19,21,22,21,22,22,20,21,19];
    const body = {
      fees: feesCalc,
      annualWorkdays: coefDaysYear,
      age,
      category,
      grossAnnualSalary: grossSalary,
      dailyMealCard,
      annualPerformanceBonus: annualBonus,
      bonusCalendar,
      annualChildSupport,
      annualTraining,
      hasLaptop,
      monthlyLaptop,
      hasHealthInsurance,
      monthlyHealthInsurance,
      monthlyExtraIT,
      monthlyLicenses,
      otherCosts: totalMonthly * 12 + totalYearly,
      workingDays,
      children,
      ascendants,
      disability,
      familySituation,
      otherIncomeIRPF,
      otherIncomeSS,
      taxFreeRemuneration,
    };
    request<{ ok: boolean; result: SimResult }>('/simulator/calculate', {
      method: 'POST',
      body: JSON.stringify(body),
    }).then(d => {
      if (d?.result) setResult(d.result);
    }).catch(() => {});
  }, [feesCalc, coefDaysYear, age, category, grossSalary, dailyMealCard, annualBonus,
      bonusCalendar, annualChildSupport, annualTraining, hasLaptop, monthlyLaptop,
      hasHealthInsurance, monthlyHealthInsurance, monthlyExtraIT, monthlyLicenses,
      totalMonthly, totalYearly, children, ascendants, disability, familySituation,
      otherIncomeIRPF, otherIncomeSS, taxFreeRemuneration, defaults]);

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
          tariff: dailyRate,
          coefPercentage: result.coef,
          coefMargin: result.coefMargin,
          managerBonus: result.managerBonus,
          coefProjection: JSON.stringify(result.monthlyProjection),
          inputs: JSON.stringify({
            fees: feesCalc, annualWorkdays: coefDaysYear, age, category,
            grossAnnualSalary: grossSalary, dailyMealCard, annualPerformanceBonus: annualBonus,
            bonusCalendar, annualChildSupport, annualTraining, hasLaptop, monthlyLaptop,
            hasHealthInsurance, monthlyHealthInsurance, monthlyExtraIT, monthlyLicenses,
            otherCosts: totalMonthly * 12 + totalYearly, workingDays: defaults?.workingDays,
            children, ascendants, disability, familySituation, otherIncomeIRPF, otherIncomeSS,
            taxFreeRemuneration, dailyRate, costRows,
          }),
        }),
      });
      if (res.ok) {
        setSavedMsg('Saved');
        setTimeout(() => setSavedMsg(''), 2000);
        if (onCoefSaved) onCoefSaved();
      } else {
        const err = await res.json().catch(() => ({ error: 'Error' }));
        setSavedMsg(err.error || 'Error');
      }
    } catch {
      setSavedMsg('Connection error');
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

      <div className="sticky top-0 z-10 bg-background pt-1 pb-3 mb-6 border-b">
        <div className="grid grid-cols-3 gap-3">
          <Card className="bg-emerald-50 dark:bg-emerald-950/20 border-emerald-200">
            <CardContent className="p-3 text-center">
              <p className="text-xs text-muted-foreground"><FormattedMessage id="simulator.coefPct" /></p>
              <p className="text-2xl font-bold text-emerald-700">
                {result ? `${pct(result.coef)}%` : '—'}
              </p>
            </CardContent>
          </Card>
          <Card className="bg-blue-50 dark:bg-blue-950/20 border-blue-200">
            <CardContent className="p-3 text-center">
              <p className="text-xs text-muted-foreground"><FormattedMessage id="simulator.margin" /></p>
              <p className="text-2xl font-bold text-blue-700">
                {result ? `€${fmt(result.coefMargin)}` : '—'}
              </p>
            </CardContent>
          </Card>
          <Card className="bg-amber-50 dark:bg-amber-950/20 border-amber-200">
            <CardContent className="p-3 text-center">
              <p className="text-xs text-muted-foreground"><FormattedMessage id="simulator.managerBonus" /></p>
              <p className="text-2xl font-bold text-amber-700">
                {result ? `€${result.managerBonus.toFixed(2)}` : '—'}
              </p>
            </CardContent>
          </Card>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="space-y-4">
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
                  {selectedConsultant ? `Save in ${selectedConsultant.name}` : intl.formatMessage({ id: 'simulator.saveToConsultant' })}
                </Button>
              </div>
              {savedMsg && (
                <div className={`text-xs text-center rounded p-1.5 ${savedMsg === 'Saved' ? 'bg-emerald-50 text-emerald-700' : 'bg-red-50 text-red-700'}`}>
                  {savedMsg}
                </div>
              )}
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="pb-2"><CardTitle className="text-sm"><FormattedMessage id="simulator.personalData" /></CardTitle></CardHeader>
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
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <Label><FormattedMessage id="simulator.familySituation" /></Label>
                  <select value={familySituation} onChange={e => setFamilySituation(e.target.value)}
                    className="flex h-8.5 w-full rounded-md border border-input bg-background px-3 py-1 text-sm">
                    <option value="single"><FormattedMessage id="simulator.single" /></option>
                    <option value="married"><FormattedMessage id="simulator.married" /></option>
                    <option value="other"><FormattedMessage id="simulator.other" /></option>
                  </select>
                </div>
                <div />
              </div>
              <div className="grid grid-cols-3 gap-3">
                <div>
                  <Label><FormattedMessage id="simulator.children" /></Label>
                  <Input type="number" value={children} onChange={e => setChildren(parseInt(e.target.value)||0)} />
                </div>
                <div>
                  <Label><FormattedMessage id="simulator.ascendants" /></Label>
                  <Input type="number" value={ascendants} onChange={e => setAscendants(parseInt(e.target.value)||0)} />
                </div>
                <div>
                  <Label><FormattedMessage id="simulator.disability" /></Label>
                  <Input type="number" value={disability} onChange={e => setDisability(parseInt(e.target.value)||0)} />
                </div>
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="pb-2"><CardTitle className="text-sm"><FormattedMessage id="simulator.salaryPrice" /></CardTitle></CardHeader>
            <CardContent className="space-y-3">
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <Label><FormattedMessage id="simulator.grossAnnual" /></Label>
                  <Input type="number" value={grossSalary} onChange={e => setGrossSalary(parseFloat(e.target.value)||0)} />
                </div>
                <div>
                  <Label><FormattedMessage id="simulator.priceDay" /></Label>
                  <Input type="number" value={dailyRate} onChange={e => setDailyRate(parseFloat(e.target.value)||0)} />
                </div>
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <Label><FormattedMessage id="simulator.workdays" /></Label>
                  <Input type="number" value={coefDaysMonth} disabled className="bg-muted" />
                </div>
                <div />
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <Label><FormattedMessage id="simulator.dailyMealCard" /></Label>
                  <Input type="number" value={dailyMealCard} onChange={e => setDailyMealCard(parseFloat(e.target.value)||0)} />
                </div>
                <div>
                  <Label><FormattedMessage id="simulator.annualBonus" /></Label>
                  <Input type="number" value={annualBonus} onChange={e => setAnnualBonus(parseFloat(e.target.value)||0)} />
                </div>
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <Label><FormattedMessage id="simulator.bonusSchedule" /></Label>
                  <select value={bonusCalendar} onChange={e => setBonusCalendar(e.target.value)}
                    className="flex h-8.5 w-full rounded-md border border-input bg-background px-3 py-1 text-sm">
                    {defaults?.schedules?.map((s: string) => <option key={s} value={s}>{s}</option>)}
                  </select>
                </div>
                <div>
                  <Label><FormattedMessage id="simulator.annualChildSupport" /></Label>
                  <Input type="number" value={annualChildSupport} onChange={e => setAnnualChildSupport(parseFloat(e.target.value)||0)} />
                </div>
              </div>
              <div>
                <Label><FormattedMessage id="simulator.annualTraining" /></Label>
                <Input type="number" value={annualTraining} onChange={e => setAnnualTraining(parseFloat(e.target.value)||0)} />
              </div>
              <div className="bg-muted/50 p-3 rounded-md">
                <div className="flex justify-between items-center">
                  <span className="text-xs text-muted-foreground"><FormattedMessage id="simulator.fees" /></span>
                  <span className="text-sm font-semibold">€{fmt(feesCalc)}</span>
                </div>
                <div className="text-xs text-muted-foreground mt-1">
                  {dailyRate} × {coefDaysMonth} work days
                </div>
              </div>
              {result && (
                <div className="grid grid-cols-2 lg:grid-cols-4 gap-2 mt-2">
                  <div className="bg-emerald-50 dark:bg-emerald-950/20 border border-emerald-200 rounded-md p-2">
                    <p className="text-xs text-muted-foreground"><FormattedMessage id="simulator.netMonthly" /></p>
                    <p className="text-sm font-bold text-emerald-700">€{fmt(result.netMonthlySalary)}</p>
                  </div>
                  <div className="bg-blue-50 dark:bg-blue-950/20 border border-blue-200 rounded-md p-2">
                    <p className="text-xs text-muted-foreground"><FormattedMessage id="simulator.totalCost" /></p>
                    <p className="text-sm font-bold text-blue-700">€{fmt(result.totalConsultantCost)}</p>
                  </div>
                  <div className="bg-purple-50 dark:bg-purple-950/20 border border-purple-200 rounded-md p-2">
                    <p className="text-xs text-muted-foreground"><FormattedMessage id="simulator.irpf" /></p>
                    <p className="text-sm font-bold text-purple-700">{pct(result.irpfRate)}%</p>
                  </div>
                  <div className="bg-amber-50 dark:bg-amber-950/20 border border-amber-200 rounded-md p-2">
                    <p className="text-xs text-muted-foreground"><FormattedMessage id="simulator.socialSecurity" /></p>
                    <p className="text-sm font-bold text-amber-700">{pct(result.ssRate)}%</p>
                  </div>
                </div>
              )}
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="pb-2"><CardTitle className="text-sm"><FormattedMessage id="simulator.benefitsEquipment" /></CardTitle></CardHeader>
            <CardContent className="space-y-3">
              <div className="flex items-center gap-2">
                <input type="checkbox" checked={hasLaptop} onChange={e => setHasLaptop(e.target.checked)} className="size-4" />
                <Label className="mb-0"><FormattedMessage id="simulator.hasLaptop" /></Label>
                {hasLaptop && <Input type="number" value={monthlyLaptop} onChange={e => setMonthlyLaptop(parseFloat(e.target.value)||0)} className="w-24 ml-auto" placeholder="€/mo" />}
              </div>
              <div className="flex items-center gap-2">
                <input type="checkbox" checked={hasHealthInsurance} onChange={e => setHasHealthInsurance(e.target.checked)} className="size-4" />
                <Label className="mb-0"><FormattedMessage id="simulator.hasHealthInsurance" /></Label>
                {hasHealthInsurance && <Input type="number" value={monthlyHealthInsurance} onChange={e => setMonthlyHealthInsurance(parseFloat(e.target.value)||0)} className="w-24 ml-auto" placeholder="€/mo" />}
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <Label><FormattedMessage id="simulator.monthlyExtraIT" /></Label>
                  <Input type="number" value={monthlyExtraIT} onChange={e => setMonthlyExtraIT(parseFloat(e.target.value)||0)} />
                </div>
                <div>
                  <Label><FormattedMessage id="simulator.monthlyLicenses" /></Label>
                  <Input type="number" value={monthlyLicenses} onChange={e => setMonthlyLicenses(parseFloat(e.target.value)||0)} />
                </div>
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="pb-2"><CardTitle className="text-sm"><FormattedMessage id="simulator.otherIncome" /></CardTitle></CardHeader>
            <CardContent className="grid grid-cols-3 gap-3">
              <div>
                <Label><FormattedMessage id="simulator.otherIncomeIRPF" /></Label>
                <Input type="number" value={otherIncomeIRPF} onChange={e => setOtherIncomeIRPF(parseFloat(e.target.value)||0)} />
              </div>
              <div>
                <Label><FormattedMessage id="simulator.otherIncomeSS" /></Label>
                <Input type="number" value={otherIncomeSS} onChange={e => setOtherIncomeSS(parseFloat(e.target.value)||0)} />
              </div>
              <div>
                <Label><FormattedMessage id="simulator.taxFreeRemuneration" /></Label>
                <Input type="number" value={taxFreeRemuneration} onChange={e => setTaxFreeRemuneration(parseFloat(e.target.value)||0)} />
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
                Total: €{totalMonthly.toFixed(2)}/mo
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
                Total: €{totalYearly.toFixed(2)}/yr (€{totalYearlyMonthly.toFixed(2)}/mo)
              </div>
            </CardContent>
          </Card>
        </div>

        <div className="space-y-4">
          <Card>
            <CardHeader className="pb-2"><CardTitle className="text-sm"><FormattedMessage id="simulator.salaryBreakdown" /></CardTitle></CardHeader>
            <CardContent className="space-y-3">
              <div className="grid grid-cols-2 gap-2 text-xs">
                <div className="flex justify-between p-2 bg-muted/30 rounded">
                  <span className="text-muted-foreground"><FormattedMessage id="simulator.grossAnnual" /></span>
                  <span className="font-semibold">€{fmt(grossSalary)}</span>
                </div>
                <div className="flex justify-between p-2 bg-muted/30 rounded">
                  <span className="text-muted-foreground"><FormattedMessage id="common.fees" /></span>
                  <span className="font-semibold">€{fmt(feesCalc)}</span>
                </div>
              </div>
              {result && (
                <>
                  <div className="grid grid-cols-2 gap-2 text-xs">
                    <div className="flex justify-between p-2 bg-green-50 dark:bg-green-950/20 border border-green-200 rounded">
                      <span className="text-muted-foreground"><FormattedMessage id="simulator.netMonthly" /></span>
                      <span className="font-semibold text-green-700">€{fmt(result.netMonthlySalary)}</span>
                    </div>
                    <div className="flex justify-between p-2 bg-slate-50 dark:bg-slate-800 border border-slate-200 rounded">
                      <span className="text-muted-foreground"><FormattedMessage id="simulator.totalCost" /></span>
                      <span className="font-semibold">€{fmt(result.totalConsultantCost)}</span>
                    </div>
                    <div className="flex justify-between p-2 bg-blue-50 dark:bg-blue-950/20 border border-blue-200 rounded">
                      <span className="text-muted-foreground"><FormattedMessage id="simulator.irpf" /></span>
                      <span className="font-semibold text-blue-700">€{fmt(result.monthlyIRPF)}</span>
                    </div>
                    <div className="flex justify-between p-2 bg-purple-50 dark:bg-purple-950/20 border border-purple-200 rounded">
                      <span className="text-muted-foreground"><FormattedMessage id="simulator.socialSecurity" /></span>
                      <span className="font-semibold text-purple-700">€{fmt(result.monthlySSC)}</span>
                    </div>
                  </div>
                  <div className="grid grid-cols-2 gap-2 text-xs">
                    <div className="flex justify-between p-2 bg-muted/30 rounded">
                      <span className="text-muted-foreground"><FormattedMessage id="simulator.irpfRate" /></span>
                      <span className="font-semibold">{pct(result.irpfRate)}%</span>
                    </div>
                    <div className="flex justify-between p-2 bg-muted/30 rounded">
                      <span className="text-muted-foreground"><FormattedMessage id="simulator.ssRate" /></span>
                      <span className="font-semibold">{pct(result.ssRate)}%</span>
                    </div>
                  </div>
                  <div className="border-t pt-2 mt-1">
                    <div className="flex justify-between items-center">
                      <span className="text-xs text-muted-foreground"><FormattedMessage id="simulator.coefPct" /></span>
                      <span className="text-xl font-bold text-emerald-700">{pct(result.coef)}%</span>
                    </div>
                    <div className="flex justify-between items-center mt-1">
                      <span className="text-xs text-muted-foreground"><FormattedMessage id="simulator.margin" /></span>
                      <span className="text-sm font-semibold">€{fmt(result.coefMargin)}</span>
                    </div>
                    <div className="flex justify-between items-center mt-1">
                      <span className="text-xs text-muted-foreground"><FormattedMessage id="simulator.managerBonus" /></span>
                      <span className="text-sm font-semibold text-amber-700">€{result.managerBonus.toFixed(2)}</span>
                    </div>
                    <div className="flex justify-between items-center mt-1">
                      <span className="text-xs text-muted-foreground"><FormattedMessage id="simulator.netAnnual" /></span>
                      <span className="text-sm font-semibold">€{fmt(result.netAnnualSalary)}</span>
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

  const filtered = concepts
    .filter(c => c.type === row.type && c.name.toLowerCase().includes(search.toLowerCase()));

  if (search && !filtered.find(m => m.name === search)) {
    filtered.unshift({ id: -1, name: search, type: row.type, defaultValue: 0 });
  }

  return (
    <div className="flex gap-2 items-start">
      <div className="relative flex-1">
        <Input placeholder={intl.formatMessage({ id: 'simulator.concept' })} value={search}
          onChange={e => { setSearch(e.target.value); onUpdate(row.id, 'concept', e.target.value); }}
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
