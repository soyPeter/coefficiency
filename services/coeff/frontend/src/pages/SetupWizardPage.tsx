import { useState, useEffect } from 'react';
import { FormattedMessage, useIntl } from 'react-intl';
import { useNavigate, useSearchParams } from 'react-router';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { detectLocale } from '@/i18n/messages';
import type { Locale } from '@/i18n/messages';

const BASE = '/api';

async function api<T>(url: string, options?: RequestInit): Promise<T> {
  const res = await fetch(`${BASE}${url}`, {
    headers: { 'Content-Type': 'application/json' },
    ...options,
  });
  return res.json();
}

type Step = 'welcome' | 'account' | 'config' | 'done';

export default function SetupWizardPage({ onComplete }: { onComplete: () => void }) {
  const intl = useIntl();
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const [step, setStep] = useState<Step>('welcome');
  const [locale, setLocale] = useState<Locale>(detectLocale);
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [deltaAnnual, setDeltaAnnual] = useState('12');
  const [autoLogout, setAutoLogout] = useState('15');
  const [error, setError] = useState('');
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    api<{ hasUser: boolean }>('/auth/status').then(r => {
      if (r.hasUser) {
        // Setup already done — redirect to login
        navigate('/', { replace: true });
      }
    });
  }, [navigate]);

  const handleLanguageChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    const newLocale = e.target.value as Locale;
    setLocale(newLocale);
    window.dispatchEvent(new CustomEvent('langchange'));
    // Persist locale preference
    localStorage.setItem('locale', newLocale);
  };

  const handleAccountSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    if (username.length < 3) {
      setError(intl.formatMessage({ id: 'auth.usernameRequired' }));
      return;
    }
    if (password.length < 8) {
      setError(intl.formatMessage({ id: 'auth.passwordRequired' }));
      return;
    }
    if (password !== confirmPassword) {
      setError(intl.formatMessage({ id: 'auth.passwordsDontMatch' }));
      return;
    }
    setStep('config');
  };

  const handleConfigSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setSubmitting(true);

    try {
      // Create account (returns token directly on success)
      const setupRes = await api<{ token?: string; message?: string }>('/auth/setup', {
        method: 'POST',
        body: JSON.stringify({ username, password }),
      });

      if (!setupRes.token) {
        setError(setupRes.message || 'Setup failed');
        setSubmitting(false);
        return;
      }

      localStorage.setItem('token', setupRes.token);

      // Save delta annual setting
      const token = setupRes.token;
      const headers = { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` };

      await fetch(`${BASE}/settings`, {
        method: 'PUT',
        headers,
        body: JSON.stringify({ key: 'delta_annual', value: deltaAnnual }),
      });

      // Save auto-logout setting
      await fetch(`${BASE}/settings`, {
        method: 'PUT',
        headers,
        body: JSON.stringify({ key: 'auto_logout_timeout', value: autoLogout }),
      });

      setStep('done');
      setSubmitting(false);
    } catch (err) {
      setError(String(err));
      setSubmitting(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-muted/30">
      <Card className="w-full max-w-lg mx-4">
        <CardContent className="p-8">
          {/* Step indicator */}
          <div className="flex justify-center gap-2 mb-8">
            {(['welcome', 'account', 'config', 'done'] as const).map((s) => (
              <div
                key={s}
                className={`h-2 w-12 rounded-full transition-colors ${
                  ['welcome', 'account', 'config', 'done'].indexOf(step) >=
                  ['welcome', 'account', 'config', 'done'].indexOf(s)
                    ? 'bg-primary'
                    : 'bg-muted'
                }`}
              />
            ))}
          </div>

          {step === 'welcome' && (
            <div className="text-center space-y-6">
              <div className="space-y-2">
                <h1 className="text-2xl font-bold tracking-wider text-primary">BITNOMIO</h1>
                <h2 className="text-xl font-semibold">
                  <FormattedMessage id="setupWizard.welcome.title" />
                </h2>
                <p className="text-sm text-muted-foreground">
                  <FormattedMessage id="setupWizard.welcome.description" />
                </p>
              </div>

              <div className="space-y-2">
                <Label htmlFor="language">
                  <FormattedMessage id="setupWizard.welcome.selectLanguage" />
                </Label>
                <select
                  id="language"
                  value={locale}
                  onChange={handleLanguageChange}
                  className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background"
                >
                  <option value="en">English</option>
                  <option value="es">Español</option>
                </select>
              </div>

              <Button onClick={() => setStep('account')} className="w-full">
                <FormattedMessage id="setupWizard.welcome.start" />
              </Button>
            </div>
          )}

          {step === 'account' && (
            <form onSubmit={handleAccountSubmit} className="space-y-6">
              <div className="space-y-2">
                <h2 className="text-xl font-semibold">
                  <FormattedMessage id="setupWizard.account.title" />
                </h2>
                <p className="text-sm text-muted-foreground">
                  <FormattedMessage id="setupWizard.account.description" />
                </p>
              </div>

              <div className="space-y-4">
                <div>
                  <Label htmlFor="username"><FormattedMessage id="auth.username" /></Label>
                  <Input
                    id="username"
                    value={username}
                    onChange={e => setUsername(e.target.value)}
                    autoFocus
                  />
                </div>
                <div>
                  <Label htmlFor="password"><FormattedMessage id="auth.password" /></Label>
                  <Input
                    id="password"
                    type="password"
                    value={password}
                    onChange={e => setPassword(e.target.value)}
                  />
                </div>
                <div>
                  <Label htmlFor="confirm"><FormattedMessage id="auth.confirmPassword" /></Label>
                  <Input
                    id="confirm"
                    type="password"
                    value={confirmPassword}
                    onChange={e => setConfirmPassword(e.target.value)}
                  />
                </div>
              </div>

              {error && <p className="text-sm text-destructive">{error}</p>}

              <div className="flex justify-between">
                <Button type="button" variant="outline" onClick={() => setStep('welcome')}>
                  <FormattedMessage id="common.back" />
                </Button>
                <Button type="submit">
                  <FormattedMessage id="setupWizard.continue" />
                </Button>
              </div>
            </form>
          )}

          {step === 'config' && (
            <form onSubmit={handleConfigSubmit} className="space-y-6">
              <div className="space-y-2">
                <h2 className="text-xl font-semibold">
                  <FormattedMessage id="setupWizard.config.title" />
                </h2>
                <p className="text-sm text-muted-foreground">
                  <FormattedMessage id="setupWizard.config.description" />
                </p>
              </div>

              <div className="space-y-4">
                <div>
                  <Label htmlFor="deltaAnnual">
                    <FormattedMessage id="setupWizard.config.deltaAnnual" />
                  </Label>
                  <Input
                    id="deltaAnnual"
                    type="number"
                    value={deltaAnnual}
                    onChange={e => setDeltaAnnual(e.target.value)}
                  />
                </div>
                <div>
                  <Label htmlFor="autoLogout">
                    <FormattedMessage id="setupWizard.config.autoLogout" />
                  </Label>
                  <Input
                    id="autoLogout"
                    type="number"
                    value={autoLogout}
                    onChange={e => setAutoLogout(e.target.value)}
                  />
                </div>
              </div>

              {error && <p className="text-sm text-destructive">{error}</p>}

              <div className="flex justify-between">
                <Button type="button" variant="outline" onClick={() => setStep('account')}>
                  <FormattedMessage id="common.back" />
                </Button>
                <Button type="submit" disabled={submitting}>
                  {submitting
                    ? <FormattedMessage id="setupWizard.submitting" />
                    : <FormattedMessage id="setupWizard.finish" />
                  }
                </Button>
              </div>
            </form>
          )}

          {step === 'done' && (
            <div className="text-center space-y-6">
              <div className="space-y-2">
                <h2 className="text-xl font-semibold">
                  <FormattedMessage id="setupWizard.done.title" />
                </h2>
                <p className="text-sm text-muted-foreground">
                  <FormattedMessage id="setupWizard.done.description" />
                </p>
              </div>

              <div className="space-y-3">
                <Button
                  variant="outline"
                  className="w-full justify-start text-left h-auto py-4 px-6"
                  onClick={() => navigate('/import')}
                >
                  <div>
                    <div className="font-medium">
                      <FormattedMessage id="setupWizard.done.importCsv" />
                    </div>
                    <div className="text-xs text-muted-foreground">
                      <FormattedMessage id="setupWizard.done.importCsvDesc" />
                    </div>
                  </div>
                </Button>

                <Button
                  variant="outline"
                  className="w-full justify-start text-left h-auto py-4 px-6"
                  onClick={() => navigate('/config')}
                >
                  <div>
                    <div className="font-medium">
                      <FormattedMessage id="setupWizard.done.restoreBackup" />
                    </div>
                    <div className="text-xs text-muted-foreground">
                      <FormattedMessage id="setupWizard.done.restoreBackupDesc" />
                    </div>
                  </div>
                </Button>

                <Button
                  className="w-full"
                  onClick={() => { onComplete(); navigate('/'); }}
                >
                  <FormattedMessage id="setupWizard.done.goDashboard" />
                </Button>
              </div>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
