// REQ-HOOK-COEFCONFIG-001
import {useCallback, useEffect, useState} from 'react';

type AuthFetchFn = (url: string, options?: RequestInit) => Promise<Response>;

export interface CoefConfig {
    workingDays: number[];
    coefDaysMonth: number;
    totalWorkingDays: number;
    coefAlertThreshold: number;
    tenureBonusAmount: number;
    tenureBonusMonths: number;
    quarterlyBonusAmount: number;
    mngBonusStartDay: number;
    mngBonusEndDay: number;
    mngBonusExcludedMonths: number[];
    positionTariffAlertPct: number;
    params: Record<string, number>;
    savedKey: string;
}

const BASE = '/api';

export interface UseCoefConfigResult extends CoefConfig {
    load: () => Promise<void>;
    setPartial: (patch: Partial<CoefConfig>) => void;
    setParam: (key: string, value: number) => void;
    flashSaved: (key: string) => void;
}

export function useCoefConfig(authFetch: AuthFetchFn): UseCoefConfigResult {
    const [state, setState] = useState<CoefConfig>({
        workingDays: [],
        coefDaysMonth: 21,
        totalWorkingDays: 0,
        coefAlertThreshold: 0.15,
        tenureBonusAmount: 300,
        tenureBonusMonths: 3,
        quarterlyBonusAmount: 500,
        mngBonusStartDay: 14,
        mngBonusEndDay: 21,
        mngBonusExcludedMonths: [8],
        positionTariffAlertPct: 15,
        params: {
            coefMultiplier: 1.7, mngBonusPct: 0.05, insuranceMonths: 6, mealCardDays: 22,
            ssRate: 0.0635,
        },
        savedKey: '',
    });

    const load = useCallback(async () => {
        try {
            const d = await authFetch(`${BASE}/fiscal`).then(r => r.json());
            setState(s => ({
                ...s,
                workingDays: d.workingDays || [],
                coefDaysMonth: d.coefDaysMonth || 21,
                totalWorkingDays: d.coefDaysYear || 0,
                coefAlertThreshold: d.coefAlertThreshold ?? 0.15,
                tenureBonusAmount: d.tenureBonusAmount ?? 300,
                tenureBonusMonths: d.tenureBonusMonths ?? 3,
                quarterlyBonusAmount: d.quarterlyBonusAmount ?? 500,
                mngBonusStartDay: d.mngBonusStartDay ?? 14,
                mngBonusEndDay: d.mngBonusEndDay ?? 21,
                mngBonusExcludedMonths: Array.isArray(d.mngBonusExcludedMonths) ? d.mngBonusExcludedMonths : [8],
                positionTariffAlertPct: d.positionTariffAlertPct ?? 15,
                params: {
                    coefMultiplier: d.coefMultiplier ?? 1.7,
                    mngBonusPct: d.mngBonusPct ?? 0.05,
                    insuranceMonths: d.insuranceMonths ?? 6,
                    mealCardDays: d.mealCardDays ?? 22,
                    ssRate: d.ssRate ?? 0.0635,
                },
                savedKey: '',
            }));
        } catch { /* keep defaults */ }
    }, [authFetch]);

    useEffect(() => { load(); }, [load]);

    const setPartial = useCallback((patch: Partial<CoefConfig>) => {
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
