import { useEffect, useState } from 'react';
import { ChevronDown } from 'lucide-react';
import { detectLocale, setLocale, SUPPORTED_LOCALES, LOCALE_LABELS, type Locale } from '@/i18n/messages';

export function LanguageSwitcher() {
  const [locale, setLocalState] = useState<Locale>(detectLocale);

  useEffect(() => {
    const handler = () => setLocalState(detectLocale());
    window.addEventListener('langchange', handler);
    return () => window.removeEventListener('langchange', handler);
  }, []);

  return (
    <div className="relative">
      <select
        value={locale}
        onChange={(e) => setLocale(e.target.value as Locale)}
        className="w-full appearance-none bg-transparent border border-border rounded-md px-2 py-1 text-xs text-muted-foreground cursor-pointer"
      >
        {SUPPORTED_LOCALES.map((l) => (
          <option key={l} value={l}>{LOCALE_LABELS[l]}</option>
        ))}
      </select>
      <ChevronDown className="absolute right-2 top-1/2 -translate-y-1/2 size-3 text-muted-foreground pointer-events-none" />
    </div>
  );
}
