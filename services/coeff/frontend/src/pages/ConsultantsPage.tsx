import {useCallback, useEffect, useMemo, useState} from 'react';
import {
    ArrowDown,
    ArrowUp,
    Eye,
    Pencil,
    Plus,
    Search,
    Target,
    Trash2,
    TrendingDown,
    TrendingUp,
    Users,
    X
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
import ConfirmDialog from '@/components/ConfirmDialog';
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

function DropdownInput({id, label, value, options, onChange}: {
    id: string; label: string; value: string; options: string[];
    onChange: (v: string) => void;
}) {
    const [open, setOpen] = useState(false);
    const [search, setSearch] = useState('');
    const [allowed, setAllowed] = useState(true);
    const intl = useIntl();

    const filtered = useMemo(() => {
        const existing = options.filter(o => o.toLowerCase().includes(search.toLowerCase()));
        if (!existing.includes(value) && value && search) {
            existing.unshift(value);
        }
        return existing;
    }, [options, search, value]);

    if (allowed) {
        return (
            <div className="relative">
                <Label htmlFor={id}>{label}</Label>
                <div className="flex gap-1">
                    <Input id={id} value={value} onChange={e => {
                        onChange(e.target.value);
                        setSearch(e.target.value);
                    }} onFocus={() => setOpen(true)} onBlur={() => setTimeout(() => setOpen(false), 200)}/>
                    <Button variant="outline" size="sm" type="button" onClick={() => setAllowed(false)}
                            className="shrink-0 mt-0.5" title={intl.formatMessage({id: 'common.search'})}>
                        <Search className="size-4"/>
                    </Button>
                </div>
                {open && filtered.length > 0 && (
                    <div
                        className="absolute z-10 w-full mt-1 bg-background border rounded-md shadow-lg max-h-40 overflow-auto">
                        {filtered.map((o, i) => (
                            <div key={i} className="px-3 py-1.5 text-sm cursor-pointer hover:bg-muted"
                                 onMouseDown={() => {
                                     onChange(o);
                                     setSearch(o);
                                     setOpen(false);
                                 }}>
                                {o}
                            </div>
                        ))}
                    </div>
                )}
            </div>
        );
    }

    return (
        <div>
            <Label htmlFor={id}>{label}</Label>
            <div className="flex gap-1">
                <select id={id} value={value} onChange={e => onChange(e.target.value)}
                        className="flex h-8.5 w-full rounded-md border border-input bg-background px-3 py-1 text-sm">
                    <option value="">-- {value || intl.formatMessage({id: 'common.select'})} --</option>
                    {options.filter(o => o).map((o, i) => <option key={i} value={o}>{o}</option>)}
                </select>
                <Button variant="outline" size="sm" type="button" onClick={() => setAllowed(true)}
                        className="shrink-0 mt-0.5" title={intl.formatMessage({id: 'common.write'})}>
                    <Pencil className="size-4"/>
                </Button>
            </div>
        </div>
    );
}

type SortField =
    'name'
    | 'client'
    | 'position'
    | 'startDate'
    | 'endDate'
    | 'daysInRole'
    | 'coefPercentage'
    | 'tariff'
    | 'managerBonus'
    | 'id';

const COLUMNS: { field: SortField; i18n: string; className: string }[] = [
    {field: 'name', i18n: 'consultants.name', className: 'text-left'},
    {field: 'client', i18n: 'consultants.client', className: 'text-left'},
    {field: 'position', i18n: 'consultants.position', className: 'text-left'},
    {field: 'startDate', i18n: 'consultants.startDate', className: 'text-right'},
    {field: 'endDate', i18n: 'consultants.endDate', className: 'text-right'},
    {field: 'daysInRole', i18n: 'consultants.daysInRole', className: 'text-right'},
    {field: 'coefPercentage', i18n: 'consultants.coefPct', className: 'text-right'},
    {field: 'tariff', i18n: 'consultants.dailyRate', className: 'text-right'},
    {field: 'managerBonus', i18n: 'consultants.managerBonus', className: 'text-right'},
];

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

    const clients = useMemo(() => [...new Set(consultants.map(c => c.client))].sort(), [consultants]);
    const positions = useMemo(() => [...new Set(consultants.map(c => c.position).filter(Boolean))].sort(), [consultants]);
    const belowThreshold = consultants.filter(c => c.coefPercentage < coefAlertThreshold);

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
        fetchBillingSummary().then(setBilling);
        fetchBillingMonthly().then(setMonthly).catch(() => {
        });
        request<any>('/fiscal').then(d => setCoefAlertThreshold(d.coefAlertThreshold ?? 0.15)).catch(() => {
        });
    }, []);

    const handleSort = (field: SortField) => {
        if (sortField === field) {
            setSortDir(d => d === 'asc' ? 'desc' : 'asc');
        } else {
            setSortField(field);
            setSortDir(field === 'id' ? 'desc' : 'asc');
        }
    };

    const filteredAndSorted = useMemo(() => {
        let list = [...consultants];
        if (searchQuery) {
            const q = searchQuery.toLowerCase();
            list = list.filter(c =>
                c.name.toLowerCase().includes(q) ||
                c.client.toLowerCase().includes(q) ||
                c.position.toLowerCase().includes(q)
            );
        }
        list.sort((a, b) => {
            const aVal = a[sortField];
            const bVal = b[sortField];
            const dir = sortDir === 'asc' ? 1 : -1;
            if (typeof aVal === 'string' && typeof bVal === 'string') return aVal.localeCompare(bVal) * dir;
            if (typeof aVal === 'number' && typeof bVal === 'number') return (aVal - bVal) * dir;
            if (aVal == null && bVal == null) return 0;
            if (aVal == null) return 1;
            if (bVal == null) return -1;
            return String(aVal).localeCompare(String(bVal)) * dir;
        });
        return list;
    }, [consultants, searchQuery, sortField, sortDir]);

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
                    <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-4">
                        <Card>
                            <CardContent className="p-4 flex items-center gap-3">
                                <div className="p-2 rounded-lg bg-blue-50 dark:bg-blue-950/30"><Users
                                    className="size-5 text-blue-600"/></div>
                                <div>
                                    <p className="text-xs text-muted-foreground"><FormattedMessage
                                        id="billing.activeConsultants"/></p>
                                    <p className="text-xl font-bold">{billing.consultantCount}</p>
                                </div>
                            </CardContent>
                        </Card>
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
                                                className="text-sm font-normal text-muted-foreground"> +{billing.expectedHires}
                                                <FormattedMessage id="billing.expected"/></span>
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
                                                className="text-sm font-normal text-muted-foreground"> +{billing.expectedTerminations}
                                                <FormattedMessage id="billing.expected"/></span>
                                        )}
                                    </p>
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
                                        <ReLineChart data={monthly.reduce((acc: any[], m, i) => {
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
                        <Button onClick={openNew}>
                            <Plus className="size-4"/> <FormattedMessage id="consultants.add"/>
                        </Button>
                    </div>

                    {error &&
                        <div className="mb-4 p-3 bg-destructive/10 text-destructive rounded-md text-sm">{error}</div>}

                    {/* COEF Alert */}
                    {belowThreshold.length > 0 && (
                        <div
                            className="mb-4 p-3 bg-red-50 dark:bg-red-950/20 border border-red-200 rounded-md flex items-center gap-2">
                            <TrendingDown className="size-4 text-red-600"/>
                            <span className="text-sm text-red-700">
            <FormattedMessage id="consultants.belowThresholdAlert" values={{
                count: belowThreshold.length,
                threshold: (coefAlertThreshold * 100).toFixed(0)
            }}/>
          </span>
                        </div>
                    )}

                    {/* Search filter */}
                    <div className="relative mb-4 max-w-md">
                        <Search className="absolute left-2.5 top-1/2 -translate-y-1/2 size-4 text-muted-foreground"/>
                        <Input
                            placeholder={intl.formatMessage({id: 'consultants.search'})}
                            value={searchQuery}
                            onChange={e => {
                                setSearchQuery(e.target.value);
                                setPage(1);
                            }}
                            className="pl-8"
                        />
                    </div>

                    <Card>
                        <CardContent className="p-0">
                            <div className="overflow-auto">
                                <table className="w-full">
                                    <thead>
                                    <tr className="border-b bg-muted/50">
                                        {COLUMNS.map(col => (
                                            <th
                                                key={col.field}
                                                className={`p-3 text-xs font-medium text-muted-foreground cursor-pointer select-none hover:bg-muted ${col.className}`}
                                                onClick={() => handleSort(col.field)}
                                            >
                      <span className="inline-flex items-center gap-1">
                        <FormattedMessage id={col.i18n}/>
                          {sortField === col.field && (
                              sortDir === 'asc' ? <ArrowUp className="size-3"/> : <ArrowDown className="size-3"/>
                          )}
                      </span>
                                            </th>
                                        ))}
                                        <th className="text-right p-3 text-xs font-medium text-muted-foreground">
                                            <FormattedMessage id="consultants.actions"/>
                                        </th>
                                    </tr>
                                    </thead>
                                    <tbody>
                                    {paginated.map((c) => (
                                        <tr key={c.id} className="border-b hover:bg-muted/30">
                                            <td className="p-3 font-medium">{c.name}</td>
                                            <td className="p-3 text-sm">{c.client}</td>
                                            <td className="p-3 text-sm">{c.position}</td>
                                            <td className="p-3 text-sm text-right">{c.startDate}</td>
                                            <td className="p-3 text-sm text-right">{c.endDate ||
                                                <span className="text-muted-foreground"><FormattedMessage
                                                    id="consultants.noEndDate"/></span>}</td>
                                            <td className="p-3 text-sm text-right">{c.daysInRole}</td>
                                            <td className={`p-3 text-sm text-right font-semibold ${c.coefPercentage < coefAlertThreshold ? 'text-red-600 bg-red-50 dark:bg-red-950/20' : ''}`}>{(c.coefPercentage * 100).toFixed(1)}%</td>
                                            <td className="p-3 text-sm text-right">{fmt(c.tariff)} €</td>
                                            <td className="p-3 text-sm text-right">{fmt(c.managerBonus)} €</td>
                                            <td className="p-3 text-right">
                                                <div className="flex gap-1 justify-end">
                                                    <Button variant="ghost" size="sm"
                                                            onClick={() => setShowConsultant(c)}
                                                            title={intl.formatMessage({id: 'consultants.show'})}>
                                                        <Eye className="size-3.5"/>
                                                    </Button>
                                                    <Button variant="ghost" size="sm"
                                                            onClick={() => openEdit(c)}
                                                            title={intl.formatMessage({id: 'consultants.edit'})}>
                                                        <Pencil className="size-3.5"/>
                                                    </Button>
                                                    <Button variant="ghost" size="sm"
                                                            onClick={() => handleDelete(c)}
                                                            title={intl.formatMessage({id: 'consultants.delete'})}>
                                                        <Trash2 className="size-3.5 text-destructive"/>
                                                    </Button>
                                                </div>
                                            </td>
                                        </tr>
                                    ))}
                                    {consultants.length === 0 && (
                                        <tr>
                                            <td colSpan={11} className="p-6 text-center text-muted-foreground">
                                                <FormattedMessage id="consultants.empty"/></td>
                                        </tr>
                                    )}
                                    </tbody>
                                </table>
                            </div>
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

                    {/* Leaderboard: Top 5 + Bottom 5 by COEF% */}
                    {consultants.length > 0 && (
                        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mt-6">
                            <Card>
                                <CardHeader className="pb-2"><CardTitle className="text-sm"><FormattedMessage
                                    id="consultants.topCoef"/></CardTitle></CardHeader>
                                <CardContent className="p-0">
                                    <table className="w-full text-xs">
                                        <thead>
                                        <tr className="border-b bg-muted/30">
                                            <th className="text-left p-2"><FormattedMessage id="consultants.name"/></th>
                                            <th className="text-right p-2"><FormattedMessage id="consultants.coefPct"/>
                                            </th>
                                            <th className="text-right p-2"><FormattedMessage id="common.margin"/></th>
                                        </tr>
                                        </thead>
                                        <tbody>{[...consultants].sort((a, b) => b.coefPercentage - a.coefPercentage).slice(0, 5).map(c => (
                                            <tr key={c.id} className="border-b hover:bg-muted/30">
                                                <td className="p-2 font-medium">{c.name}</td>
                                                <td className="p-2 text-right font-semibold text-emerald-700">{fmtPct(c.coefPercentage)}%</td>
                                                <td className="p-2 text-right">{fmt(c.coefMargin)}€</td>
                                            </tr>
                                        ))}</tbody>
                                    </table>
                                </CardContent>
                            </Card>
                            <Card>
                                <CardHeader className="pb-2"><CardTitle className="text-sm"><FormattedMessage
                                    id="consultants.bottomCoef"/></CardTitle></CardHeader>
                                <CardContent className="p-0">
                                    <table className="w-full text-xs">
                                        <thead>
                                        <tr className="border-b bg-muted/30">
                                            <th className="text-left p-2"><FormattedMessage id="consultants.name"/></th>
                                            <th className="text-right p-2"><FormattedMessage id="consultants.coefPct"/>
                                            </th>
                                            <th className="text-right p-2"><FormattedMessage id="common.margin"/></th>
                                        </tr>
                                        </thead>
                                        <tbody>{[...consultants].sort((a, b) => a.coefPercentage - b.coefPercentage).slice(0, 5).map(c => (
                                            <tr key={c.id} className="border-b hover:bg-muted/30">
                                                <td className="p-2 font-medium">{c.name}</td>
                                                <td className="p-2 text-right font-semibold text-red-700">{fmtPct(c.coefPercentage)}%</td>
                                                <td className="p-2 text-right">{fmt(c.coefMargin)}€</td>
                                            </tr>
                                        ))}</tbody>
                                    </table>
                                </CardContent>
                            </Card>
                        </div>
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
                                                    <p className="text-lg font-bold text-emerald-700">{(showConsultant.coefPercentage * 100).toFixed(2)}%</p>
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
