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
  },

  integrations: [
    sitemap({
      // Portal is noindexed WIP; /dev is internal; /report is noindexed so listing it
      // would contradict the page itself; blog stays out until site.json blogPublic
      // flips to true (see MAINTENANCE.md).
      filter: (page) =>
        !page.includes('/portal') &&
        !page.includes('/dev/') &&
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
