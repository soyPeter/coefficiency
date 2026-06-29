import {FormattedMessage} from 'react-intl';

const STATUS_COLORS: Record<string, string> = {
    PROFITABLE: 'bg-emerald-100 text-emerald-800',
    AT_RISK: 'bg-amber-100 text-amber-800',
    BELOW_THRESHOLD: 'bg-red-100 text-red-800',
    INSUFFICIENT_DATA: 'bg-gray-100 text-gray-600',
};

const STATUS_I18N: Record<string, string> = {
    PROFITABLE: 'profitability.profitable',
    AT_RISK: 'profitability.atRisk',
    BELOW_THRESHOLD: 'profitability.belowThreshold',
    INSUFFICIENT_DATA: 'profitability.insufficientData',
};

export function StatusBadge({status}: { status?: string }) {
    if (!status) return <span className="text-xs text-muted-foreground">—</span>;
    const colorClass = STATUS_COLORS[status] || 'bg-gray-100 text-gray-600';
    const labelKey = STATUS_I18N[status] || 'profitability.insufficientData';
    return (
        <span className={`inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium ${colorClass}`}>
            <FormattedMessage id={labelKey}/>
        </span>
    );
}
