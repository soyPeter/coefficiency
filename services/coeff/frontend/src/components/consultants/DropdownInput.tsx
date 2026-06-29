'use client';

import {useMemo, useState} from 'react';
import {useIntl} from 'react-intl';
import {Button} from '@/components/ui/button';
import {Input} from '@/components/ui/input';
import {Label} from '@/components/ui/label';
import {Pencil, Search} from 'lucide-react';

/* REQ-FE-001: DropdownInput for autocomplete/select dual-mode input */

export interface DropdownInputProps {
    id: string;
    label: string;
    value: string;
    options: string[];
    onChange: (v: string) => void;
}

export default function DropdownInput({id, label, value, options, onChange}: DropdownInputProps) {
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
