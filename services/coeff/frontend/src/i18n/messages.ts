import en from './en';
import es from './es';

export type Locale = 'en' | 'es';

const messages: Record<Locale, Record<string, string>> = { en, es };

export function getMessages(locale: Locale): Record<string, string> {
  return messages[locale] || messages.en;
}

export function detectLocale(): Locale {
  const stored = localStorage.getItem('lang') as Locale | null;
  if (stored && (stored === 'en' || stored === 'es')) return stored;
  const browserLang = navigator.language || '';
  if (browserLang.startsWith('es')) return 'es';
  return 'en';
}

export function persistLocale(locale: Locale) {
  localStorage.setItem('lang', locale);
}

export function setLocale(locale: Locale) {
  persistLocale(locale);
  window.dispatchEvent(new Event('langchange'));
}

export function useLocale() {
  return detectLocale();
}

export const SUPPORTED_LOCALES: Locale[] = ['en', 'es'];
export const LOCALE_LABELS: Record<Locale, string> = { en: 'EN', es: 'ES' };
