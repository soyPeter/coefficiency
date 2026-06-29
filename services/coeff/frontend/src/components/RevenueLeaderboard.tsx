'use client';

import {useMemo, useState} from 'react';
import {ArrowUpDown} from 'lucide-react';
import {FormattedMessage, useIntl} from 'react-intl';
import {Button} from '@/components/ui/button';
import {Card, CardContent, CardHeader, CardTitle} from '@/components/ui/card';

/* REQ-FE-005, REQ-FE-006, REQ-FE-007: RevenueLeaderboard with sorting, search, pagination */

interface ConsultantBrief {
    id: number;
    name: string;
    tariff: number;
    coefPercentage: number;
    position: string;
    coefMargin: number;
    managerBonus: number;
    fees: number;
    client: string;
}

type SortField = 'fees' | 'tariff' | 'coefMargin' | 'name' | 'client' | 'position' | 'coef';

interface RevenueLeaderboardProps {
    consultants: ConsultantBrief[];
    onRowClick?: (consultant: ConsultantBrief) => void;
}

const ROWS_PER_PAGE = 10;

const P = (n: number) => (n * 100).toFixed(1);
const F = (n: number) => n.toLocaleString('es-ES', {minimumFractionDigits: 2, maximumFractionDigits: 2});

export default function RevenueLeaderboard({consultants, onRowClick}: RevenueLeaderboardProps) {
    const intl = useIntl();
    const [sortField, setSortField] = useState<SortField>('fees');
    const [sortDir, setSortDir] = useState<'asc' | 'desc'>('desc');
    const [search, setSearch] = useState('');
    const [page, setPage] = useState(0);

    const handleSort = (field: SortField) => {
        if (sortField === field) {
            setSortDir(d => d === 'asc' ? 'desc' : 'asc');
        } else {
            setSortField(field);
            setSortDir('desc');
        }
        setPage(0);
    };

    const filtered = useMemo(() => {
        let list = [...consultants];
        if (search) {
            const q = search.toLowerCase();
            list = list.filter(c =>
                c.name.toLowerCase().includes(q) ||
                c.client.toLowerCase().includes(q)
            );
        }
        list.sort((a, b) => {
            const aVal = a[sortField];
            const bVal = b[sortField];
            const dir = sortDir === 'asc' ? 1 : -1;
            if (typeof aVal === 'string' && typeof bVal === 'string') return aVal.localeCompare(bVal) * dir;
            if (typeof aVal === 'number' && typeof bVal === 'number') return (aVal - bVal) * dir;
            return 0;
        });
        return list;
    }, [consultants, search, sortField, sortDir]);

    const totalPages = Math.max(1, Math.ceil(filtered.length / ROWS_PER_PAGE));
    const paginated = filtered.slice(page * ROWS_PER_PAGE, (page + 1) * ROWS_PER_PAGE);

    const columns: { field: SortField; i18n: string }[] = [
        {field: 'name', i18n: 'consultants.name'},
        {field: 'client', i18n: 'consultants.client'},
        {field: 'position', i18n: 'consultants.position'},
        {field: 'tariff', i18n: 'consultants.dailyRate'},
        {field: 'fees', i18n: 'billing.totalFees'},
        {field: 'coef', i18n: 'consultants.coefPct'},
        {field: 'coefMargin', i18n: 'common.margin'},
    ];

    return (
        <Card>
            <CardHeader className="pb-2">
                <CardTitle className="text-base flex items-center gap-2">
                    <FormattedMessage id="billing.leaderboard"/>
                </CardTitle>
            </CardHeader>
            <CardContent className="p-0">
                {/* Search */}
                <div className="px-4 pt-2 pb-3">
                    <input
                        type="text"
                        placeholder={intl.formatMessage({id: 'common.search'})}
                        value={search}
                        onChange={e => {
                            setSearch(e.target.value);
                            setPage(0);
                        }}
                        className="w-full rounded-md border border-input bg-background px-3 py-1.5 text-sm"
                    />
                </div>
                <div className="overflow-auto">
                    <table className="w-full text-xs">
                        <thead>
                        <tr className="border-b bg-muted/30">
                            <th className="text-left p-2 w-8">#</th>
                            {columns.map(col => (
                                <th
                                    key={col.field}
                                    className="text-right p-2 cursor-pointer select-none hover:bg-muted"
                                    onClick={() => handleSort(col.field)}
                                >
                                    <span className="inline-flex items-center gap-1">
                                        <FormattedMessage id={col.i18n}/>
                                        {sortField === col.field && <ArrowUpDown className="size-3"/>}
                                    </span>
                                </th>
                            ))}
                        </tr>
                        </thead>
                        <tbody>
                        {paginated.map((c, i) => {
                            const rank = page * ROWS_PER_PAGE + i + 1;
                            return (
                                <tr
                                    key={c.id}
                                    className={`border-b hover:bg-muted/30 ${onRowClick ? 'cursor-pointer' : ''}`}
                                    onClick={() => onRowClick?.(c)}
                                >
                                    <td className="p-2 text-center text-base">
                                        {rank === 1 ? '🥇' : rank === 2 ? '🥈' : rank === 3 ? '🥉' : (
                                            <span className="text-muted-foreground">{rank}</span>
                                        )}
                                    </td>
                                    <td className="p-2 font-medium text-left">{c.name}</td>
                                    <td className="p-2 text-right text-muted-foreground">{c.client}</td>
                                    <td className="p-2 text-right">{c.position}</td>
                                    <td className="p-2 text-right">{c.tariff}€</td>
                                    <td className="p-2 text-right font-semibold">{F(c.fees)}€</td>
                                    <td className="p-2 text-right">{P(c.coefPercentage)}%</td>
                                    <td className="p-2 text-right">{F(c.coefMargin)}€</td>
                                </tr>
                            );
                        })}
                        {paginated.length === 0 && (
                            <tr>
                                <td colSpan={8} className="p-6 text-center text-muted-foreground">
                                    <FormattedMessage id="consultants.empty"/>
                                </td>
                            </tr>
                        )}
                        </tbody>
                    </table>
                </div>

                {/* Pagination */}
                {totalPages > 1 && (
                    <div className="flex items-center justify-between px-4 py-3 border-t text-sm">
                        <span className="text-xs text-muted-foreground">
                            {filtered.length} <FormattedMessage id="common.total"/>
                        </span>
                        <div className="flex items-center gap-1">
                            <Button variant="outline" size="sm" disabled={page <= 0}
                                    onClick={() => setPage(p => p - 1)}>←</Button>
                            <span className="px-2 text-xs">{page + 1} / {totalPages}</span>
                            <Button variant="outline" size="sm" disabled={page >= totalPages - 1}
                                    onClick={() => setPage(p => p + 1)}>→</Button>
                        </div>
                    </div>
                )}
            </CardContent>
        </Card>
    );
}
