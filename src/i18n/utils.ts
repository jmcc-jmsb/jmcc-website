// ABOUTME: i18n helpers — useTranslations() wraps t() for type-safe string lookup.
// ABOUTME: getLocalizedPath() builds /fr-prefixed URLs; getLangFromUrl() reads the current locale.

import en from './en.json';
import fr from './fr.json';

export type Locale = 'en' | 'fr';
type Dict = typeof en;
export type TranslationKey = keyof Dict;

const dicts = { en, fr } as Record<Locale, Dict>;

export function useTranslations(lang: Locale) {
  return function t(key: TranslationKey): string {
    return dicts[lang][key] ?? dicts.en[key];
  };
}

export function getLocalizedPath(path: string, lang: Locale): string {
  const normalized = path.startsWith('/') ? path : `/${path}`;
  if (lang === 'en') return normalized;
  return normalized === '/' ? '/fr' : `/fr${normalized}`;
}

export function getLangFromUrl(url: URL): Locale {
  const [, first] = url.pathname.split('/');
  return first === 'fr' ? 'fr' : 'en';
}
