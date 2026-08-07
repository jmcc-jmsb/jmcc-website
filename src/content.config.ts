// ABOUTME: Content collections — blog posts migrated from Wix in Phase 3 (Case & Point archive).
// ABOUTME: The collection is always built; site.json blogPublic only controls visibility/indexing.
import { defineCollection, z } from 'astro:content';
import { glob } from 'astro/loaders';

const blog = defineCollection({
  loader: glob({ pattern: '**/*.md', base: './src/content/blog' }),
  schema: ({ image }) =>
    z.object({
      title: z.string(),
      description: z.string().optional(),
      pubDate: z.coerce.date(),
      updatedDate: z.coerce.date().optional(),
      author: z.string().default('JMCC'),
      category: z.enum(['delegate-story', 'getting-started', 'workshop']),
      cover: image().optional(),
      coverAlt: z.string().optional(),
      readTime: z.string().optional(),
      // Archived posts are English. Reviving the blog in French is an editorial
      // decision, not a migration one — never machine-translate these.
      lang: z.literal('en').default('en'),
      draft: z.boolean().default(false),
    }),
});

export const collections = { blog };
