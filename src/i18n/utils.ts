// ABOUTME: i18n helpers — useTranslations() wraps t() for type-safe string lookup.
// ABOUTME: getLocalizedPath() builds /fr-prefixed, slash-terminated URLs; getLangFromUrl() reads the locale.

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

// Every page builds to a folder (who-we-are/index.html), and Apache 301s a slashless
// /who-we-are to /who-we-are/. Links carry the slash so a click never costs that hop.
// The slash goes before any ?query or #hash; file paths (with an extension) are left alone.
function withTrailingSlash(path: string): string {
  const cut = path.search(/[?#]/);
  const pathname = cut === -1 ? path : path.slice(0, cut);
  const rest = cut === -1 ? '' : path.slice(cut);
  if (pathname.endsWith('/') || /\.[a-z0-9]+$/i.test(pathname)) return path;
  return `${pathname}/${rest}`;
}

export function getLocalizedPath(path: string, lang: Locale): string {
  const normalized = path.startsWith('/') ? path : `/${path}`;
  if (lang === 'en') return withTrailingSlash(normalized);
  return withTrailingSlash(normalized === '/' ? '/fr' : `/fr${normalized}`);
}

export function getLangFromUrl(url: URL): Locale {
  const [, first] = url.pathname.split('/');
  return first === 'fr' ? 'fr' : 'en';
}
