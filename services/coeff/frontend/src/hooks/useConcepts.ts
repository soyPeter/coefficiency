// REQ-HOOK-CONCEPTS-001
import {useCallback, useState} from 'react';

export interface Concept {
    id: number;
    name: string;
    type: string;
    defaultValue: number;
}

export interface ConceptDraft {
    name: string;
    type: string;
    value: number;
}

export interface UseConceptsResult {
    concepts: Concept[];
    draft: ConceptDraft;
    setConcepts: React.Dispatch<React.SetStateAction<Concept[]>>;
    setDraftName: (v: string) => void;
    setDraftType: (v: string) => void;
    setDraftValue: (v: number) => void;
    resetDraft: () => void;
}

const INITIAL_DRAFT: ConceptDraft = {name: '', type: 'monthly', value: 0};

export function useConcepts(): UseConceptsResult {
    const [concepts, setConcepts] = useState<Concept[]>([]);
    const [draft, setDraft] = useState<ConceptDraft>(INITIAL_DRAFT);

    const setDraftName = useCallback(
        (name: string) => setDraft(d => ({...d, name})),
        [],
    );
    const setDraftType = useCallback(
        (type: string) => setDraft(d => ({...d, type})),
        [],
    );
    const setDraftValue = useCallback(
        (value: number) => setDraft(d => ({...d, value})),
        [],
    );
    const resetDraft = useCallback(() => setDraft(INITIAL_DRAFT), []);

    return {
        concepts,
        draft,
        setConcepts,
        setDraftName,
        setDraftType,
        setDraftValue,
        resetDraft,
    };
}
