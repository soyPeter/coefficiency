import {useCallback, useEffect, useMemo, useState} from 'react';
import {
    Building2,
    Calendar,
    Clock,
    Download,
    Euro,
    Filter,
    Plus,
    Target,
    TrendingDown,
    TrendingUp,
    Users,
    X,
} from 'lucide-react';
import {FormattedMessage, useIntl} from 'react-intl';
import {Button} from '@/components/ui/button';
import {Card, CardContent, CardHeader, CardTitle} from '@/components/ui/card';
import {Input} from '@/components/ui/input';
import {Label} from '@/components/ui/label';
import {ScrollArea} from '@/components/ui/scroll-area';
import {Tabs, TabsContent, TabsList, TabsTrigger} from '@/components/ui/tabs';
import SimulatorPage from '@/pages/SimulatorPage';
import type {BillingSummary, Consultant, CreateConsultantRequest} from '@/types';
import { downloadCsv } from '@/hooks/useCsvExport';
import ConfirmDialog from '@/components/ConfirmDialog';
import DropdownInput from '@/components/consultants/DropdownInput';
import {ConsultantTable, type SortField} from '@/components/consultants/ConsultantTable';
import {ConsultantFilterBar, type CoefFilter, type TableFilter} from '@/components/consultants/ConsultantFilterBar';
import {
    createConsultant,
    deleteConsultant,
    fetchBillingMonthly,
    fetchBillingSummary,
    fetchConsultants,
    request,
    updateConsultant,
} from '@/api';
import {
    Bar,
    BarChart,
    CartesianGrid,
    Legend,
    Line,
    LineChart as ReLineChart,
    ResponsiveContainer,
    Tooltip,
    XAxis,
    YAxis,
} from 'recharts';

interface MonthlyRow {
    month: string;
    hires: number;
    terminations: number;
    avgCoef: number;
    totalBonus: number;
}

export default function ConsultantsPage() {
    const intl = useIntl();
    const [consultants, setConsultants] = useState<Consultant[]>([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);
    const [drawerOpen, setDrawerOpen] = useState(false);
    const [editing, setEditing] = useState<Consultant | null>(null);
    const [showConsultant, setShowConsultant] = useState<Consultant | null>(null);
    const [activeTab, setActiveTab] = useState('list');
    const [simulatorConsultantId, setSimulatorConsultantId] = useState<number | null>(null);
    const [sortField, setSortField] = useState<SortField>('id');
    const [sortDir, setSortDir] = useState<'asc' | 'desc'>('desc');
    const [searchQuery, setSearchQuery] = useState('');
    const [billing, setBilling] = useState<BillingSummary | null>(null);
    const [monthly, setMonthly] = useState<MonthlyRow[]>([]);
    const [coefAlertThreshold, setCoefAlertThreshold] = useState(0.15);
    const [positionTariffAlertPct, setPositionTariffAlertPct] = useState(15);
    const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const now = new Date();
    const currentMonthIdx = now.getMonth();
    const currentYear = now.getFullYear();
    const thisMonthLabel = `${monthNames[currentMonthIdx]} ${currentYear}`;
    const thisMonthBonus = useMemo(() => {
        const row = monthly.find(m => m.month === thisMonthLabel);
        return row ? row.totalBonus : 0;
    }, [monthly, thisMonthLabel]);
    const qtdBonus = useMemo(() => {
        const qStart = Math.floor(currentMonthIdx / 3) * 3;
        const labels = monthNames.slice(qStart, currentMonthIdx + 1).map(m => `${m} ${currentYear}`);
        return monthly.filter(m => labels.includes(m.month)).reduce((s, r) => s + r.totalBonus, 0);
    }, [monthly, currentMonthIdx, currentYear]);
    const ytdBonus = useMemo(() => {
        const labels = monthNames.slice(0, currentMonthIdx + 1).map(m => `${m} ${currentYear}`);
        return monthly.filter(m => labels.includes(m.month)).reduce((s, r) => s + r.totalBonus, 0);
    }, [monthly, currentMonthIdx, currentYear]);
    const qHires = useMemo(() => {
        const qStart = Math.floor(currentMonthIdx / 3) * 3;
        const labels = monthNames.slice(qStart, currentMonthIdx + 1).map(m => `${m} ${currentYear}`);
        return monthly.filter(m => labels.includes(m.month)).reduce((s, r) => s + r.hires, 0);
    }, [monthly, currentMonthIdx, currentYear]);
    const qTerminations = useMemo(() => {
        const qStart = Math.floor(currentMonthIdx / 3) * 3;
        const labels = monthNames.slice(qStart, currentMonthIdx + 1).map(m => `${m} ${currentYear}`);
        return monthly.filter(m => labels.includes(m.month)).reduce((s, r) => s + r.terminations, 0);
    }, [monthly, currentMonthIdx, currentYear]);
    const qNet = qHires - qTerminations;
    const qMonthsElapsed = (currentMonthIdx % 3) + 1;
    const qTarget = billing ? Math.ceil(billing.delta / 12) * qMonthsElapsed : 0;
    const totalBonusAllTime = useMemo(() => monthly.reduce((s, r) => s + r.totalBonus, 0), [monthly]);
    const firstYear = useMemo(() => {
        if (consultants.length === 0) return currentYear;
        return Math.min(...consultants.map(c => parseInt(c.startDate.slice(0, 4))));
    }, [consultants]);
    const [page, setPage] = useState(1);
    const [rowsPerPage, setRowsPerPage] = useState(25);
    const [pendingConfirm, setPendingConfirm] = useState<{
        title: string;
        message: string;
        destructive?: boolean;
        onConfirm: () => void
    } | null>(null);
    const [form, setForm] = useState<CreateConsultantRequest>({
        name: '', client: '', position: '',
        coef: 0, tariff: 0,
        startDate: new Date().toISOString().slice(0, 10), endDate: '',
        fees: 0, coefPercentage: 0, coefMargin: 0, managerBonus: 0,
    });

    const activeConsultants = useMemo(() => consultants.filter(c => !c.endDate), [consultants]);
    const clients = useMemo(() => [...new Set(consultants.map(c => c.client))].sort(), [consultants]);
    const positions = useMemo(() => [...new Set(consultants.map(c => c.position).filter(Boolean))].sort(), [consultants]);
    const avgCoefVal = activeConsultants.length > 0 ? activeConsultants.reduce((s, c) => s + c.coefPercentage, 0) / activeConsultants.length : 0;
    const toggleCoefFilter = (key: CoefFilter) => {
        setCoefFilter(f => f === key ? null : key);
        setPage(1);
    };
    const belowThreshold = activeConsultants.filter(c => c.coefPercentage < coefAlertThreshold).length;
    const aboveThreshold = activeConsultants.filter(c => c.coefPercentage > coefAlertThreshold * 1.25).length;
    const avgTariff = activeConsultants.length > 0 ? activeConsultants.reduce((s, c) => s + c.tariff, 0) / activeConsultants.length : 0;
    const computedThresholds = useMemo(() => {
        const byPosition: Record<string, number[]> = {};
        activeConsultants.forEach(c => {
            const pos = c.position || 'Unknown';
            if (!byPosition[pos]) byPosition[pos] = [];
            byPosition[pos].push(c.tariff);
        });
        const result: Record<string, number> = {};
        const margin = positionTariffAlertPct / 100;
        Object.entries(byPosition).forEach(([pos, tariffs]) => {
            if (tariffs.length < 2) {
                result[pos] = avgTariff * (1 - margin);
            } else {
                const avg = tariffs.reduce((s, t) => s + t, 0) / tariffs.length;
                result[pos] = avg * (1 - margin);
            }
        });
        return result;
    }, [activeConsultants, avgTariff, positionTariffAlertPct]);
    const belowTariffThreshold = useMemo(() =>
        activeConsultants.filter(c => {
            const threshold = c.position ? computedThresholds[c.position] : undefined;
            return threshold != null && c.tariff < threshold;
        }).length,
    [activeConsultants, computedThresholds]);
    const overAvgCount = activeConsultants.filter(c => c.coefPercentage > avgCoefVal).length;
    const underAvgCount = activeConsultants.filter(c => c.coefPercentage < avgCoefVal).length;
    const activeClientCount = useMemo(() => {
        const activeClients = new Set(activeConsultants.map(c => c.client));
        return activeClients.size;
    }, [activeConsultants]);
    const maxTariffC = useMemo(() => activeConsultants.length > 0 ? activeConsultants.reduce((a, b) => a.tariff > b.tariff ? a : b) : null, [activeConsultants]);
    const minTariffC = useMemo(() => activeConsultants.length > 0 ? activeConsultants.reduce((a, b) => a.tariff < b.tariff ? a : b) : null, [activeConsultants]);
    const [tableFilter, setTableFilter] = useState<TableFilter>('active');
    const [coefFilter, setCoefFilter] = useState<CoefFilter>(null);
    const [showBonus, setShowBonus] = useState(false);

    const load = useCallback(async () => {
        try {
            setError(null);
            setConsultants(await fetchConsultants());
        } catch (err) {
            setError(err instanceof Error ? err.message : intl.formatMessage({id: 'consultants.loadError'}));
        } finally {
            setLoading(false);
        }
    }, [intl]);

    useEffect(() => {
        load();
    }, [load]);

    useEffect(() => {
        fetchBillingSummary().then(setBilling).catch(e => console.error('Billing summary error:', e));
        fetchBillingMonthly().then(setMonthly).catch(e => console.error('Billing monthly error:', e));
        request<{ coefAlertThreshold?: number; positionTariffAlertPct?: number }>('/fiscal').then(d => {
            setCoefAlertThreshold(d.coefAlertThreshold ?? 0.15);
            setPositionTariffAlertPct(d.positionTariffAlertPct ?? 15);
        }).catch(e => console.error('Fiscal error:', e));
    }, []);

    const handleSort = (field: SortField) => {
        if (field === 'status' || field === 'profitability') return;
        if (sortField === field) {
            setSortDir(d => d === 'asc' ? 'desc' : 'asc');
        } else {
            setSortField(field);
            setSortDir(field === 'id' ? 'desc' : 'asc');
        }
    };

    const filteredAndSorted = useMemo(() => {
        let list = tableFilter === 'active' ? activeConsultants : tableFilter === 'terminated' ? consultants.filter(c => c.endDate) : [...consultants];
        if (coefFilter === 'overAvg') list = list.filter(c => c.coefPercentage > avgCoefVal);
        else if (coefFilter === 'underAvg') list = list.filter(c => c.coefPercentage < avgCoefVal);
        else if (coefFilter === 'belowThreshold') list = list.filter(c => c.coefPercentage < coefAlertThreshold);
        else if (coefFilter === 'aboveThresholdPlus') list = list.filter(c => c.coefPercentage > coefAlertThreshold * 1.25);
        if (searchQuery) {
            const q = searchQuery.toLowerCase();
            list = list.filter(c =>
                c.name.toLowerCase().includes(q) ||
                c.client.toLowerCase().includes(q) ||
                c.position.toLowerCase().includes(q)
            );
        }
        list.sort((a, b) => {
            const aVal = (a as Record<string, unknown>)[sortField];
            const bVal = (b as Record<string, unknown>)[sortField];
            const dir = sortDir === 'asc' ? 1 : -1;
            if (typeof aVal === 'string' && typeof bVal === 'string') return aVal.localeCompare(bVal) * dir;
            if (typeof aVal === 'number' && typeof bVal === 'number') return (aVal - bVal) * dir;
            if (aVal == null && bVal == null) return 0;
            if (aVal == null) return 1;
            if (bVal == null) return -1;
            return String(aVal).localeCompare(String(bVal)) * dir;
        });
        return list;
    }, [consultants, searchQuery, sortField, sortDir, tableFilter, activeConsultants, coefFilter, avgCoefVal, coefAlertThreshold]);

    const totalPages = Math.max(1, Math.ceil(filteredAndSorted.length / rowsPerPage));
    const paginated = filteredAndSorted.slice((page - 1) * rowsPerPage, page * rowsPerPage);

    const tenureBuckets = useMemo(() => {
        const buckets: Record<string, number> = {'<6m': 0, '6-12m': 0, '1-2a': 0, '2-3a': 0, '3a+': 0};
        consultants.forEach(c => {
            const d = c.daysInRole;
            if (d < 180) buckets['<6m']++; else if (d < 365) buckets['6-12m']++; else if (d < 730) buckets['1-2a']++; else if (d < 1095) buckets['2-3a']++; else buckets['3a+']++;
        });
        return Object.entries(buckets).map(([range, count]) => ({range, count}));
    }, [consultants]);

    const openNew = () => {
        setEditing(null);
        setForm({
            name: '',
            client: '',
            position: '',
            coef: 0,
            tariff: 0,
            startDate: new Date().toISOString().slice(0, 10),
            endDate: '',
            fees: 0,
            coefPercentage: 0,
            coefMargin: 0,
            managerBonus: 0
        });
        setDrawerOpen(true);
    };

    const openEdit = (c: Consultant) => {
        setEditing(c);
        setForm({
            name: c.name,
            client: c.client,
            position: c.position,
            coef: c.coef,
            tariff: c.tariff,
            startDate: c.startDate,
            endDate: c.endDate || '',
            fees: c.fees || 0,
            coefPercentage: c.coefPercentage || 0,
            coefMargin: c.coefMargin || 0,
            managerBonus: c.managerBonus || 0
        });
        setDrawerOpen(true);
    };

    const handleSave = async () => {
        if (editing) {
            setPendingConfirm({
                title: intl.formatMessage({id: 'common.confirm'}),
                message: intl.formatMessage({id: 'consultants.confirmUpdate'}, {name: editing.name}),
                onConfirm: async () => {
                    try {
                        await updateConsultant(editing.id, form);
                        setDrawerOpen(false);
                        load();
                    } catch (err) {
                        setError(err instanceof Error ? err.message : intl.formatMessage({id: 'consultants.saveError'}));
                    }
                },
            });
            return;
        }
        try {
            if (editing) {
                await updateConsultant(editing.id, form);
            } else {
                await createConsultant(form);
            }
            setDrawerOpen(false);
            load();
        } catch (err) {
            setError(err instanceof Error ? err.message : intl.formatMessage({id: 'consultants.saveError'}));
        }
    };

    const handleDelete = async (c: Consultant) => {
        setPendingConfirm({
            title: intl.formatMessage({id: 'common.confirm'}),
            message: intl.formatMessage({id: 'consultants.confirmDelete'}, {name: c.name, client: c.client}),
            destructive: true,
            onConfirm: async () => {
                try {
                    await deleteConsultant(c.id);
                    load();
                } catch (err) {
                    setError(err instanceof Error ? err.message : intl.formatMessage({id: 'consultants.deleteError'}));
                }
            },
        });
    };

    const fmt = (n: number, decimals = 2) => n.toLocaleString('es-ES', {
        minimumFractionDigits: decimals,
        maximumFractionDigits: decimals
    });
    const fmtPct = (n: number) => (n * 100).toFixed(1);

    if (loading) return <div className="p-5"><p><FormattedMessage id="consultants.loading"/></p></div>;

    return (
        <div className="p-5">
            {/* === Manager KPIs === */}
            {billing && (
                <div className="mb-6">
                    <div className="grid grid-cols-1 lg:grid-cols-5 gap-4 mb-6">
                        <div className="flex flex-col gap-4">
                            <Card className="border-l-4 border-l-blue-400">
                                <CardContent className="p-5">
                                    <div className="flex items-start justify-between mb-3">
                                        <p className="text-xs font-medium text-blue-600 uppercase tracking-wider"><FormattedMessage id="consultants.cardConsultants"/></p>
                                        <div className="p-2 rounded-lg bg-blue-50">
                                            <Users className="size-4 text-blue-600" />
                                        </div>
                                    </div>
                                    <p className="text-2xl font-bold">{activeConsultants.length}
                                        <span className="text-sm font-normal text-muted-foreground"> de {consultants.length}</span>
                                        <span className="text-xs font-normal text-muted-foreground ml-2"><FormattedMessage id="consultants.active"/></span>
                                    </p>
                                </CardContent>
                            </Card>
                            <Card className="border-l-4 border-l-purple-400">
                                <CardContent className="p-5">
                                    <div className="flex items-start justify-between mb-3">
                                        <p className="text-xs font-medium text-purple-600 uppercase tracking-wider"><FormattedMessage id="consultants.cardClients"/></p>
                                        <div className="p-2 rounded-lg bg-purple-50">
                                            <Building2 className="size-4 text-purple-600" />
                                        </div>
                                    </div>
                                    <p className="text-2xl font-bold">{activeClientCount}
                                        <span className="text-xs font-normal text-muted-foreground ml-2"><FormattedMessage id="consultants.withActiveConsultants"/></span>
                                    </p>
                                </CardContent>
                            </Card>
                        </div>
                        <Card className="border-l-4 border-l-indigo-400">
                            <CardContent className="p-5">
                                <div className="flex items-start justify-between mb-3">
                                    <p className="text-xs font-medium text-indigo-600 uppercase tracking-wider"><FormattedMessage id="consultants.cardRates"/></p>
                                    <div className="p-2 rounded-lg bg-indigo-50">
                                        <Euro className="size-4 text-indigo-600" />
                                    </div>
                                </div>
                                <div className="flex flex-col items-center justify-center py-2 border-b border-muted-foreground/10 mb-3">
                                    <p className="text-3xl font-bold">{fmt(avgTariff)} €</p>
                                    <p className="text-[10px] text-muted-foreground"><FormattedMessage id="consultants.avgRate"/></p>
                                </div>
                                <div className="flex items-center justify-around">
                                    <div className="text-center">
                                        <p className="text-xl font-bold">{maxTariffC ? fmt(maxTariffC.tariff) : '-'} €</p>
                                        <p className="text-[9px] text-muted-foreground">Máx</p>
                                    </div>
                                    <div className="w-px h-10 bg-muted-foreground/20" />
                                    <div className="text-center">
                                        <p className="text-xl font-bold">{minTariffC ? fmt(minTariffC.tariff) : '-'} €</p>
                                        <p className="text-[9px] text-muted-foreground">Mín</p>
                                    </div>
                                </div>
                            </CardContent>
                        </Card>
                        <Card className="border-l-4 border-l-emerald-400">
                            <CardContent className="p-5">
                                <div className="flex items-start justify-between mb-3">
                                    <p className="text-xs font-medium text-emerald-600 uppercase tracking-wider"><FormattedMessage id="consultants.cardCoef"/></p>
                                    <div className="p-2 rounded-lg bg-emerald-50">
                                        <TrendingUp className="size-4 text-emerald-600" />
                                    </div>
                                </div>
                                <div className="flex flex-col items-center justify-center py-2 border-b border-muted-foreground/10 mb-3">
                                    <p className="text-3xl font-bold">{(avgCoefVal * 100).toFixed(1)}%</p>
                                    <p className="text-[10px] text-muted-foreground"><FormattedMessage id="consultants.average"/></p>
                                </div>
                                <div className="flex items-center justify-around">
                                    <div className="text-center group">
                                        <div className="flex items-center justify-center gap-1">
                                            <TrendingUp className="size-3.5 text-emerald-500/60 shrink-0" />
                                            <button onClick={() => toggleCoefFilter('overAvg')} title="Filtrar"
                                                    className={`text-xl font-bold transition-colors ${coefFilter === 'overAvg' ? 'text-emerald-600 underline' : 'text-emerald-600 group-hover:text-emerald-800'}`}>
                                                {overAvgCount}
                                                <Filter className="size-2.5 opacity-0 group-hover:opacity-60 transition-opacity inline ml-0.5" />
                                            </button>
                                        </div>
                                        <p className="text-[9px] text-muted-foreground"><FormattedMessage id="consultants.aboveAverage"/></p>
                                    </div>
                                    <div className="text-center group">
                                        <div className="flex items-center justify-center gap-1">
                                            <TrendingDown className="size-3.5 text-red-400/60 shrink-0" />
                                            <button onClick={() => toggleCoefFilter('underAvg')} title="Filtrar"
                                                    className={`text-xl font-bold transition-colors ${coefFilter === 'underAvg' ? 'text-red-500 underline' : 'text-red-500 group-hover:text-red-700'}`}>
                                                {underAvgCount}
                                                <Filter className="size-2.5 opacity-0 group-hover:opacity-60 transition-opacity inline ml-0.5" />
                                            </button>
                                        </div>
                                        <p className="text-[9px] text-muted-foreground"><FormattedMessage id="consultants.belowAverage"/></p>
                                    </div>
                                </div>
                            </CardContent>
                        </Card>
                        <Card className="border-l-4 border-l-emerald-400">
                            <CardContent className="p-5">
                                <div className="flex items-start justify-between mb-3">
                                    <p className="text-xs font-medium text-emerald-600 uppercase tracking-wider"><FormattedMessage id="consultants.threshold"/></p>
                                    <div className="p-2 rounded-lg bg-emerald-50">
                                        <Target className="size-4 text-emerald-600" />
                                    </div>
                                </div>
                                <div className="flex flex-col items-center justify-center py-2 border-b border-muted-foreground/10 mb-3">
                                    <p className="text-3xl font-bold">{(coefAlertThreshold * 100).toFixed(0)}%</p>
                                    <p className="text-[10px] text-muted-foreground"><FormattedMessage id="consultants.threshold"/></p>
                                </div>
                                <div className="flex items-center justify-around">
                                    <div className="text-center group">
                                        <div className="flex items-center justify-center gap-1">
                                            <TrendingUp className="size-3.5 text-emerald-500/60 shrink-0" />
                                            <button onClick={() => toggleCoefFilter('aboveThresholdPlus')} title="Filtrar"
                                                    className={`text-xl font-bold transition-colors ${coefFilter === 'aboveThresholdPlus' ? 'text-emerald-600 underline' : 'text-emerald-600 group-hover:text-emerald-800'}`}>
                                                {aboveThreshold}
                                                <Filter className="size-2.5 opacity-0 group-hover:opacity-60 transition-opacity inline ml-0.5" />
                                            </button>
                                        </div>
                                        <p className="text-[9px] text-muted-foreground">                                        <FormattedMessage id="consultants.abovePeerThreshold"/></p>
                                    </div>
                                    <div className="text-center group">
                                        <div className="flex items-center justify-center gap-1">
                                            <TrendingDown className="size-3.5 text-red-400/60 shrink-0" />
                                            <button onClick={() => toggleCoefFilter('belowThreshold')} title="Filtrar"
                                                    className={`text-xl font-bold transition-colors ${coefFilter === 'belowThreshold' ? 'text-red-500 underline' : 'text-red-500 group-hover:text-red-700'}`}>
                                                {belowThreshold}
                                                <Filter className="size-2.5 opacity-0 group-hover:opacity-60 transition-opacity inline ml-0.5" />
                                            </button>
                                        </div>
                                        <p className="text-[9px] text-muted-foreground"><FormattedMessage id="consultants.belowThreshold"/></p>
                                    </div>
                                </div>
                            </CardContent>
                        </Card>
                        <Card className="border-l-4 border-l-amber-400">
                            <CardContent className="p-5">
                                <div className="flex items-start justify-between mb-3">
                                    <p className="text-xs font-medium text-amber-600 uppercase tracking-wider">Tarifa Mín.</p>
                                    <div className="p-2 rounded-lg bg-amber-50">
                                        <Target className="size-4 text-amber-600" />
                                    </div>
                                </div>
                                <div className="flex flex-col items-center justify-center py-2 border-b border-muted-foreground/10 mb-3">
                                    <p className="text-xl font-bold text-amber-700">{belowTariffThreshold}</p>
                                    <p className="text-[10px] text-muted-foreground">por debajo de tarifa mín.</p>
                                </div>
                                <div className="text-center">
                                    <p className="text-[9px] text-muted-foreground">Activos por debajo de su tarifa mínima por rol</p>
                                </div>
                            </CardContent>
                        </Card>
                    </div>
                    <p className="text-lg font-semibold text-muted-foreground mb-3"><FormattedMessage id="billing.periodLabelYear"/></p>
                    <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-4">
                        <Card>
                            <CardContent className="p-4 flex items-center gap-3">
                                <div className="p-2 rounded-lg bg-emerald-50 dark:bg-emerald-950/30"><TrendingUp
                                    className="size-5 text-emerald-600"/></div>
                                <div className="flex-1">
                                    <p className="text-xs text-muted-foreground"><FormattedMessage id="billing.hires"/>
                                    </p>
                                    <p className="text-xl font-bold text-emerald-700">
                                        {billing.hires}
                                        {billing.expectedHires > 0 && (
                                            <span
                                                className="text-sm font-normal text-muted-foreground"> +{billing.expectedHires} <FormattedMessage id="billing.expected"/></span>
                                        )}
                                    </p>
                                    {billing.delta > billing.hires + billing.expectedHires && (
                                        <p className="text-xs text-amber-600"><FormattedMessage id="billing.remaining"
                                                                                                values={{n: billing.delta - billing.hires - billing.expectedHires}}/>
                                        </p>
                                    )}
                                    {billing.hires + billing.expectedHires >= billing.delta && billing.delta > 0 && (
                                        <p className="text-xs text-emerald-600"><FormattedMessage
                                            id="billing.targetMet"/></p>
                                    )}
                                </div>
                            </CardContent>
                        </Card>
                        <Card>
                            <CardContent className="p-4 flex items-center gap-3">
                                <div className="p-2 rounded-lg bg-red-50 dark:bg-red-950/30"><TrendingDown
                                    className="size-5 text-red-600"/></div>
                                <div className="flex-1">
                                    <p className="text-xs text-muted-foreground"><FormattedMessage
                                        id="billing.terminations"/></p>
                                    <p className="text-xl font-bold text-red-700">
                                        {billing.terminations}
                                        {billing.expectedTerminations > 0 && (
                                            <span
                                                className="text-sm font-normal text-muted-foreground"> +{billing.expectedTerminations} <FormattedMessage id="billing.expected"/></span>
                                        )}
                                    </p>
                                </div>
                            </CardContent>
                        </Card>
                        <Card>
                            <CardContent className="p-4 flex items-center gap-3">
                                <div className="p-2 rounded-lg bg-indigo-50 dark:bg-indigo-950/30"><Target
                                    className="size-5 text-indigo-600"/></div>
                                <div className="flex-1">
                                    <p className="text-xs text-muted-foreground">Q Goal</p>
                                    <p className="text-xl font-bold text-indigo-700">
                                        {qHires - qTerminations}
                                        <span className="text-sm font-normal text-muted-foreground"> / {qTarget}</span>
                                    </p>
                                    {qNet >= qTarget ? (
                                        <p className="text-xs text-emerald-600">Over goal</p>
                                    ) : (
                                        <p className="text-xs text-amber-600">Behind goal</p>
                                    )}
                                </div>
                            </CardContent>
                        </Card>
                        <Card>
                            <CardContent className="p-4 flex items-center gap-3">
                                <div className="p-2 rounded-lg bg-amber-50 dark:bg-amber-950/30"><Target
                                    className="size-5 text-amber-600"/></div>
                                <div className="flex-1">
                                    <p className="text-xs text-muted-foreground"><FormattedMessage id="billing.delta"/>
                                    </p>
                                    <p className="text-xl font-bold text-amber-700">{billing.delta}</p>
                                    {billing.delta > 0 && (
                                        <div className="mt-1 w-full bg-muted rounded-full h-1.5">
                                            <div className="bg-amber-500 h-1.5 rounded-full transition-all"
                                                 style={{width: `${Math.min(100, (billing.hires / billing.delta) * 100)}%`}}/>
                                        </div>
                                    )}
                                </div>
                            </CardContent>
                        </Card>
                    </div>
                    {monthly.length > 0 && (
                        <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
                            <Card>
                                <CardHeader className="pb-2">
                                    <CardTitle className="text-sm"><FormattedMessage
                                        id="billing.hiresTerminationsPerMonth"/></CardTitle>
                                </CardHeader>
                                <CardContent>
                                    <ResponsiveContainer width="100%" height={200}>
                                        <BarChart data={monthly.map(m => ({
                                            month: m.month,
                                            hires: m.hires,
                                            terminations: m.terminations
                                        }))}>
                                            <CartesianGrid strokeDasharray="3 3" className="stroke-muted"/>
                                            <XAxis dataKey="month" tick={{fontSize: 11}}/>
                                            <YAxis allowDecimals={false} tick={{fontSize: 11}}/>
                                            <Tooltip/>
                                            <Legend/>
                                            <Bar dataKey="hires" name={intl.formatMessage({id: 'billing.hires'})}
                                                 stackId="a" fill="#10b981" radius={[4, 4, 0, 0]}/>
                                            <Bar dataKey="terminations"
                                                 name={intl.formatMessage({id: 'billing.terminations'})} stackId="a"
                                                 fill="#ef4444" radius={[4, 4, 0, 0]}/>
                                        </BarChart>
                                    </ResponsiveContainer>
                                </CardContent>
                            </Card>
                            <Card>
                                <CardHeader className="pb-2">
                                    <CardTitle className="text-sm"><FormattedMessage
                                        id="consultants.cumulativeNetChange"/></CardTitle>
                                </CardHeader>
                                <CardContent>
                                    <ResponsiveContainer width="100%" height={200}>
                                        <ReLineChart data={monthly.reduce((acc: { month: string; net: number }[], m, i) => {
                                            const prev = i > 0 ? acc[i - 1] : {net: 0};
                                            return [...acc, {month: m.month, net: prev.net + m.hires - m.terminations}];
                                        }, [])}>
                                            <CartesianGrid strokeDasharray="3 3" className="stroke-muted"/>
                                            <XAxis dataKey="month" tick={{fontSize: 11}}/>
                                            <YAxis tick={{fontSize: 11}}/>
                                            <Tooltip/>
                                            <Line type="monotone" dataKey="net" stroke="#6366f1" strokeWidth={2}
                                                  dot={{r: 3}}/>
                                        </ReLineChart>
                                    </ResponsiveContainer>
                                </CardContent>
                            </Card>
                        </div>
                    )}
                </div>
            )}
            <Tabs value={activeTab} onValueChange={setActiveTab} className="w-full">
                <TabsList className="mb-4">
                    <TabsTrigger value="list"><FormattedMessage id="consultants.title"/></TabsTrigger>
                    <TabsTrigger value="simulator"><FormattedMessage id="consultants.simulatorTab"/></TabsTrigger>
                </TabsList>

                <TabsContent value="list">
                    <div className="flex items-center justify-between mb-6">
                        <div>
                            <h1 className="text-2xl font-bold"><FormattedMessage id="consultants.title"/></h1>
                            <p className="text-sm text-muted-foreground">
                                <FormattedMessage id="consultants.subtitle" values={{count: consultants.length}}/>
                            </p>
                        </div>
                        <div className="flex gap-2">
                            <Button variant="outline" size="sm" onClick={() => {
                                const cols = ['name', 'client', 'position', 'startDate', 'endDate', 'daysInRole', 'status', 'coefPercentage', 'profitability', 'tariff', 'managerBonus'];
                                const rows = filteredAndSorted.map(c => ({
                                    name: c.name, client: c.client, position: c.position,
                                    startDate: c.startDate, endDate: c.endDate || 'Active',
                                    daysInRole: c.daysInRole,
                                    status: c.endDate ? 'Terminated' : 'Active',
                                    coefPercentage: `${(c.coefPercentage * 100).toFixed(1)}%`,
                                    profitability: c.profitabilityStatus || 'INSUFFICIENT_DATA',
                                    tariff: `${fmt(c.tariff)} €`,
                                    managerBonus: `${fmt(c.managerBonus)} €`,
                                }));
                                downloadCsv('consultants.csv', rows, cols);
                            }}><Download className="size-3.5 mr-1"/> <FormattedMessage id="common.exportCsv"/></Button>
                            <Button onClick={openNew}>
                                <Plus className="size-4"/> <FormattedMessage id="consultants.add"/>
                            </Button>
                        </div>
                    </div>

                    {error &&
                        <div className="mb-4 p-3 bg-destructive/10 text-destructive rounded-md text-sm">{error}</div>}

                    {/* Search + filter */}
                    <ConsultantFilterBar
                        searchQuery={searchQuery}
                        onSearchChange={q => { setSearchQuery(q); setPage(1); }}
                        tableFilter={tableFilter}
                        onTableFilterChange={f => { setTableFilter(f); setPage(1); }}
                        coefFilter={coefFilter}
                        onCoefFilterChange={f => { setCoefFilter(f); setPage(1); }}
                    />

                    <Card>
                        <CardContent className="p-0">
                            <ConsultantTable
                                consultants={paginated}
                                sortField={sortField}
                                sortDir={sortDir}
                                onSort={handleSort}
                                showBonus={showBonus}
                                onToggleBonus={() => setShowBonus(s => !s)}
                                coefAlertThreshold={coefAlertThreshold}
                                positionTariffThresholds={computedThresholds}
                                onShow={setShowConsultant}
                                onEdit={openEdit}
                                onDelete={handleDelete}
                                fmt={fmt}
                                emptyI18n={consultants.length === 0 ? 'consultants.empty' : 'common.noData'}
                            />
                        </CardContent>
                    </Card>

                    {/* Pagination */}
                    {totalPages > 1 && (
                        <div className="flex items-center justify-between mt-4 text-sm">
                            <div className="flex items-center gap-2">
                                <span className="text-muted-foreground"><FormattedMessage id="common.rows"/></span>
                                <select value={rowsPerPage} onChange={e => {
                                    setRowsPerPage(parseInt(e.target.value) || 25);
                                    setPage(1);
                                }}
                                        className="border rounded px-2 py-0.5 bg-background text-xs">
                                    {[10, 25, 50, 100].map(n => <option key={n} value={n}>{n}</option>)}
                                </select>
                                <span className="text-muted-foreground ml-2">{filteredAndSorted.length}
                                    <FormattedMessage id="common.total"/></span>
                            </div>
                            <div className="flex items-center gap-1">
                                <Button variant="outline" size="sm" disabled={page <= 1}
                                        onClick={() => setPage(p => p - 1)}>←</Button>
                                <span className="px-2 text-xs">{page} / {totalPages}</span>
                                <Button variant="outline" size="sm" disabled={page >= totalPages}
                                        onClick={() => setPage(p => p + 1)}>→</Button>
                            </div>
                        </div>
                    )}

                    {/* Consultant Scatter removed — moved to Facturación tab, replaced by Tenure */}

                    {/* Tenure / Antigüedad */}
                    {consultants.length > 0 && (
                        <Card className="mt-6">
                            <CardHeader className="pb-2"><CardTitle className="text-sm"><FormattedMessage
                                id="consultants.tenure"/></CardTitle></CardHeader>
                            <CardContent>
                                <ResponsiveContainer width="100%" height={220}>
                                    <BarChart data={tenureBuckets} layout="vertical">
                                        <CartesianGrid strokeDasharray="3 3" className="stroke-muted"/>
                                        <XAxis type="number" allowDecimals={false} tick={{fontSize: 11}}/>
                                        <YAxis type="category" dataKey="range" tick={{fontSize: 11}} width={40}/>
                                        <Tooltip/>
                                        <Bar dataKey="count" fill="#3b82f6" radius={[0, 4, 4, 0]}/>
                                    </BarChart>
                                </ResponsiveContainer>
                            </CardContent>
                        </Card>
                    )}

                    {/* Show modal */}
                    {showConsultant && (
                        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
                            <div className="fixed inset-0 bg-black/40" onClick={() => setShowConsultant(null)}/>
                            <div className="relative w-full max-w-md bg-background rounded-lg border shadow-lg">
                                <div className="flex items-center justify-between p-4 border-b">
                                    <h2 className="text-lg font-semibold">{showConsultant.name}</h2>
                                    <Button variant="ghost" onClick={() => setShowConsultant(null)}>
                                        <X className="size-4"/>
                                    </Button>
                                </div>
                                <ScrollArea className="p-4 max-h-[70vh]">
                                    <div className="space-y-4">
                                        <div className="grid grid-cols-2 gap-4">
                                            <div>
                                                <Label className="text-xs text-muted-foreground"><FormattedMessage
                                                    id="consultants.client"/></Label>
                                                <p className="text-sm font-medium">{showConsultant.client}</p>
                                            </div>
                                            <div>
                                                <Label className="text-xs text-muted-foreground"><FormattedMessage
                                                    id="consultants.position"/></Label>
                                                <p className="text-sm font-medium">{showConsultant.position}</p>
                                            </div>
                                        </div>
                                        <div className="grid grid-cols-3 gap-4">
                                            <div>
                                                <Label className="text-xs text-muted-foreground"><FormattedMessage
                                                    id="consultants.startDate"/></Label>
                                                <p className="text-sm font-medium">{showConsultant.startDate}</p>
                                            </div>
                                            <div>
                                                <Label className="text-xs text-muted-foreground"><FormattedMessage
                                                    id="consultants.endDate"/></Label>
                                                <p className="text-sm font-medium">{showConsultant.endDate ||
                                                    <FormattedMessage id="consultants.noEndDate"/>}</p>
                                            </div>
                                            <div>
                                                <Label className="text-xs text-muted-foreground"><FormattedMessage
                                                    id="consultants.daysInRole"/></Label>
                                                <p className="text-sm font-medium">{showConsultant.daysInRole}</p>
                                            </div>
                                        </div>
                                        <div className="border-t pt-3">
                                            <Label
                                                className="text-xs text-muted-foreground uppercase tracking-wider mb-2 block"><FormattedMessage
                                                id="consultants.coef"/></Label>
                                            <div className="grid grid-cols-2 gap-3">
                                                <div className="bg-muted/40 p-2 rounded">
                                                    <span className="text-xs text-muted-foreground"><FormattedMessage
                                                        id="consultants.coefPct"/></span>
                                                    <p className="text-lg font-bold text-emerald-700">{(showConsultant.coefPercentage ? showConsultant.coefPercentage : showConsultant.coef) * 100}%</p>
                                                </div>
                                                <div className="bg-muted/40 p-2 rounded">
                                                    <span className="text-xs text-muted-foreground"><FormattedMessage
                                                        id="consultants.dailyRate"/></span>
                                                    <p className="text-lg font-bold">{fmt(showConsultant.tariff)} €</p>
                                                </div>
                                                <div className="bg-muted/40 p-2 rounded">
                                                    <span className="text-xs text-muted-foreground"><FormattedMessage
                                                        id="common.fees"/></span>
                                                    <p className="text-lg font-bold">{fmt(showConsultant.fees)} €</p>
                                                </div>
                                                <div className="bg-muted/40 p-2 rounded">
                                                    <span className="text-xs text-muted-foreground"><FormattedMessage
                                                        id="consultants.coefMargin"/></span>
                                                    <p className="text-lg font-bold">{fmt(showConsultant.coefMargin)} €</p>
                                                </div>
                                                <div className="bg-muted/40 p-2 rounded col-span-2">
                                                    <span className="text-xs text-muted-foreground"><FormattedMessage
                                                        id="consultants.managerBonus"/></span>
                                                    <p className="text-lg font-bold text-amber-700">{fmt(showConsultant.managerBonus)} €</p>
                                                </div>
                                            </div>
                                        </div>
                                        {showConsultant.simulationInputs && showConsultant.grossMonthlySalary > 0 && (
                                            <details className="border-t pt-3 group">
                                                <summary className="text-xs text-muted-foreground uppercase tracking-wider mb-2 cursor-pointer hover:text-foreground select-none">
                                                    COEF Calculation Detail
                                                </summary>
                                                <div className="grid grid-cols-2 gap-3 mb-3 pt-2">
                                                    <div className="bg-muted/40 p-2 rounded">
                                                        <span className="text-xs text-muted-foreground">Gross Salary (monthly)</span>
                                                        <p className="text-sm font-semibold">{fmt(showConsultant.grossMonthlySalary)} €</p>
                                                    </div>
                                                    <div className="bg-muted/40 p-2 rounded">
                                                        <span className="text-xs text-muted-foreground">Net Salary (monthly)</span>
                                                        <p className="text-sm font-semibold">{fmt(showConsultant.netMonthlySalary)} €</p>
                                                    </div>
                                                    <div className="bg-muted/40 p-2 rounded">
                                                        <span className="text-xs text-muted-foreground">Net Salary (annual)</span>
                                                        <p className="text-sm font-semibold">{fmt(showConsultant.netAnnualSalary)} €</p>
                                                    </div>
                                                    <div className="bg-muted/40 p-2 rounded">
                                                        <span className="text-xs text-muted-foreground">IRPF Rate</span>
                                                        <p className="text-sm font-semibold">{(showConsultant.irpfRate * 100).toFixed(2)}%</p>
                                                    </div>
                                                    <div className="bg-muted/40 p-2 rounded">
                                                        <span className="text-xs text-muted-foreground">SS Rate</span>
                                                        <p className="text-sm font-semibold">{(showConsultant.ssRate * 100).toFixed(2)}%</p>
                                                    </div>
                                                    <div className="bg-muted/40 p-2 rounded">
                                                        <span className="text-xs text-muted-foreground">Monthly IRPF</span>
                                                        <p className="text-sm font-semibold">{fmt(showConsultant.monthlyIrpf)} €</p>
                                                    </div>
                                                    <div className="bg-muted/40 p-2 rounded">
                                                        <span className="text-xs text-muted-foreground">Monthly SS</span>
                                                        <p className="text-sm font-semibold">{fmt(showConsultant.monthlySs)} €</p>
                                                    </div>
                                                </div>
                                                {showConsultant.coefProjection && (() => {
                                                    try {
                                                        const proj = JSON.parse(showConsultant.coefProjection);
                                                        if (!Array.isArray(proj) || proj.length === 0) return null;
                                                        return (
                                                            <div>
                                                                <span className="text-xs text-muted-foreground uppercase tracking-wider mb-1 block">Monthly Projection</span>
                                                                <div className="overflow-x-auto">
                                                                    <table className="w-full text-xs border-collapse">
                                                                        <thead>
                                                                            <tr className="border-b bg-muted/30">
                                                                                <th className="text-left p-1">Month</th>
                                                                                <th className="text-right p-1">Days</th>
                                                                                <th className="text-right p-1">Gross</th>
                                                                                <th className="text-right p-1">SS</th>
                                                                                <th className="text-right p-1">IRPF</th>
                                                                                <th className="text-right p-1">Net</th>
                                                                            </tr>
                                                                        </thead>
                                                                        <tbody>
                                                                            {proj.map((row: { month: string; workingDays: number; gross: number; mealCard: number; childSupport: number; bonus: number; training: number; ss: number; irpf: number; neto: number }, i: number) => (
                                                                                <tr key={i} className="border-b border-dashed">
                                                                                    <td className="p-1">{row.month}</td>
                                                                                    <td className="text-right p-1">{row.workingDays}</td>
                                                                                    <td className="text-right p-1">{fmt(row.gross)} €</td>
                                                                                    <td className="text-right p-1">{fmt(row.ss)} €</td>
                                                                                    <td className="text-right p-1">{fmt(row.irpf)} €</td>
                                                                                    <td className="text-right p-1 font-medium">{fmt(row.neto)} €</td>
                                                                                </tr>
                                                                            ))}
                                                                        </tbody>
                                                                    </table>
                                                                </div>
                                                            </div>
                                                        );
                                                    } catch { return null; }
                                                })()}
                                            </details>
                                        )}
                                        <div className="border-t pt-3 flex gap-2">
                                            <Button variant="outline" className="flex-1" onClick={() => {
                                                const id = showConsultant?.id ?? null;
                                                setShowConsultant(null);
                                                setSimulatorConsultantId(id);
                                                setActiveTab('simulator');
                                            }}>
                                                <FormattedMessage id="consultants.openSimulator"/>
                                            </Button>
                                            <Button variant="secondary" className="flex-1"
                                                    onClick={() => setShowConsultant(null)}>
                                                <FormattedMessage id="common.close"/>
                                            </Button>
                                        </div>
                                    </div>
                                </ScrollArea>
                            </div>
                        </div>
                    )}

                    {/* Edit / New drawer */}
                    {drawerOpen && (
                        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
                            <div className="fixed inset-0 bg-black/40" onClick={() => setDrawerOpen(false)}/>
                            <div className="relative w-full max-w-md bg-background rounded-lg border shadow-lg">
                                <div className="flex items-center justify-between p-4 border-b">
                                    <h2 className="text-lg font-semibold">
                                        {editing ? <FormattedMessage id="consultants.editTitle"/> :
                                            <FormattedMessage id="consultants.new"/>}
                                    </h2>
                                    <Button variant="ghost" onClick={() => setDrawerOpen(false)}>
                                        <X className="size-4"/>
                                    </Button>
                                </div>
                                <ScrollArea className="p-4 max-h-[70vh]">
                                    <div className="space-y-4">
                                        <div>
                                            <Label htmlFor="name"><FormattedMessage id="consultants.name"/> *</Label>
                                            <Input id="name" value={form.name}
                                                   onChange={e => setForm({...form, name: e.target.value})}
                                                   placeholder={intl.formatMessage({id: 'consultants.placeholder.name'})}/>
                                        </div>
                                        <DropdownInput id="client"
                                                       label={`${intl.formatMessage({id: 'consultants.client'})} *`}
                                                       value={form.client} options={clients}
                                                       onChange={v => setForm({...form, client: v})}/>
                                        <DropdownInput id="position"
                                                       label={intl.formatMessage({id: 'consultants.position'})}
                                                       value={form.position} options={positions}
                                                       onChange={v => setForm({...form, position: v})}/>
                                        <div className="grid grid-cols-2 gap-4">
                                            <div>
                                                <Label htmlFor="startDate"><FormattedMessage
                                                    id="consultants.startDate"/></Label>
                                                <Input id="startDate" type="date" value={form.startDate}
                                                       onChange={e => setForm({...form, startDate: e.target.value})}/>
                                            </div>
                                            <div>
                                                <Label htmlFor="endDate"><FormattedMessage
                                                    id="consultants.endDate"/></Label>
                                                <Input id="endDate" type="date" value={form.endDate}
                                                       onChange={e => setForm({...form, endDate: e.target.value})}/>
                                            </div>
                                        </div>
                                        <div>
                                            <Label htmlFor="tariff"><FormattedMessage
                                                id="consultants.dailyRate"/> (€)</Label>
                                            <Input id="tariff" type="number" step="0.01" value={form.tariff || ''}
                                                   onChange={e => setForm({
                                                       ...form,
                                                       tariff: parseFloat(e.target.value) || 0
                                                   })}/>
                                        </div>
                                    </div>
                                    <div className="flex gap-3 mt-6 pt-4 border-t">
                                        <Button variant="secondary" className="flex-1"
                                                onClick={() => setDrawerOpen(false)}><FormattedMessage
                                            id="common.cancel"/></Button>
                                        <Button className="flex-1" onClick={handleSave}
                                                disabled={!form.name || !form.client}>
                                            {editing ? <FormattedMessage id="common.update"/> :
                                                <FormattedMessage id="common.create"/>}
                                        </Button>
                                    </div>
                                </ScrollArea>
                            </div>
                        </div>
                    )}
                </TabsContent>

                <TabsContent value="simulator">
                    <SimulatorPage embedded initialConsultantId={simulatorConsultantId} onCoefSaved={() => {
                        load();
                        setSimulatorConsultantId(null);
                    }}/>
                </TabsContent>
            </Tabs>
            <ConfirmDialog
                open={pendingConfirm !== null}
                onOpenChange={() => setPendingConfirm(null)}
                title={pendingConfirm?.title || ''}
                message={pendingConfirm?.message || ''}
                confirmText={intl.formatMessage({id: pendingConfirm?.destructive ? 'common.delete' : 'common.confirm'})}
                cancelText={intl.formatMessage({id: 'common.cancel'})}
                destructive={pendingConfirm?.destructive}
                onConfirm={() => pendingConfirm?.onConfirm()}
            />
        </div>
    );
}
