import { useState, useEffect } from 'react';
import { FormattedMessage, useIntl } from 'react-intl';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';

const BASE = '/api';

async function api<T>(url: string, options?: RequestInit): Promise<T> {
  const res = await fetch(`${BASE}${url}`, {
    headers: { 'Content-Type': 'application/json' },
    ...options,
  });
  return res.json();
}

export function hasValidToken(): boolean {
  const token = localStorage.getItem('token');
  if (!token) return false;
  try {
    const decoded = atob(token);
    const [, expiry] = decoded.split(':');
    return parseInt(expiry) > Date.now() / 1000;
  } catch {
    return false;
  }
}

export function clearToken() {
  localStorage.removeItem('token');
}

export default function LoginPage({ onLogin }: { onLogin: () => void }) {
  const intl = useIntl();
  const [mode, setMode] = useState<'login' | 'setup'>('login');
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [error, setError] = useState('');
  const [message, setMessage] = useState('');

  useEffect(() => {
    api<{ hasUser: boolean }>('/auth/status').then(r => {
      setMode(r.hasUser ? 'login' : 'setup');
    });
  }, []);

  const handleSetup = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    if (username.length < 3) {
      setError(intl.formatMessage({ id: 'auth.usernameRequired' }));
      return;
    }
    if (password.length < 4) {
      setError(intl.formatMessage({ id: 'auth.passwordRequired' }));
      return;
    }
    if (password !== confirmPassword) {
      setError(intl.formatMessage({ id: 'auth.passwordsDontMatch' }));
      return;
    }
    const res = await api<{ success: boolean; message: string }>('/auth/setup', {
      method: 'POST',
      body: JSON.stringify({ username, password }),
    });
    if (res.success) {
      setMessage(intl.formatMessage({ id: 'auth.setupSuccess' }));
      setMode('login');
      setPassword('');
      setConfirmPassword('');
    } else {
      setError(res.message);
    }
  };

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    const res = await api<{ token: string | null; message?: string }>('/auth/login', {
      method: 'POST',
      body: JSON.stringify({ username, password }),
    });
    if (res.token) {
      localStorage.setItem('token', res.token);
      onLogin();
    } else {
      setError(res.message || intl.formatMessage({ id: 'auth.invalidCredentials' }));
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-muted/30">
      <Card className="w-full max-w-sm mx-4">
        <CardContent className="p-8">
          <div className="text-center mb-8">
            <h1 className="text-2xl font-bold tracking-wider text-primary">BITNOMIO</h1>
            <p className="text-sm text-muted-foreground mt-1">
              {mode === 'setup' ? <FormattedMessage id="auth.setup" /> : <FormattedMessage id="auth.login" />}
            </p>
          </div>

          <form onSubmit={mode === 'setup' ? handleSetup : handleLogin} className="space-y-4">
            <div>
              <Label htmlFor="username"><FormattedMessage id="auth.username" /></Label>
              <Input id="username" value={username} onChange={e => setUsername(e.target.value)} autoFocus />
            </div>
            <div>
              <Label htmlFor="password"><FormattedMessage id="auth.password" /></Label>
              <Input id="password" type="password" value={password} onChange={e => setPassword(e.target.value)} />
            </div>
            {mode === 'setup' && (
              <div>
                <Label htmlFor="confirm"><FormattedMessage id="auth.confirmPassword" /></Label>
                <Input id="confirm" type="password" value={confirmPassword} onChange={e => setConfirmPassword(e.target.value)} />
              </div>
            )}

            {error && <p className="text-sm text-destructive">{error}</p>}
            {message && <p className="text-sm text-emerald-600">{message}</p>}

            <Button type="submit" className="w-full">
              {mode === 'setup' ? <FormattedMessage id="auth.createAccount" /> : <FormattedMessage id="auth.submit" />}
            </Button>
          </form>

          <div className="text-center mt-4">
            <button
              type="button"
              className="text-sm text-muted-foreground hover:text-primary"
              onClick={() => { setMode(mode === 'login' ? 'setup' : 'login'); setError(''); setMessage(''); }}
            >
              {mode === 'login' ? <FormattedMessage id="auth.firstTime" /> : <FormattedMessage id="auth.haveAccount" />}
            </button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
