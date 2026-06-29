// REQ-HOOK-PASSWORDFORM-001
import {useCallback, useState} from 'react';

export interface PasswordFormState {
    currentPassword: string;
    newPassword: string;
    confirmPassword: string;
    message: string;
    messageSuccess: boolean;
}

export interface UsePasswordFormResult extends PasswordFormState {
    setCurrentPassword: (v: string) => void;
    setNewPassword: (v: string) => void;
    setConfirmPassword: (v: string) => void;
    setMessage: (msg: string, success: boolean) => void;
    clearMessage: () => void;
    clear: () => void;
}

const INITIAL: PasswordFormState = {
    currentPassword: '',
    newPassword: '',
    confirmPassword: '',
    message: '',
    messageSuccess: false,
};

export function usePasswordForm(): UsePasswordFormResult {
    const [state, setState] = useState<PasswordFormState>(INITIAL);

    const setCurrentPassword = useCallback(
        (currentPassword: string) => setState(s => ({...s, currentPassword})),
        [],
    );
    const setNewPassword = useCallback(
        (newPassword: string) => setState(s => ({...s, newPassword})),
        [],
    );
    const setConfirmPassword = useCallback(
        (confirmPassword: string) => setState(s => ({...s, confirmPassword})),
        [],
    );
    const setMessage = useCallback(
        (message: string, messageSuccess: boolean) =>
            setState(s => ({...s, message, messageSuccess})),
        [],
    );
    const clearMessage = useCallback(
        () => setState(s => ({...s, message: '', messageSuccess: false})),
        [],
    );
    const clear = useCallback(
        () => setState(s => ({...s, currentPassword: '', newPassword: '', confirmPassword: '', message: '', messageSuccess: false})),
        [],
    );

    return {
        ...state,
        setCurrentPassword,
        setNewPassword,
        setConfirmPassword,
        setMessage,
        clearMessage,
        clear,
    };
}
