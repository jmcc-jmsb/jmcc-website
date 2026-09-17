// @ts-check
import { defineConfig } from 'astro/config';
import tailwindcss from '@tailwindcss/vite';
import sitemap from '@astrojs/sitemap';
import site from './src/data/site.json';

export default defineConfig({
  // Canonical domain. wecompete.ca is primary; jmccjmsb.ca is legacy and 301s here.
  // `www` is canonical (the old site used it). Every absolute URL — canonical tags,
  // hreflang, sitemap — derives from this one value; never hardcode a hostname.
  site: 'https://www.wecompete.ca',

  i18n: {
    defaultLocale: 'en',
    locales: ['en', 'fr'],
    routing: {
      prefixDefaultLocale: false,
    },
  },

  vite: {
    plugins: [tailwindcss()],
    build: {
      // Never inline a font as a data: URL: .htaccess sets font-src 'self', which blocks
      // them. Some @fontsource subsets are under Vite's 4 KB inline limit.
      assetsInlineLimit: (file) => (/\.woff2?$/.test(file) ? false : undefined),
    },
  },

  integrations: [
    sitemap({
      // Portal is noindexed WIP; /report is noindexed so listing it would contradict
      // the page itself; blog stays out until site.json blogPublic flips to true
      // (see MAINTENANCE.md).
      filter: (page) =>
        !page.includes('/portal') &&
        !page.includes('/report') &&
        (site.blogPublic || !page.includes('/blog')),
      i18n: {
        defaultLocale: 'en',
        locales: {
          en: 'en-CA',
          fr: 'fr-CA',
        },
      },
    }),
  ],
});
