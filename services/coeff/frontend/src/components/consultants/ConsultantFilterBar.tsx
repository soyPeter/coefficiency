import {FormattedMessage, useIntl} from 'react-intl';
import {Filter, Search, X} from 'lucide-react';
import {Input} from '@/components/ui/input';

export type TableFilter = 'all' | 'active' | 'terminated';
export type CoefFilter = 'overAvg' | 'underAvg' | 'aboveThresholdPlus' | 'belowThreshold' | null;

export interface ConsultantFilterBarProps {
    searchQuery: string;
    onSearchChange: (q: string) => void;
    tableFilter: TableFilter;
    onTableFilterChange: (f: TableFilter) => void;
    coefFilter: CoefFilter;
    onCoefFilterChange: (f: CoefFilter) => void;
}

const COEF_FILTER_LABEL: Record<NonNullable<CoefFilter>, string> = {
    overAvg: 'consultants.aboveAverage',
    underAvg: 'consultants.belowAverage',
    aboveThresholdPlus: 'consultants.abovePeerThreshold',
    belowThreshold: 'consultants.belowThreshold',
};

export function ConsultantFilterBar({
    searchQuery,
    onSearchChange,
    tableFilter,
    onTableFilterChange,
    coefFilter,
    onCoefFilterChange,
}: ConsultantFilterBarProps) {
    const intl = useIntl();

    const handleSearch = (value: string) => {
        onSearchChange(value);
    };

    const handleTableFilter = (f: TableFilter) => {
        onTableFilterChange(f);
        onCoefFilterChange(null);
    };

    return (
        <div className="flex flex-col gap-3 mb-4">
            <div className="flex items-center gap-4">
                <div className="relative flex-1 max-w-md">
                    <Search className="absolute left-2.5 top-1/2 -translate-y-1/2 size-4 text-muted-foreground"/>
                    <Input
                        placeholder={intl.formatMessage({id: 'consultants.search'})}
                        value={searchQuery}
                        onChange={e => handleSearch(e.target.value)}
                        className="pl-8"
                    />
                </div>
                <div className="flex bg-muted rounded-lg p-0.5">
                    <button onClick={() => handleTableFilter('all')}
                            className={`px-3 py-1 text-xs rounded-md transition-colors ${tableFilter === 'all' ? 'bg-background shadow-sm font-medium' : 'text-muted-foreground'}`}>
                        <FormattedMessage id="consultants.showAll"/>
                    </button>
                    <button onClick={() => handleTableFilter('active')}
                            className={`px-3 py-1 text-xs rounded-md transition-colors ${tableFilter === 'active' ? 'bg-background shadow-sm font-medium' : 'text-muted-foreground'}`}>
                        <FormattedMessage id="consultants.showActive"/>
                    </button>
                    <button onClick={() => handleTableFilter('terminated')}
                            className={`px-3 py-1 text-xs rounded-md transition-colors ${tableFilter === 'terminated' ? 'bg-background shadow-sm font-medium' : 'text-muted-foreground'}`}>
                        Terminated
                    </button>
                </div>
            </div>
            {coefFilter && (
                <div className="flex items-center gap-2">
                    <span className="text-xs text-muted-foreground font-medium"><Filter className="size-3 inline mr-1" />Filtros:</span>
                    <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-md bg-primary/10 text-primary text-xs font-medium">
                        {intl.formatMessage({id: COEF_FILTER_LABEL[coefFilter]})}
                        <button onClick={() => onCoefFilterChange(null)} className="hover:text-primary/70 ml-0.5">
                            <X className="size-3" />
                        </button>
                    </span>
                </div>
            )}
        </div>
    );
}
