import { useEffect, useState } from 'react';
import { Plus, Trash2, Save, Download, Upload, Database, Lock, Loader2 } from 'lucide-react';
import { FormattedMessage, useIntl } from 'react-intl';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Button } from '@/components/ui/button';
import { ScrollArea } from '@/components/ui/scroll-area';
import ConfirmDialog from '@/components/ConfirmDialog';
import { useDumpBackups } from '@/hooks/useDumpBackups';
import { authHeaders, changePassword, createBackup, listBackups, restoreBackup, createDumpBackup, restoreDumpBackup, pruneDatabase } from '@/api';
import type { BackupFile } from '@/api';

const BASE = '/api';

const authFetch = (url: string, options?: RequestInit) =>
  fetch(url, { ...options, headers: { 'Content-Type': 'application/json', ...authHeaders(), ...(options?.headers as Record<string, string> || {}) } });
interface Concept { id: number; name: string; type: string; defaultValue: number; }

export default function ConfigPage() {
  const intl = useIntl();
  const [delta, setDelta] = useState('');
  const [saved, setSaved] = useState(false);
  const [concepts, setConcepts] = useState<Concept[]>([]);
  const [newName, setNewName] = useState('');
  const [newType, setNewType] = useState('monthly');
  const [newValue, setNewValue] = useState(0);
  const [workingDays, setWorkingDays] = useState<number[]>([]);
  const [brackets, setBrackets] = useState<any[]>([]);
  const [regionalBrackets, setRegionalBrackets] = useState<any[]>([]);
  const [ssConfig, setSSConfig] = useState<any[]>([]);
  const [savedFiscal, setSavedFiscal] = useState('');
  const [savedCoef, setSavedCoef] = useState('');
  const [savedTimeout, setSavedTimeout] = useState(false);
  const [coefDaysMonth, setCoefDaysMonth] = useState(21);
  const [totalWorkingDays, setTotalWorkingDays] = useState(0);
  const [gastosLIRPF, setGastosLIRPF] = useState(2000);
  const [lirpfExpenses, setLirpfExpenses] = useState(2000);
  const [coefAlertThreshold, setCoefAlertThreshold] = useState(0.15);
  const [autoLogoutTimeout, setAutoLogoutTimeout] = useState(15);
  const [pendingConfirm, setPendingConfirm] = useState<{ title: string; message: string; onConfirm: () => void } | null>(null);
  const [passwordMsg, setPasswordMsg] = useState('');
  const [pwOld, setPwOld] = useState('');
  const [pwNew1, setPwNew1] = useState('');
  const [pwNew2, setPwNew2] = useState('');
  const [backups, setBackups] = useState<BackupFile[]>([]);
  const [backupMsg, setBackupMsg] = useState('');
  const [dumpPw, setDumpPw] = useState('');
  const [dumpPw2, setDumpPw2] = useState('');
  const [restorePw, setRestorePw] = useState('');
  const [pruning, setPruning] = useState(false);
  const [params, setParams] = useState({
    coefMultiplier: 1.7, mngBonusPct: 0.05, insuranceMonths: 6, mealCardDays: 22,
    ssRate: 0.0635, ssContingencies: 0.047, ssUnemployment: 0.0155, ssTraining: 0.001,
    personalMinimum: 5550, deductionSpouse: 2150, deductionChild: 2400, deductionAsc: 1150, deductionDis: 3000,
  });
  const [mngBonusExcludedMonths, setMngBonusExcludedMonths] = useState<number[]>([]);
  const [tenureBonusAmount, setTenureBonusAmount] = useState(300);
  const [tenureBonusMonths, setTenureBonusMonths] = useState(3);
  const [quarterlyBonusAmount, setQuarterlyBonusAmount] = useState(500);
  const [positionTariffAlertPct, setPositionTariffAlertPct] = useState(0);
  const [savedMngBonus, setSavedMngBonus] = useState('');
  const [savedBonusPayout, setSavedBonusPayout] = useState('');
  const [savedTariffAlert, setSavedTariffAlert] = useState('');
  const [savedFamily, setSavedFamily] = useState('');
  const dump = useDumpBackups(authFetch);

  const loadBackups = async () => {
    try { setBackups(await listBackups()); } catch {}
  };

  useEffect(() => {
    authFetch(`${BASE}/settings`).then(r => r.json()).then(d => {
      setDelta(d.delta_annual || '12');
      setAutoLogoutTimeout(parseInt(d.autoLogoutTimeout) || 15);
    });
    loadConcepts();
    authFetch(`${BASE}/fiscal`).then(r => r.json()).then(d => {
      setWorkingDays(d.workingDays || []);
      setBrackets(d.brackets || []);
      setRegionalBrackets(d.regionalBrackets || []);
      setSSConfig(d.ssConfig || []);
      setCoefDaysMonth(d.coefDaysMonth || 21);
      setTotalWorkingDays(d.coefDaysYear || 0);
      setLirpfExpenses(d.gastosLIRPF ?? 2000);
      setCoefAlertThreshold(d.coefAlertThreshold ?? 0.15);
      setMngBonusExcludedMonths(Array.isArray(d.mng_bonus_excluded_months) ? d.mng_bonus_excluded_months : []);
      setTenureBonusAmount(d.tenure_bonus_amount ?? 300);
      setTenureBonusMonths(d.tenure_bonus_months ?? 3);
      setQuarterlyBonusAmount(d.quarterly_bonus_amount ?? 500);
      setPositionTariffAlertPct(d.position_tariff_alert_pct ?? 0);
      setParams({
        coefMultiplier: d.coefMultiplier ?? 1.7,
        mngBonusPct: d.mngBonusPct ?? 0.05,
        insuranceMonths: d.insuranceMonths ?? 6,
        mealCardDays: d.mealCardDays ?? 22,
        ssRate: d.ssRate ?? 0.0635,
        personalMinimum: d.personalMinimum ?? 5550,
        deductionSpouse: d.deduction_spouse ?? 2150,
        deductionChild: d.deductionChild ?? 2400,
        deductionAsc: d.deductionAsc ?? 1150,
        deductionDis: d.deductionDis ?? 3000,
      });
    });
  }, []);

  const handleSaveDelta = async () => {
    await authFetch(`${BASE}/settings`, {
      method: 'PUT', headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ annualDelta: delta }),
    });
    setSaved(true); setTimeout(() => setSaved(false), 3000);
  };

  const loadConcepts = () => authFetch(`${BASE}/concepts`).then(r => r.json()).then(setConcepts);

  const addConcept = async () => {
    if (!newName) return;
    await authFetch(`${BASE}/concepts`, {
      method: 'POST', headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: newName, type: newType, defaultValue: newValue }),
    });
    setNewName(''); setNewValue(0); loadConcepts();
  };

  const updateConcept = async (c: Concept) => {
    await authFetch(`${BASE}/concepts/${c.id}`, {
      method: 'PUT', headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: c.name, type: c.type, defaultValue: c.defaultValue }),
    });
    loadConcepts();
  };

  const deleteConcept = async (id: number) => {
    setPendingConfirm({
      title: intl.formatMessage({ id: 'common.confirm' }),
      message: intl.formatMessage({ id: 'config.confirmDelete' }),
      onConfirm: async () => {
        await authFetch(`${BASE}/concepts/${id}`, { method: 'DELETE' });
        loadConcepts();
      },
    });
    await authFetch(`${BASE}/concepts/${id}`, { method: 'DELETE' });
    loadConcepts();
  };

  const saveFiscal = async (type: string, data: any) => {
    const endpoint = type === 'params' ? 'params'
      : type === 'days' ? 'days'
      : type === 'brackets' ? 'brackets'
      : type === 'regional-brackets' ? 'regional-brackets'
      : type === 'ss' ? 'ss' : null;
    if (!endpoint) return;
    const res = await authFetch(`${BASE}/fiscal/${endpoint}`, {
      method: 'PUT', headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    });
    if (res.ok) {
      setSavedFiscal(type);
      setTimeout(() => setSavedFiscal(''), 3000);
    }
  };

  const saveSessionTimeout = async () => {
    await authFetch(`${BASE}/settings`, {
      method: 'PUT', headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ autoLogoutTimeout: String(autoLogoutTimeout) }),
    });
    setSavedTimeout(true);
    setTimeout(() => setSavedTimeout(false), 3000);
  };

  const saveFiscalSetting = async (key: string, value: string) => {
    await authFetch(`${BASE}/fiscal/${key}`, {
      method: 'PUT',
      body: JSON.stringify({ value }),
    });
  };

  const saveMngBonus = async () => {
    await saveFiscalSetting('mng_bonus_pct', String(params.mngBonusPct));
    await saveFiscalSetting('mng_bonus_excluded_months', JSON.stringify(mngBonusExcludedMonths));
    setSavedMngBonus('ok');
    setTimeout(() => setSavedMngBonus(''), 3000);
  };

  const saveFamilyThresholds = async () => {
    await saveFiscalSetting('personal_minimum', String(params.personalMinimum));
    await saveFiscalSetting('deduction_spouse', String(params.deductionSpouse));
    await saveFiscalSetting('deduction_child', String(params.deductionChild));
    await saveFiscalSetting('deduction_asc', String(params.deductionAsc));
    await saveFiscalSetting('deduction_dis', String(params.deductionDis));
    await saveFiscalSetting('lirpf_expenses', String(lirpfExpenses));
    setSavedFamily('ok');
    setTimeout(() => setSavedFamily(''), 3000);
  };

  const saveBonusPayouts = async () => {
    await saveFiscalSetting('tenure_bonus_amount', String(tenureBonusAmount));
    await saveFiscalSetting('tenure_bonus_months', String(tenureBonusMonths));
    await saveFiscalSetting('quarterly_bonus_amount', String(quarterlyBonusAmount));
    setSavedBonusPayout('ok');
    setTimeout(() => setSavedBonusPayout(''), 3000);
  };

  const saveTariffAlert = async () => {
    await saveFiscalSetting('position_tariff_alert_pct', String(positionTariffAlertPct));
    setSavedTariffAlert('ok');
    setTimeout(() => setSavedTariffAlert(''), 3000);
  };

  const saveParams = async () => {
    const res = await authFetch(`${BASE}/fiscal/params`, {
      method: 'PUT', headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ ...params, gastosLIRPF: lirpfExpenses, coefAlertThreshold }),
    });
    if (res.ok) {
      setSavedFiscal('params');
      setTimeout(() => setSavedFiscal(''), 3000);
      const d = await authFetch(`${BASE}/fiscal`).then(r => r.json());
      setParams({
        coefMultiplier: d.coefMultiplier ?? 1.7,
        mngBonusPct: d.mngBonusPct ?? 0.05,
        insuranceMonths: d.insuranceMonths ?? 6,
        mealCardDays: d.mealCardDays ?? 22,
        ssRate: d.ssRate ?? 0.0635,
        personalMinimum: d.personalMinimum ?? 5550,
        deductionSpouse: d.deduction_spouse ?? 2150,
        deductionChild: d.deductionChild ?? 2400,
        deductionAsc: d.deductionAsc ?? 1150,
        deductionDis: d.deductionDis ?? 3000,
      });
    }
  };

  return (
    <div className="p-5">
      <h1 className="text-2xl font-bold mb-6"><FormattedMessage id="config.title" /></h1>
      <Tabs defaultValue="delta">
        <TabsList className="mb-4">
          <TabsTrigger value="delta"><FormattedMessage id="config.deltaTab" /></TabsTrigger>
          <TabsTrigger value="concepts"><FormattedMessage id="config.conceptsTab" /></TabsTrigger>
          <TabsTrigger value="fiscal"><FormattedMessage id="config.fiscalTab" /></TabsTrigger>
          <TabsTrigger value="maintenance"><FormattedMessage id="config.maintenanceTab" /></TabsTrigger>
        </TabsList>

        <TabsContent value="delta">
          <div className="space-y-6">
            <Card>
              <CardHeader>
                <CardTitle className="text-base"><FormattedMessage id="config.deltaTitle" /></CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <p className="text-sm text-muted-foreground"><FormattedMessage id="config.deltaDescription" /></p>
                <div>
                  <Label htmlFor="delta"><FormattedMessage id="config.deltaLabel" /></Label>
                  <Input id="delta" type="number" value={delta} onChange={e => setDelta(e.target.value)} />
                </div>
                <Button onClick={handleSaveDelta}><FormattedMessage id="config.save" /></Button>
                {saved && <p className="text-sm text-emerald-600"><FormattedMessage id="config.saved" /></p>}
              </CardContent>
            </Card>
            <Card>
              <CardHeader>
                <CardTitle className="text-base"><FormattedMessage id="config.autoLogoutTimeout" /></CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <p className="text-sm text-muted-foreground"><FormattedMessage id="config.autoLogoutTimeoutHint" /></p>
                <div>
                  <Input type="number" min="1" max="120" value={autoLogoutTimeout}
                         onChange={e => setAutoLogoutTimeout(parseInt(e.target.value)||15)} />
                </div>
                <Button onClick={saveSessionTimeout}><FormattedMessage id="config.save" /></Button>
                {savedTimeout && <p className="text-sm text-emerald-600"><FormattedMessage id="config.saved" /></p>}
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle className="text-base"><Lock className="size-4 inline mr-1" /> <FormattedMessage id="config.changePassword" /></CardTitle>
              </CardHeader>
              <CardContent className="space-y-3">
                <div>
                  <Label><FormattedMessage id="config.currentPassword" /></Label>
                  <Input type="password" value={pwOld} onChange={e => setPwOld(e.target.value)} />
                </div>
                <div>
                  <Label><FormattedMessage id="config.newPassword" /></Label>
                  <Input type="password" value={pwNew1} onChange={e => setPwNew1(e.target.value)} />
                </div>
                <div>
                  <Label><FormattedMessage id="config.confirmPassword" /></Label>
                  <Input type="password" value={pwNew2} onChange={e => setPwNew2(e.target.value)} />
                </div>
                <Button onClick={async () => {
                  if (!pwOld || !pwNew1) { setPasswordMsg(intl.formatMessage({ id: 'common.error' })); return; }
                  if (pwNew1.length < 8) { setPasswordMsg(intl.formatMessage({ id: 'common.error' })); return; }
                  if (pwNew1 !== pwNew2) { setPasswordMsg(intl.formatMessage({ id: 'auth.passwordsDontMatch' })); return; }
                  try {
                    await changePassword(pwOld, pwNew1);
                    setPasswordMsg(intl.formatMessage({ id: 'config.passwordChanged' }));
                    setPwOld(''); setPwNew1(''); setPwNew2('');
                    setTimeout(() => setPasswordMsg(''), 3000);
                  } catch (e: any) { setPasswordMsg(e.message || intl.formatMessage({ id: 'common.error' })); }
                }}><FormattedMessage id="config.changePassword" /></Button>
                {passwordMsg && <p className={`text-sm ${passwordMsg === intl.formatMessage({ id: 'config.passwordChanged' }) ? 'text-emerald-600' : 'text-red-600'}`}>{passwordMsg}</p>}
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        <TabsContent value="concepts">
          <Card>
            <CardHeader>
              <CardTitle className="text-base"><FormattedMessage id="config.conceptsTitle" /></CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <p className="text-sm text-muted-foreground"><FormattedMessage id="config.conceptsDescription" /></p>

              <div className="overflow-auto">
                <table className="w-full">
                  <thead>
                    <tr className="border-b bg-muted/30">
                      <th className="text-left p-2 text-xs font-medium"><FormattedMessage id="config.conceptName" /></th>
                      <th className="text-left p-2 text-xs font-medium"><FormattedMessage id="config.conceptType" /></th>
                      <th className="text-right p-2 text-xs font-medium"><FormattedMessage id="config.conceptValue" /></th>
                      <th className="text-right p-2 text-xs font-medium"><FormattedMessage id="config.conceptActions" /></th>
                    </tr>
                  </thead>
                  <tbody>
                    {concepts.map(c => (
                      <tr key={c.id} className="border-b">
                        <td className="p-1">
                          <Input value={c.name} onChange={e => setConcepts(prev => prev.map(x => x.id === c.id ? {...x, name: e.target.value} : x))} className="h-7 text-sm" />
                        </td>
                        <td className="p-1">
                          <select value={c.type} onChange={e => setConcepts(prev => prev.map(x => x.id === c.id ? {...x, type: e.target.value} : x))}
                            className="h-7 w-full rounded border border-input bg-background text-sm px-1">
                            <option value="monthly">{intl.formatMessage({ id: 'config.monthly' })}</option>
                            <option value="yearly">{intl.formatMessage({ id: 'config.yearly' })}</option>
                          </select>
                        </td>
                        <td className="p-1">
                          <Input type="number" value={c.defaultValue} onChange={e => setConcepts(prev => prev.map(x => x.id === c.id ? {...x, defaultValue: parseFloat(e.target.value)||0} : x))} className="h-7 w-24 text-sm text-right" />
                        </td>
                        <td className="p-1 text-right">
                          <div className="flex gap-1 justify-end">
                            <Button variant="outline" size="sm" onClick={() => updateConcept(c)}><Save className="size-3" /></Button>
                            <Button variant="ghost" size="sm" onClick={() => deleteConcept(c.id)}><Trash2 className="size-3" /></Button>
                          </div>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>

              <div className="flex gap-2 items-end">
                <div className="flex-1">
                  <Label><FormattedMessage id="config.newConcept" /></Label>
                  <Input value={newName} onChange={e => setNewName(e.target.value)} />
                </div>
                <div>
                  <Label><FormattedMessage id="config.conceptType" /></Label>
                  <select value={newType} onChange={e => setNewType(e.target.value)}
                    className="flex h-8.5 w-full rounded-md border border-input bg-background px-3 py-1 text-sm">
                    <option value="monthly">{intl.formatMessage({ id: 'config.monthly' })}</option>
                    <option value="yearly">{intl.formatMessage({ id: 'config.yearly' })}</option>
                  </select>
                </div>
                <div>
                  <Label><FormattedMessage id="config.conceptValue" /></Label>
                  <Input type="number" value={newValue} onChange={e => setNewValue(parseFloat(e.target.value)||0)} className="w-24" />
                </div>
                <Button onClick={addConcept} disabled={!newName}><Plus className="size-4 mr-1" /> <FormattedMessage id="config.add" /></Button>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="fiscal">
          <div className="space-y-6">

            {/* Derived COEF values */}
            <Card>
              <CardHeader>
                <CardTitle className="text-base"><FormattedMessage id="config.coefParams" /></CardTitle>
              </CardHeader>
              <CardContent>
                <div className="grid grid-cols-2 gap-4 mb-4">
                  <div>
                    <Label className="text-xs text-muted-foreground"><FormattedMessage id="config.coefDaysMonth" /></Label>
                    <Input type="number" value={coefDaysMonth} onChange={e => setCoefDaysMonth(parseInt(e.target.value)||0)} className="h-9 text-lg font-bold" />
                    <p className="text-xs text-muted-foreground mt-1"><FormattedMessage id="config.coefDaysMonthHint" /></p>
                  </div>
                  <div>
                    <Label className="text-xs text-muted-foreground"><FormattedMessage id="config.coefDaysYear" /></Label>
                    <Input type="number" value={totalWorkingDays} onChange={e => setTotalWorkingDays(parseInt(e.target.value)||0)} className="h-9 text-lg font-bold" />
                    <p className="text-xs text-muted-foreground mt-1"><FormattedMessage id="config.coefDaysYearHint" /></p>
                  </div>
                </div>
                <Button size="sm" onClick={async () => {
                  await saveFiscal('params', { ...params, coefDaysMonth, coefDaysYear: totalWorkingDays });
                  setSavedCoef('coef');
                  setTimeout(() => setSavedCoef(''), 3000);
                }}>
                  <Save className="size-3.5 mr-1" /> <FormattedMessage id="config.saveCoefParams" />
                </Button>
                {savedCoef === 'coef' && <span className="text-sm text-emerald-600 ml-2"><FormattedMessage id="config.saved" /></span>}
              </CardContent>
            </Card>

            {/* Working Days */}
            <Card>
              <CardHeader>
                <CardTitle className="text-base"><FormattedMessage id="config.workingDaysMonth" /></CardTitle>
              </CardHeader>
              <CardContent>
                <div className="grid grid-cols-6 sm:grid-cols-12 gap-2 mb-4">
                  {['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'].map((m, i) => (
                    <div key={m}>
                      <Label className="text-xs">{m}</Label>
                      <Input type="number" value={workingDays[i] || 0} onChange={e => {
                        const n = [...workingDays]; n[i] = parseInt(e.target.value)||0; setWorkingDays(n);
                      }} className="h-8 text-sm text-center" />
                    </div>
                  ))}
                </div>
                <Button size="sm" onClick={() => saveFiscal('days', workingDays)}>
                  <Save className="size-3.5 mr-1" /> <FormattedMessage id="config.saveWorkingDays" />
                </Button>
                {savedFiscal === 'days' && <span className="text-sm text-emerald-600 ml-2"><FormattedMessage id="config.saved" /></span>}
              </CardContent>
            </Card>
            {/* Card Multipliers */}
            <Card>
              <CardHeader>
                <CardTitle className="text-base"><FormattedMessage id="config.cardMultipliers" /></CardTitle>
              </CardHeader>
              <CardContent>
                <div className="max-w-xs">
                  <Label><FormattedMessage id="config.coefMultiplier" /></Label>
                  <Input type="number" step="0.01" value={params.coefMultiplier}
                         onChange={e => setParams({...params, coefMultiplier: parseFloat(e.target.value)||0})} />
                </div>
                <Button size="sm" className="mt-4" onClick={async () => {
                  await saveFiscalSetting('coef_multiplier', String(params.coefMultiplier));
                  setSavedFiscal('multiplier');
                  setTimeout(() => setSavedFiscal(''), 3000);
                }}>
                  <Save className="size-3.5 mr-1" /> <FormattedMessage id="config.save" />
                </Button>
                {savedFiscal === 'multiplier' && <span className="text-sm text-emerald-600 ml-2"><FormattedMessage id="config.saved" /></span>}
              </CardContent>
            </Card>

            {/* Card Manager Bonus */}
            <Card>
              <CardHeader>
                <CardTitle className="text-base"><FormattedMessage id="config.cardManagerBonus" /></CardTitle>
              </CardHeader>
              <CardContent>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                  <div>
                    <Label><FormattedMessage id="config.mngBonusPct" /></Label>
                    <Input type="number" step="0.001" value={params.mngBonusPct}
                           onChange={e => setParams({...params, mngBonusPct: parseFloat(e.target.value)||0})} />
                  </div>
                </div>
                <div className="mt-4">
                  <Label className="text-xs text-muted-foreground mb-1 block"><FormattedMessage id="config.mngBonusExcludedMonths" /></Label>
                  <div className="flex flex-wrap gap-2">
                    {['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'].map((m, i) => {
                      const monthNum = i + 1;
                      const checked = mngBonusExcludedMonths.includes(monthNum);
                      return (
                        <label key={m} className={`flex items-center gap-1 px-2 py-1 rounded text-xs cursor-pointer border ${checked ? 'bg-amber-100 border-amber-300 text-amber-800' : 'bg-muted/30 border-border'}`}>
                          <input type="checkbox" checked={checked} onChange={() => {
                            const next = checked
                              ? mngBonusExcludedMonths.filter(n => n !== monthNum)
                              : [...mngBonusExcludedMonths, monthNum].sort((a, b) => a - b);
                            setMngBonusExcludedMonths(next);
                          }} className="sr-only" />
                          {m}
                        </label>
                      );
                    })}
                  </div>
                </div>
                <Button size="sm" className="mt-4" onClick={saveMngBonus}>
                  <Save className="size-3.5 mr-1" /> <FormattedMessage id="config.save" />
                </Button>
                {savedMngBonus === 'ok' && <span className="text-sm text-emerald-600 ml-2"><FormattedMessage id="config.saved" /></span>}
              </CardContent>
            </Card>

            {/* Card SS Benefits */}
            <Card>
              <CardHeader>
                <CardTitle className="text-base"><FormattedMessage id="config.cardSsBenefits" /></CardTitle>
              </CardHeader>
              <CardContent>
                <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
                  <div>
                    <Label><FormattedMessage id="config.ssRate" /></Label>
                    <Input type="number" step="0.0001" value={params.ssRate}
                           onChange={e => setParams({...params, ssRate: parseFloat(e.target.value)||0})} />
                  </div>
                  <div>
                    <Label><FormattedMessage id="config.insuranceMonths" /></Label>
                    <Input type="number" value={params.insuranceMonths}
                           onChange={e => setParams({...params, insuranceMonths: parseInt(e.target.value)||0})} />
                  </div>
                  <div>
                    <Label><FormattedMessage id="config.mealCardDays" /></Label>
                    <Input type="number" value={params.mealCardDays}
                           onChange={e => setParams({...params, mealCardDays: parseInt(e.target.value)||0})} />
                  </div>
                </div>
                <Button size="sm" className="mt-4" onClick={async () => {
                  await saveFiscalSetting('ss_rate', String(params.ssRate));
                  await saveFiscalSetting('insurance_months', String(params.insuranceMonths));
                  await saveFiscalSetting('meal_card_days', String(params.mealCardDays));
                  setSavedFiscal('ssbenefits');
                  setTimeout(() => setSavedFiscal(''), 3000);
                }}>
                  <Save className="size-3.5 mr-1" /> <FormattedMessage id="config.save" />
                </Button>
                {savedFiscal === 'ssbenefits' && <span className="text-sm text-emerald-600 ml-2"><FormattedMessage id="config.saved" /></span>}
              </CardContent>
            </Card>

            {/* Family Thresholds */}
            <Card>
              <CardHeader>
                <CardTitle className="text-base"><FormattedMessage id="config.familyThresholds" /></CardTitle>
              </CardHeader>
              <CardContent>
                <div className="overflow-auto">
                  <table className="w-full">
                    <thead>
                      <tr className="border-b bg-muted/30">
                        <th className="text-left p-2 text-xs"><FormattedMessage id="config.conceptName" /></th>
                        <th className="text-right p-2 text-xs"><FormattedMessage id="common.amount" /></th>
                      </tr>
                    </thead>
                    <tbody>
                      {[
                        { key: 'personalMinimum', label: intl.formatMessage({ id: 'config.personalMinimum' }), value: params.personalMinimum },
                        { key: 'deductionSpouse', label: intl.formatMessage({ id: 'config.deductionSpouse' }), value: params.deductionSpouse },
                        { key: 'deductionChild', label: intl.formatMessage({ id: 'config.deductionChild' }), value: params.deductionChild },
                        { key: 'deductionAsc', label: intl.formatMessage({ id: 'config.deductionAsc' }), value: params.deductionAsc },
                        { key: 'deductionDis', label: intl.formatMessage({ id: 'config.deductionDis' }), value: params.deductionDis },
                        { key: 'lirpfExpenses', label: intl.formatMessage({ id: 'config.lirpfExpenses' }), value: lirpfExpenses },
                      ].map((row) => (
                        <tr key={row.key} className="border-b">
                          <td className="p-2 text-sm">{row.label}</td>
                          <td className="p-1">
                            <Input type="number" step="0.01" value={row.value} onChange={e => {
                              if (row.key === 'lirpfExpenses') {
                                setLirpfExpenses(parseFloat(e.target.value)||0);
                              } else {
                                setParams({...params, [row.key]: parseFloat(e.target.value)||0});
                              }
                            }} className="h-7 text-sm text-right w-32 ml-auto" />
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
                <Button size="sm" className="mt-4" onClick={saveFamilyThresholds}>
                  <Save className="size-3.5 mr-1" /> <FormattedMessage id="config.save" />
                </Button>
                {savedFamily === 'ok' && <span className="text-sm text-emerald-600 ml-2"><FormattedMessage id="config.saved" /></span>}
              </CardContent>
            </Card>

            {/* Position Tariff Alert */}
            <Card>
              <CardHeader>
                <CardTitle className="text-base"><FormattedMessage id="config.positionTariffAlertPct" /></CardTitle>
              </CardHeader>
              <CardContent>
                <div className="max-w-xs">
                  <Label><FormattedMessage id="config.positionTariffAlertPct" /></Label>
                  <Input type="number" step="1" value={positionTariffAlertPct}
                         onChange={e => setPositionTariffAlertPct(parseFloat(e.target.value)||0)} />
                  <p className="text-xs text-muted-foreground mt-0.5"><FormattedMessage id="config.positionTariffAlertPctHint" /></p>
                </div>
                <Button size="sm" className="mt-4" onClick={saveTariffAlert}>
                  <Save className="size-3.5 mr-1" /> <FormattedMessage id="config.save" />
                </Button>
                {savedTariffAlert === 'ok' && <span className="text-sm text-emerald-600 ml-2"><FormattedMessage id="config.saved" /></span>}
              </CardContent>
            </Card>

            {/* Bonus Payouts */}
            <Card>
              <CardHeader>
                <CardTitle className="text-base"><FormattedMessage id="config.cardBonusPayouts" /></CardTitle>
              </CardHeader>
              <CardContent>
                <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
                  <div>
                    <Label><FormattedMessage id="config.tenureBonusAmount" /></Label>
                    <Input type="number" value={tenureBonusAmount}
                           onChange={e => setTenureBonusAmount(parseFloat(e.target.value)||0)} />
                    <p className="text-xs text-muted-foreground mt-0.5"><FormattedMessage id="config.tenureBonusAmountHint" /></p>
                  </div>
                  <div>
                    <Label><FormattedMessage id="config.tenureBonusMonths" /></Label>
                    <Input type="number" value={tenureBonusMonths}
                           onChange={e => setTenureBonusMonths(parseInt(e.target.value)||0)} />
                    <p className="text-xs text-muted-foreground mt-0.5"><FormattedMessage id="config.tenureBonusMonthsHint" /></p>
                  </div>
                  <div>
                    <Label><FormattedMessage id="config.quarterlyBonusAmount" /></Label>
                    <Input type="number" value={quarterlyBonusAmount}
                           onChange={e => setQuarterlyBonusAmount(parseFloat(e.target.value)||0)} />
                    <p className="text-xs text-muted-foreground mt-0.5"><FormattedMessage id="config.quarterlyBonusAmountHint" /></p>
                  </div>
                </div>
                <Button size="sm" className="mt-4" onClick={saveBonusPayouts}>
                  <Save className="size-3.5 mr-1" /> <FormattedMessage id="config.save" />
                </Button>
                {savedBonusPayout === 'ok' && <span className="text-sm text-emerald-600 ml-2"><FormattedMessage id="config.saved" /></span>}
              </CardContent>
            </Card>

            {/* Coef Alert Threshold */}
            <Card>
              <CardHeader>
                <CardTitle className="text-base"><FormattedMessage id="config.cardThresholds" /></CardTitle>
              </CardHeader>
              <CardContent>
                <div className="max-w-xs">
                  <Label><FormattedMessage id="config.coefAlertThreshold" /></Label>
                  <Input type="number" step="0.01" value={coefAlertThreshold}
                         onChange={e => setCoefAlertThreshold(parseFloat(e.target.value)||0)} />
                  <p className="text-xs text-muted-foreground mt-0.5"><FormattedMessage id="config.coefAlertThresholdHint" /></p>
                </div>
                <Button size="sm" className="mt-4" onClick={async () => {
                  await saveFiscalSetting('coef_alert_threshold', String(coefAlertThreshold));
                  setSavedFiscal('threshold');
                  setTimeout(() => setSavedFiscal(''), 3000);
                }}>
                  <Save className="size-3.5 mr-1" /> <FormattedMessage id="config.save" />
                </Button>
                {savedFiscal === 'threshold' && <span className="text-sm text-emerald-600 ml-2"><FormattedMessage id="config.saved" /></span>}
              </CardContent>
            </Card>

            {/* IRPF Brackets */}
            <Card>
              <CardHeader>
                <CardTitle className="text-base"><FormattedMessage id="config.irpfBracketsNational" /></CardTitle>
              </CardHeader>
              <CardContent>
                <div className="overflow-auto">
                  <table className="w-full">
                    <thead>
                      <tr className="border-b bg-muted/30">
                        <th className="text-left p-2 text-xs"><FormattedMessage id="config.fromEuro" /></th>
                        <th className="text-left p-2 text-xs"><FormattedMessage id="config.toEuro" /></th>
                        <th className="text-right p-2 text-xs"><FormattedMessage id="config.ratePct" /></th>
                      </tr>
                    </thead>
                    <tbody>
                      {brackets.map((b, i) => (
                        <tr key={i} className="border-b">
                          <td className="p-1"><Input type="number" value={b.from} onChange={e => {
                            const n = [...brackets]; n[i] = {...n[i], from: parseFloat(e.target.value)||0}; setBrackets(n);
                          }} className="h-7 text-sm" /></td>
                          <td className="p-1"><Input type="number" value={b.to} onChange={e => {
                            const n = [...brackets]; n[i] = {...n[i], to: parseFloat(e.target.value)||0}; setBrackets(n);
                          }} className="h-7 text-sm" /></td>
                          <td className="p-1"><Input type="number" step="0.001" value={b.rate} onChange={e => {
                            const n = [...brackets]; n[i] = {...n[i], rate: parseFloat(e.target.value)||0}; setBrackets(n);
                          }} className="h-7 text-sm text-right" /></td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
                <Button size="sm" className="mt-4" onClick={() => saveFiscal('brackets', brackets)}>
                  <Save className="size-3.5 mr-1" /> <FormattedMessage id="config.saveBrackets" />
                </Button>
                {savedFiscal === 'brackets' && <span className="text-sm text-emerald-600 ml-2"><FormattedMessage id="config.saved" /></span>}
              </CardContent>
            </Card>

            {/* Regional IRPF Brackets */}
            <Card>
              <CardHeader>
                <CardTitle className="text-base"><FormattedMessage id="config.irpfBracketsRegional" /></CardTitle>
              </CardHeader>
              <CardContent>
                <div className="overflow-auto">
                  <table className="w-full">
                    <thead>
                      <tr className="border-b bg-muted/30">
                        <th className="text-left p-2 text-xs"><FormattedMessage id="config.fromEuro" /></th>
                        <th className="text-left p-2 text-xs"><FormattedMessage id="config.toEuro" /></th>
                        <th className="text-right p-2 text-xs"><FormattedMessage id="config.ratePct" /></th>
                      </tr>
                    </thead>
                    <tbody>
                      {regionalBrackets.map((b, i) => (
                        <tr key={i} className="border-b">
                          <td className="p-1"><Input type="number" value={b.from} onChange={e => {
                            const n = [...regionalBrackets]; n[i] = {...n[i], from: parseFloat(e.target.value)||0}; setRegionalBrackets(n);
                          }} className="h-7 text-sm" /></td>
                          <td className="p-1"><Input type="number" value={b.to} onChange={e => {
                            const n = [...regionalBrackets]; n[i] = {...n[i], to: parseFloat(e.target.value)||0}; setRegionalBrackets(n);
                          }} className="h-7 text-sm" /></td>
                          <td className="p-1"><Input type="number" step="0.001" value={b.rate} onChange={e => {
                            const n = [...regionalBrackets]; n[i] = {...n[i], rate: parseFloat(e.target.value)||0}; setRegionalBrackets(n);
                          }} className="h-7 text-sm text-right" /></td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
                <Button size="sm" className="mt-4" onClick={() => saveFiscal('regional-brackets', regionalBrackets)}>
                  <Save className="size-3.5 mr-1" /> <FormattedMessage id="config.saveRegionalBrackets" />
                </Button>
                <Button variant="outline" size="sm" className="mt-4 ml-2" onClick={() => setRegionalBrackets([...regionalBrackets, {from: 0, to: 0, rate: 0}])}>
                  <Plus className="size-3.5 mr-1" /> <FormattedMessage id="config.addBracket" />
                </Button>
                {savedFiscal === 'regional-brackets' && <span className="text-sm text-emerald-600 ml-2"><FormattedMessage id="config.saved" /></span>}
              </CardContent>
            </Card>

            {/* Cotizaciones SS */}
            <Card>
              <CardHeader>
                <CardTitle className="text-base"><FormattedMessage id="config.ssContributions" /></CardTitle>
              </CardHeader>
              <CardContent>
                <div className="grid grid-cols-3 gap-3 mb-3">
                  <div>
                    <Label><FormattedMessage id="config.contingencies" /></Label>
                    <Input type="number" step="0.0001" value={params.ssContingencies}
                           onChange={e => setParams({...params, ssContingencies: parseFloat(e.target.value)||0})} />
                  </div>
                  <div>
                    <Label><FormattedMessage id="config.unemployment" /></Label>
                    <Input type="number" step="0.0001" value={params.ssUnemployment}
                           onChange={e => setParams({...params, ssUnemployment: parseFloat(e.target.value)||0})} />
                  </div>
                  <div>
                    <Label><FormattedMessage id="config.training" /></Label>
                    <Input type="number" step="0.0001" value={params.ssTraining}
                           onChange={e => setParams({...params, ssTraining: parseFloat(e.target.value)||0})} />
                  </div>
                </div>
                <div className="bg-muted/50 p-2 rounded-md flex justify-between items-center">
                  <span className="text-xs text-muted-foreground"><FormattedMessage id="config.ssTotal" /></span>
                  <span className="text-sm font-bold">{(((+params.ssContingencies || 0) + (+params.ssUnemployment || 0) + (+params.ssTraining || 0)) * 100).toFixed(2)}%</span>
                </div>
              </CardContent>
            </Card>

            {/* SS Config */}
            <Card>
              <CardHeader>
                <CardTitle className="text-base"><FormattedMessage id="config.ssBases" /></CardTitle>
              </CardHeader>
              <CardContent>
                <div className="overflow-auto">
                  <table className="w-full">
                    <thead>
                      <tr className="border-b bg-muted/30">
                        <th className="text-left p-2 text-xs"><FormattedMessage id="config.categoryCol" /></th>
                        <th className="text-right p-2 text-xs"><FormattedMessage id="config.baseMin" /></th>
                        <th className="text-right p-2 text-xs"><FormattedMessage id="config.baseMax" /></th>
                        <th className="text-right p-2 text-xs"><FormattedMessage id="config.ratePct" /></th>
                      </tr>
                    </thead>
                    <tbody>
                      {ssConfig.map((s, i) => (
                        <tr key={i} className="border-b">
                          <td className="p-1 text-sm">{s.category}</td>
                          <td className="p-1"><Input type="number" step="0.01" value={s.baseMin} onChange={e => {
                            const n = [...ssConfig]; n[i] = {...n[i], baseMin: parseFloat(e.target.value)||0}; setSSConfig(n);
                          }} className="h-7 text-sm text-right" /></td>
                          <td className="p-1"><Input type="number" step="0.01" value={s.baseMax} onChange={e => {
                            const n = [...ssConfig]; n[i] = {...n[i], baseMax: parseFloat(e.target.value)||0}; setSSConfig(n);
                          }} className="h-7 text-sm text-right" /></td>
                          <td className="p-1"><Input type="number" step="0.0001" value={s.rate} onChange={e => {
                            const n = [...ssConfig]; n[i] = {...n[i], rate: parseFloat(e.target.value)||0}; setSSConfig(n);
                          }} className="h-7 text-sm text-right" /></td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
                <Button size="sm" className="mt-4" onClick={() => saveFiscal('ss', ssConfig)}>
                  <Save className="size-3.5 mr-1" /> <FormattedMessage id="config.saveSS" />
                </Button>
                {savedFiscal === 'ss' && <span className="text-sm text-emerald-600 ml-2"><FormattedMessage id="config.saved" /></span>}
              </CardContent>
            </Card>



          </div>
        </TabsContent>

        <TabsContent value="maintenance">
          <div className="space-y-6">

            {/* Encrypted Backups */}
            <Card>
              <CardHeader>
                <CardTitle className="text-base"><Download className="size-4 inline mr-1" /> Encrypted Backups</CardTitle>
              </CardHeader>
              <CardContent className="space-y-3">
                <p className="text-sm text-muted-foreground">Create and restore encrypted database snapshots.</p>
                <div className="flex gap-2">
                  <Button onClick={async () => {
                    try { await createBackup(); setBackupMsg('Backup created'); loadBackups(); } catch (e: any) { setBackupMsg(e.message); }
                    setTimeout(() => setBackupMsg(''), 3000);
                  }}><Download className="size-3.5 mr-1" /> Create Backup</Button>
                </div>
                <div className="overflow-auto max-h-48">
                  <table className="w-full text-xs">
                    <thead><tr className="bg-muted/50">{['Filename','Size','Date'].map(h => <th key={h} className="text-left p-1.5">{h}</th>)}</tr></thead>
                    <tbody>
                      {backups.filter(b => b.filename.startsWith('app.db.enc.')).map((b, i) => (
                        <tr key={i} className="border-t">
                          <td className="p-1.5 font-mono text-[10px]">{b.filename}</td>
                          <td className="p-1.5">{(b.size / 1024).toFixed(0)} KB</td>
                          <td className="p-1.5">{new Date(b.createdAt).toLocaleDateString()}</td>
                          <td className="p-1.5">
                            <Button variant="outline" size="sm" className="h-6 text-[10px]"
                              onClick={async () => {
                                setPendingConfirm({
                                  title: 'Restore Backup',
                                  message: `Restore ${b.filename}? Current data will be replaced.`,
                                  onConfirm: async () => { await restoreBackup(b.filename); setBackupMsg('Restored'); setTimeout(() => setBackupMsg(''), 3000); }
                                });
                              }}>Restore</Button>
                          </td>
                        </tr>
                      ))}
                      {backups.filter(b => b.filename.startsWith('app.db.enc.')).length === 0 && (
                        <tr><td colSpan={4} className="p-3 text-center text-muted-foreground">No backups yet</td></tr>
                      )}
                    </tbody>
                  </table>
                </div>
                <Button variant="outline" size="sm" onClick={loadBackups}>Refresh List</Button>
                {backupMsg && <p className="text-sm text-emerald-600">{backupMsg}</p>}
              </CardContent>
            </Card>

            {/* Dump Backups */}
            <Card>
              <CardHeader>
                <CardTitle className="text-base"><Upload className="size-4 inline mr-1" /> SQL Dump Backups</CardTitle>
              </CardHeader>
              <CardContent className="space-y-3">
                <p className="text-sm text-muted-foreground">Password-protected SQL dump (preserves users on restore).</p>
                <div className="flex gap-2 items-end">
                  <div>
                    <Label>Password</Label>
                    <Input type="password" value={dumpPw} onChange={e => setDumpPw(e.target.value)} className="h-8 w-40" />
                  </div>
                  <div>
                    <Label>Confirm</Label>
                    <Input type="password" value={dumpPw2} onChange={e => setDumpPw2(e.target.value)} className="h-8 w-40" />
                  </div>
                  <Button onClick={async () => {
                    if (!dumpPw || dumpPw !== dumpPw2) { setBackupMsg('Passwords must match'); return; }
                    if (dumpPw.length < 4) { setBackupMsg('Min 4 characters'); return; }
                    try { await createDumpBackup(dumpPw); setBackupMsg('Dump backup created'); setDumpPw(''); setDumpPw2(''); loadBackups(); } catch (e: any) { setBackupMsg(e.message); }
                    setTimeout(() => setBackupMsg(''), 3000);
                  }}>Create Dump</Button>
                </div>
                <div className="overflow-auto max-h-48">
                  <table className="w-full text-xs">
                    <thead><tr className="bg-muted/50">{['Filename','Size','Date',''].map(h => <th key={h} className="text-left p-1.5">{h}</th>)}</tr></thead>
                    <tbody>
                      {backups.filter(b => b.filename.startsWith('app.db.dump.')).map((b, i) => (
                        <tr key={i} className="border-t">
                          <td className="p-1.5 font-mono text-[10px]">{b.filename}</td>
                          <td className="p-1.5">{(b.size / 1024).toFixed(0)} KB</td>
                          <td className="p-1.5">{new Date(b.createdAt).toLocaleDateString()}</td>
                          <td className="p-1.5">
                            <div className="flex gap-1">
                              <Input type="password" placeholder="Pw" className="h-6 w-20 text-[10px]"
                                onChange={e => setRestorePw(e.target.value)} />
                              <Button variant="outline" size="sm" className="h-6 text-[10px]"
                                onClick={async () => {
                                  if (!restorePw) { setBackupMsg('Password required'); return; }
                                  try { await restoreDumpBackup(b.filename, restorePw); setBackupMsg('Dump restored'); } catch (e: any) { setBackupMsg(e.message); }
                                  setTimeout(() => setBackupMsg(''), 3000);
                                }}>Restore</Button>
                            </div>
                          </td>
                        </tr>
                      ))}
                      {backups.filter(b => b.filename.startsWith('app.db.dump.')).length === 0 && (
                        <tr><td colSpan={4} className="p-3 text-center text-muted-foreground">No dump backups yet</td></tr>
                      )}
                    </tbody>
                  </table>
                </div>
                <div className="border-t pt-4 mt-2">
                  <p className="text-sm font-medium mb-2">Restore from file</p>
                  <div className="space-y-2">
                    <Button variant="outline" size="sm" onClick={dump.chooseDumpFile} className="w-full justify-start text-xs">
                      <Upload className="size-3.5 mr-2" />
                      {dump.dumpUploadFile ? dump.dumpUploadFile.name : 'Choose backup file (app.db.dump.*)'}
                    </Button>
                    <Input type="password" placeholder="Backup password" className="h-8 text-xs"
                           value={dump.dumpUploadPassword}
                           onChange={e => dump.setDumpUploadPassword(e.target.value)} />
                    <Button size="sm" onClick={dump.uploadAndRestore}
                            disabled={!dump.dumpUploadFile || !dump.dumpUploadPassword} className="w-full">
                      {dump.uploadingDump ? <Loader2 className="size-3 animate-spin mr-1" /> : null}
                      Upload & Restore
                    </Button>
                    {dump.dumpUploadError && <p className="text-xs text-red-600">{dump.dumpUploadError}</p>}
                  </div>
                </div>
              </CardContent>
            </Card>

            {/* Prune */}
            <Card>
              <CardHeader>
                <CardTitle className="text-base"><Database className="size-4 inline mr-1" /> Prune Database</CardTitle>
              </CardHeader>
              <CardContent className="space-y-3">
                <p className="text-sm text-muted-foreground">Delete all business data (consultants, settings, concepts, bonuses) but keep user accounts.</p>
                <Button variant="destructive" disabled={pruning} onClick={() => {
                  setPendingConfirm({
                    title: 'Prune Database',
                    message: 'This will delete all consultants, settings, concepts, and bonuses. Users will be preserved. This cannot be undone.',
                    onConfirm: async () => {
                      setPruning(true);
                      try { await pruneDatabase(); setBackupMsg('Database pruned'); } catch (e: any) { setBackupMsg(e.message); }
                      setPruning(false);
                      setTimeout(() => setBackupMsg(''), 3000);
                    },
                  });
                }}>
                  <Trash2 className="size-3.5 mr-1" /> Prune Business Data
                </Button>
                {backupMsg && <p className="text-sm text-emerald-600">{backupMsg}</p>}
              </CardContent>
            </Card>

          </div>
        </TabsContent>
      </Tabs>
      <ConfirmDialog
        open={pendingConfirm !== null}
        onOpenChange={() => setPendingConfirm(null)}
        title={pendingConfirm?.title || ''}
        message={pendingConfirm?.message || ''}
        confirmText={intl.formatMessage({ id: 'common.delete' })}
        cancelText={intl.formatMessage({ id: 'common.cancel' })}
        destructive
        onConfirm={() => pendingConfirm?.onConfirm()}
      />
    </div>
  );
}
