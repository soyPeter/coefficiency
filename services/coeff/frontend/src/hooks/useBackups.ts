// REQ-HOOK-BACKUPS-001
import {useCallback, useEffect, useState} from 'react';
import {useIntl} from 'react-intl';

const BASE = '/api';
const MSG_CLEAR_MS = 5000;

type AuthFetchFn = (url: string, options?: RequestInit) => Promise<Response>;

export interface BackupFile {
  filename: string;
  size: number;
  createdAt: string;
}

export interface UseBackupsResult {
    backups: BackupFile[];
    message: string;
    loading: boolean;
    create: () => Promise<void>;
    reload: () => void;
}

export function useBackups(authFetch: AuthFetchFn): UseBackupsResult {
    const intl = useIntl();
    const [backups, setBackups] = useState<BackupFile[]>([]);
    const [message, setMessage] = useState('');
    const [loading, setLoading] = useState(false);

    const reload = useCallback(() => {
        authFetch(`${BASE}/admin/backups`).then(r => r.json()).then(setBackups).catch(() => {});
    }, [authFetch]);

    useEffect(() => {
        reload();
    }, [reload]);

    const create = useCallback(async () => {
        setLoading(true);
        setMessage('');
        try {
            const res = await authFetch(`${BASE}/admin/backup`, {method: 'POST'});
            if (res.ok) {
                const data = await res.json();
                setMessage(intl.formatMessage({id: 'config.backupCreated'}, {filename: data.filename}));
                const list = await authFetch(`${BASE}/admin/backups`).then(r => r.json());
                setBackups(list);
            } else {
                const err = await res.json();
                setMessage(err.error || 'Error');
            }
        } catch {
            setMessage('Error');
        }
        setLoading(false);
        setTimeout(() => setMessage(''), MSG_CLEAR_MS);
    }, [authFetch, intl]);

    return {backups, message, loading, create, reload};
}
