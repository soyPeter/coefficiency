// REQ-HOOK-DUMPBACKUPS-001
import {useCallback, useState} from 'react';
import {useIntl} from 'react-intl';
import type {BackupFile} from './useBackups';

type AuthFetchFn = (url: string, options?: RequestInit) => Promise<Response>;

const BASE = '/api';

export interface UseDumpBackupsResult {
    dumpBackups: BackupFile[];
    showDumpDialog: boolean;
    dumpPassword: string;
    dumpPasswordConfirm: string;
    dumpBackupMsg: string;
    dumpBackupMsgSuccess: boolean;
    dumpRestoreFile: string;
    dumpRestorePassword: string;
    showDumpRestoreDialog: boolean;
    dumpRestoreMsg: string;
    dumpUploadFile: File | null;
    dumpUploadPassword: string;
    uploadingDump: boolean;
    dumpUploadError: string;
    loadList: () => void;
    openDumpDialog: () => void;
    closeDumpDialog: () => void;
    setDumpPassword: (v: string) => void;
    setDumpPasswordConfirm: (v: string) => void;
    createDump: () => Promise<void>;
    openRestoreDialog: (filename: string) => void;
    closeRestoreDialog: () => void;
    setDumpRestorePassword: (v: string) => void;
    confirmRestore: () => Promise<void>;
    chooseDumpFile: () => void;
    setDumpUploadPassword: (v: string) => void;
    uploadAndRestore: () => Promise<void>;
}

export function useDumpBackups(authFetch: AuthFetchFn): UseDumpBackupsResult {
    const intl = useIntl();
    const [dumpBackups, setDumpBackups] = useState<BackupFile[]>([]);
    const [showDumpDialog, setShowDumpDialog] = useState(false);
    const [dumpPassword, setDumpPassword] = useState('');
    const [dumpPasswordConfirm, setDumpPasswordConfirm] = useState('');
    const [dumpBackupMsg, setDumpBackupMsg] = useState('');
    const [dumpBackupMsgSuccess, setDumpBackupMsgSuccess] = useState(false);
    const [dumpRestoreFile, setDumpRestoreFile] = useState('');
    const [dumpRestorePassword, setDumpRestorePassword] = useState('');
    const [showDumpRestoreDialog, setShowDumpRestoreDialog] = useState(false);
    const [dumpRestoreMsg, setDumpRestoreMsg] = useState('');
    const [dumpUploadFile, setDumpUploadFile] = useState<File | null>(null);
    const [dumpUploadPassword, setDumpUploadPassword] = useState('');
    const [uploadingDump, setUploadingDump] = useState(false);
    const [dumpUploadError, setDumpUploadError] = useState('');

    const flashMsg = useCallback((setter: (m: string) => void, msg: string) => {
        setter(msg);
        setTimeout(() => setter(''), 5000);
    }, []);

    const loadList = useCallback(() => {
        authFetch(`${BASE}/admin/backups?type=dump`).then(r => r.json()).then(setDumpBackups).catch(() => {});
    }, [authFetch]);

    const openDumpDialog = useCallback(() => {
        setShowDumpDialog(true);
        setDumpBackupMsg('');
    }, []);

    const closeDumpDialog = useCallback(() => {
        setShowDumpDialog(false);
        setDumpPassword('');
        setDumpPasswordConfirm('');
    }, []);

    const createDump = useCallback(async () => {
        if (dumpPassword !== dumpPasswordConfirm) {
            setDumpBackupMsg(intl.formatMessage({id: 'config.backupPasswordMismatch'}));
            setDumpBackupMsgSuccess(false);
            setTimeout(() => setDumpBackupMsg(''), 5000);
            return;
        }
        if (dumpPassword.length < 4) {
            setDumpBackupMsg('Backup password must be at least 4 characters');
            setDumpBackupMsgSuccess(false);
            setTimeout(() => setDumpBackupMsg(''), 5000);
            return;
        }
        try {
            const res = await authFetch(`${BASE}/admin/backup-dump`, {
                method: 'POST',
                body: JSON.stringify({password: dumpPassword}),
            });
            if (res.ok) {
                const data = await res.json();
                setDumpBackupMsg(intl.formatMessage({id: 'config.dumpBackupCreated'}, {filename: data.filename}));
                setDumpBackupMsgSuccess(true);
                setDumpPassword('');
                setDumpPasswordConfirm('');
                setShowDumpDialog(false);
                const list = await authFetch(`${BASE}/admin/backups?type=dump`).then(r => r.json());
                setDumpBackups(list);
            } else {
                const err = await res.json();
                setDumpBackupMsg(err.error || intl.formatMessage({id: 'config.dumpBackupFailed'}));
                setDumpBackupMsgSuccess(false);
            }
        } catch {
            setDumpBackupMsg(intl.formatMessage({id: 'config.dumpBackupFailed'}));
            setDumpBackupMsgSuccess(false);
        }
        setTimeout(() => setDumpBackupMsg(''), 5000);
    }, [authFetch, dumpPassword, dumpPasswordConfirm, intl]);

    const openRestoreDialog = useCallback((filename: string) => {
        setDumpRestoreFile(filename);
        setDumpRestorePassword('');
        setDumpRestoreMsg('');
        setShowDumpRestoreDialog(true);
    }, []);

    const closeRestoreDialog = useCallback(() => {
        setShowDumpRestoreDialog(false);
    }, []);

    const confirmRestore = useCallback(async () => {
        if (!dumpRestorePassword) {
            setDumpRestoreMsg(intl.formatMessage({id: 'config.dumpRestorePasswordRequired'}));
            setTimeout(() => setDumpRestoreMsg(''), 5000);
            return;
        }
        try {
            const res = await authFetch(`${BASE}/admin/backups/dump/${encodeURIComponent(dumpRestoreFile)}/restore`, {
                method: 'POST',
                body: JSON.stringify({password: dumpRestorePassword}),
            });
            if (res.ok) {
                setDumpRestoreMsg(intl.formatMessage({id: 'config.restored'}));
                setTimeout(() => window.location.reload(), 1500);
            } else {
                const err = await res.json();
                setDumpRestoreMsg(err.error || 'Error');
            }
        } catch {
            setDumpRestoreMsg('Error');
        }
        setTimeout(() => setDumpRestoreMsg(''), 5000);
    }, [authFetch, dumpRestoreFile, dumpRestorePassword, intl]);

    const chooseDumpFile = useCallback(() => {
        const input = document.createElement('input');
        input.type = 'file';
        input.onchange = (e) => {
            const file = (e.target as HTMLInputElement).files?.[0];
            if (file) setDumpUploadFile(file);
        };
        input.click();
    }, []);

    const uploadAndRestore = useCallback(async () => {
        if (!dumpUploadFile || !dumpUploadPassword) return;
        setUploadingDump(true);
        setDumpUploadError('');
        try {
            const token = localStorage.getItem('token');
            const formData = new FormData();
            formData.append('file', dumpUploadFile);
            formData.append('password', dumpUploadPassword);
            const res = await fetch(`${BASE}/admin/backups/dump/restore-upload`, {
                method: 'POST',
                headers: token ? {'Authorization': 'Bearer ' + token} : undefined,
                body: formData,
            });
            if (res.ok) {
                window.location.reload();
            } else {
                const data = await res.json().catch(() => ({error: 'Restore failed'}));
                throw new Error(data.error || 'Restore failed');
            }
        } catch (err) {
            setDumpUploadError(err instanceof Error ? err.message : 'Restore failed');
            setUploadingDump(false);
        }
    }, [dumpUploadFile, dumpUploadPassword]);

    return {
        dumpBackups,
        showDumpDialog,
        dumpPassword,
        dumpPasswordConfirm,
        dumpBackupMsg,
        dumpBackupMsgSuccess,
        dumpRestoreFile,
        dumpRestorePassword,
        showDumpRestoreDialog,
        dumpRestoreMsg,
        dumpUploadFile,
        dumpUploadPassword,
        uploadingDump,
        dumpUploadError,
        loadList,
        openDumpDialog,
        closeDumpDialog,
        setDumpPassword,
        setDumpPasswordConfirm,
        createDump,
        openRestoreDialog,
        closeRestoreDialog,
        setDumpRestorePassword,
        confirmRestore,
        chooseDumpFile,
        setDumpUploadPassword,
        uploadAndRestore,
    };
}
