// @ts-check
import { defineConfig } from 'astro/config';
import tailwindcss from '@tailwindcss/vite';
import sitemap from '@astrojs/sitemap';
import site from './src/data/site.json';

export default defineConfig({
  site: 'https://www.jmccjmsb.ca',

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
      // Portal is noindexed WIP; /dev is internal; blog stays out of the sitemap
      // until site.json blogPublic flips to true (see MAINTENANCE.md).
      filter: (page) =>
        !page.includes('/portal') &&
        !page.includes('/dev/') &&
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
