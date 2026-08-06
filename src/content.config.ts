// ABOUTME: Content collections — blog posts (Phase 3 migrates the old Wix articles here).
// ABOUTME: The collection is always built; site.json blogPublic only controls visibility/indexing.
import { defineCollection, z } from 'astro:content';
import { glob } from 'astro/loaders';

const blog = defineCollection({
  loader: glob({ pattern: '**/*.md', base: './src/content/blog' }),
  schema: z.object({
    title: z.string(),
    description: z.string().optional(),
    date: z.coerce.date(),
    category: z.string().optional(),
    lang: z.enum(['en', 'fr']).default('en'),
  }),
});

export const collections = { blog };
