// ABOUTME: Display names for the three Case & Point categories, keyed by the schema enum.
// ABOUTME: Archived posts are English; the FR labels are for chrome only, not post content.
export const BLOG_CATEGORIES = {
  'delegate-story': { en: 'Delegate Story', fr: 'Récit de délégué' },
  'getting-started': { en: 'Getting Started', fr: 'Pour commencer' },
  workshop: { en: 'Workshop', fr: 'Atelier' },
} as const;

export type BlogCategory = keyof typeof BLOG_CATEGORIES;
