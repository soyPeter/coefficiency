import {FormattedMessage, useIntl} from 'react-intl';
import {ArrowDown, ArrowUp, Eye, EyeOff, Info, Pencil, Trash2} from 'lucide-react';
import {Button} from '@/components/ui/button';
import {StatusBadge} from '@/components/consultants/StatusBadge';
import type {Consultant} from '@/types';

export type SortField =
    | 'name'
    | 'client'
    | 'position'
    | 'status'
    | 'profitability'
    | 'startDate'
    | 'endDate'
    | 'daysInRole'
    | 'coefPercentage'
    | 'tariff'
    | 'managerBonus'
    | 'id';

export const COLUMNS: { field: SortField; i18n: string; className: string }[] = [
    {field: 'name', i18n: 'consultants.name', className: 'text-left'},
    {field: 'client', i18n: 'consultants.client', className: 'text-left'},
    {field: 'position', i18n: 'consultants.position', className: 'text-left'},
    {field: 'status', i18n: 'consultants.status', className: 'text-center'},
    {field: 'profitability', i18n: 'consultants.profitability', className: 'text-center'},
    {field: 'startDate', i18n: 'consultants.startDate', className: 'text-right'},
    {field: 'endDate', i18n: 'consultants.endDate', className: 'text-right'},
    {field: 'daysInRole', i18n: 'consultants.daysInRole', className: 'text-right'},
    {field: 'coefPercentage', i18n: 'consultants.coefPct', className: 'text-right'},
    {field: 'tariff', i18n: 'consultants.dailyRate', className: 'text-right'},
    {field: 'managerBonus', i18n: 'consultants.managerBonus', className: 'text-right'},
];

export interface ConsultantTableProps {
    consultants: Consultant[];
    sortField: SortField;
    sortDir: 'asc' | 'desc';
    onSort: (field: SortField) => void;
    showBonus: boolean;
    onToggleBonus: () => void;
    coefAlertThreshold: number;
    positionTariffThresholds: Record<string, number>;
    onShow: (c: Consultant) => void;
    onEdit: (c: Consultant) => void;
    onDelete: (c: Consultant) => void;
    fmt: (n: number) => string;
    emptyI18n?: string;
}

export function ConsultantTable({
    consultants,
    sortField,
    sortDir,
    onSort,
    showBonus,
    onToggleBonus,
    coefAlertThreshold,
    positionTariffThresholds,
    onShow,
    onEdit,
    onDelete,
    fmt,
    emptyI18n = 'consultants.empty',
}: ConsultantTableProps) {
    const intl = useIntl();

    const coefClass = (coefPct: number) =>
        coefPct < coefAlertThreshold
            ? 'text-red-600 bg-red-50 dark:bg-red-950/20'
            : coefPct > coefAlertThreshold * 1.25
                ? 'text-emerald-600 bg-emerald-50 dark:bg-emerald-950/20'
                : '';

    const tariffClass = (position: string, tariff: number) => {
        const threshold = position ? positionTariffThresholds[position] : undefined;
        return threshold != null && tariff < threshold
            ? 'text-amber-600 bg-amber-50 dark:bg-amber-950/20'
            : '';
    };

    return (
        <div className="overflow-auto">
            <table className="w-full">
                <thead>
                <tr className="border-b bg-muted/50">
                    {COLUMNS.map(col => (
                        <th
                            key={col.field}
                            className={`p-3 text-xs font-medium text-muted-foreground cursor-pointer select-none hover:bg-muted ${col.className}`}
                            onClick={() => onSort(col.field)}
                        >
                            <span className="inline-flex items-center gap-1">
                                <FormattedMessage id={col.i18n}/>
                                {sortField === col.field && (
                                    sortDir === 'asc' ? <ArrowUp className="size-3"/> : <ArrowDown className="size-3"/>
                                )}
                                {col.field === 'managerBonus' && (
                                    <button
                                        onClick={e => {
                                            e.stopPropagation();
                                            onToggleBonus();
                                        }}
                                        className="ml-1 p-0.5 rounded hover:bg-muted-foreground/10"
                                        title={showBonus ? 'Hide bonus' : 'Show bonus'}
                                    >
                                        {showBonus ? <EyeOff className="size-3"/> : <Eye className="size-3"/>}
                                    </button>
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
                {consultants.map((c) => (
                    <tr
                        key={c.id}
                        className={`border-b hover:bg-muted/30 ${c.endDate ? 'text-muted-foreground/60 bg-muted/10' : ''}`}
                    >
                        <td className="p-3 font-medium">{c.name}</td>
                        <td className="p-3 text-sm">{c.client}</td>
                        <td className="p-3 text-sm">{c.position}</td>
                        <td className="p-3 text-sm text-center">
                            {c.endDate ? (
                                <span className="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-700">Terminated</span>
                            ) : (
                                <span className="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-emerald-100 text-emerald-800">Active</span>
                            )}
                        </td>
                        <td className="p-3 text-sm text-center"><StatusBadge status={c.profitabilityStatus}/></td>
                        <td className="p-3 text-sm text-right">{c.startDate}</td>
                        <td className="p-3 text-sm text-right">
                            {c.endDate || (
                                <span className="text-muted-foreground">
                                    <FormattedMessage id="consultants.noEndDate"/>
                                </span>
                            )}
                        </td>
                        <td className="p-3 text-sm text-right">{c.daysInRole}</td>
                        <td className={`p-3 text-sm text-right font-semibold ${coefClass(c.coefPercentage)}`}>
                            {(c.coefPercentage * 100).toFixed(1)}%
                        </td>
                        <td className={`p-3 text-sm text-right ${tariffClass(c.position, c.tariff)}`}>{fmt(c.tariff)} €</td>
                        <td className={`p-3 text-sm text-right ${showBonus ? '' : 'blur-sm select-none'}`}>
                            {fmt(c.managerBonus)} €
                        </td>
                        <td className="p-3 text-right">
                            <div className="flex gap-1 justify-end">
                                <Button
                                    variant="ghost"
                                    size="sm"
                                    onClick={() => onShow(c)}
                                    title={intl.formatMessage({id: 'consultants.show'})}
                                >
                                    <Info className="size-3.5"/>
                                </Button>
                                <Button
                                    variant="ghost"
                                    size="sm"
                                    onClick={() => onEdit(c)}
                                    title={intl.formatMessage({id: 'consultants.edit'})}
                                >
                                    <Pencil className="size-3.5"/>
                                </Button>
                                <Button
                                    variant="ghost"
                                    size="sm"
                                    onClick={() => onDelete(c)}
                                    title={intl.formatMessage({id: 'consultants.delete'})}
                                >
                                    <Trash2 className="size-3.5 text-destructive"/>
                                </Button>
                            </div>
                        </td>
                    </tr>
                ))}
                {consultants.length === 0 && (
                    <tr>
                        <td colSpan={12} className="p-6 text-center text-muted-foreground">
                            <FormattedMessage id={emptyI18n}/>
                        </td>
                    </tr>
                )}
                </tbody>
            </table>
        </div>
    );
}
