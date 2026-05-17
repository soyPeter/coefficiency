import { useState, useEffect, useCallback } from 'react';
import { IntlProvider } from 'react-intl';
import { HelmetProvider } from 'react-helmet-async';
import { AppRouting } from '@/routing/app-routing';
import LoginPage, { hasValidToken, clearToken } from '@/pages/LoginPage';
import { detectLocale, getMessages, type Locale } from '@/i18n/messages';
import { useIdleTimer } from '@/hooks/useIdleTimer';
import AutoLogoutDialog from '@/components/AutoLogoutDialog';

const BASE = '/api';

// REQ-AUTO-005: auto-logout on expired
// REQ-AUTO-006: activity resets during countdown
// REQ-AUTO-007: event listener cleanup via hook unmount
export function App() {
  const [locale, setLocale] = useState<Locale>(detectLocale);
  const [authenticated, setAuthenticated] = useState(hasValidToken);
  const [idleTimeoutMs, setIdleTimeoutMs] = useState(900000);

  useEffect(() => {
    if (!authenticated) return;
    const token = localStorage.getItem('token');
    fetch(`${BASE}/settings`, {
      headers: token ? { 'Authorization': `Bearer ${token}` } : {},
    })
      .then(r => r.json())
      .then(d => {
        const minutes = parseInt(d.autoLogoutTimeout) || 15;
        setIdleTimeoutMs(minutes * 60 * 1000);
      })
      .catch(() => {});
  }, [authenticated]);

  const handleExpired = useCallback(() => {
    navigator.sendBeacon('/api/auth/logout');
    clearToken();
    window.location.reload();
  }, []);

  const { idleState, timeLeft, resetTimer } = useIdleTimer({
    enabled: authenticated,
    idleTimeout: idleTimeoutMs,
    onExpired: handleExpired,
  });

  useEffect(() => {
    const handler = () => setLocale(detectLocale());
    window.addEventListener('langchange', handler);
    return () => window.removeEventListener('langchange', handler);
  }, []);

  useEffect(() => {
    const handler = () => { clearToken(); window.location.reload(); };
    window.addEventListener('auth:unauthorized', handler);
    return () => window.removeEventListener('auth:unauthorized', handler);
  }, []);

  const handleLogin = useCallback(() => setAuthenticated(true), []);

  return (
    <IntlProvider locale={locale} messages={getMessages(locale)} defaultLocale="en">
      <HelmetProvider>
        {authenticated ? (
          <>
            <AppRouting />
            <AutoLogoutDialog
              open={idleState === 'countdown'}
              timeLeft={timeLeft}
              onStayLoggedIn={resetTimer}
            />
          </>
        ) : (
          <LoginPage onLogin={handleLogin} />
        )}
      </HelmetProvider>
    </IntlProvider>
  );
}
