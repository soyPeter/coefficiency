// REQ-HOOK-FISCONFIG-001
import {useCallback, useEffect, useState} from 'react';

type AuthFetchFn = (url: string, options?: RequestInit) => Promise<Response>;

export interface IrpfBracket {
  from: number;
  to: number;
  rate: number;
}

export interface SsCategory {
  category: string;
  baseMin: number;
  baseMax: number;
  rate: number;
}

export interface FiscalConfig {
    brackets: IrpfBracket[];
    regionalBrackets: IrpfBracket[];
    ssConfig: SsCategory[];
    lirpfExpenses: number;
    params: Record<string, number>;
    savedKey: string;
}

const BASE = '/api';

export interface UseFiscalConfigResult extends FiscalConfig {
    load: () => Promise<void>;
    setPartial: (patch: Partial<FiscalConfig>) => void;
    setParam: (key: string, value: number) => void;
    flashSaved: (key: string) => void;
}

export function useFiscalConfig(authFetch: AuthFetchFn): UseFiscalConfigResult {
    const [state, setState] = useState<FiscalConfig>({
        brackets: [],
        regionalBrackets: [],
        ssConfig: [],
        lirpfExpenses: 2000,
        params: {
            ssContingencies: 0.047, ssUnemployment: 0.0155, ssTraining: 0.001,
            personalMinimum: 5550, deductionChild: 2400, deductionAsc: 1150, deductionDis: 3000,
            deductionSpouse: 2150,
        },
        savedKey: '',
    });

    const load = useCallback(async () => {
        try {
            const d = await authFetch(`${BASE}/fiscal`).then(r => r.json());
            setState(s => ({
                ...s,
                brackets: d.brackets || [],
                regionalBrackets: d.regionalBrackets || [],
                ssConfig: d.ssConfig || [],
                lirpfExpenses: d.lirpfExpenses ?? 2000,
                params: {
                    ssContingencies: d.ssContingencies ?? 0.047,
                    ssUnemployment: d.ssUnemployment ?? 0.0155,
                    ssTraining: d.ssTraining ?? 0.001,
                    personalMinimum: d.personalMinimum ?? 5550,
                    deductionChild: d.deductionChild ?? 2400,
                    deductionAsc: d.deductionAsc ?? 1150,
                    deductionDis: d.deductionDis ?? 3000,
                    deductionSpouse: d.deductionSpouse ?? 2150,
                },
                savedKey: '',
            }));
        } catch { /* keep defaults */ }
    }, [authFetch]);

    useEffect(() => { load(); }, [load]);

    const setPartial = useCallback((patch: Partial<FiscalConfig>) => {
        setState(s => ({...s, ...patch}));
    }, []);

    const setParam = useCallback((key: string, value: number) => {
        setState(s => ({...s, params: {...s.params, [key]: value}}));
    }, []);

    const flashSaved = useCallback((key: string) => {
        setState(s => ({...s, savedKey: key}));
        setTimeout(() => setState(s => ({...s, savedKey: ''})), 3000);
    }, []);

    return {
        ...state,
        load,
        setPartial,
        setParam,
        flashSaved,
    };
}
