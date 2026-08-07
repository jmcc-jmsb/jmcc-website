# Maintenance

## Yearly content updates

Everything that changes year to year lives in `/src/data/` — never edit page files for these:

| What | File |
|---|---|
| Home page stat counters | `src/data/stats.json` |
| Executive roster | `src/data/team.json` (headshots in `/src/assets/photos/team/`) |
| Sponsors and tiers | `src/data/sponsors.json` (logos in `/src/assets/sponsors/`, named `sponsor-<name>.png`) |
| Competitions (internationals + regionals) | `src/data/competitions.json` (logos in `/src/assets/competitions/`) |
| Contact details, socials, VP Internal | `src/data/contact.json` |
| Sign-up URL, donation URL, deadlines | `src/data/site.json` |

Every user-facing string in these files carries `en` and `fr` fields — always fill both.

## Reviving the blog

The blog is fully built but hidden. Flip one flag in `src/data/site.json`:

```json
"blogPublic": true
```

That single change switches on, at the next build:
- the Blog link in the nav,
- inclusion in `sitemap.xml`,
- indexing (removes `noindex, nofollow` from all `/blog` routes).

Nothing else needs editing — the routes, posts, images, and redirects are already built.

### What was migrated (Phase 3)

The **Case & Point** archive: 11 posts moved off Wix into `/src/content/blog/`, with
images in `/src/assets/blog/<slug>/`. Routes are `/blog`, `/blog/<slug>`, and
`/blog/categories/<category>`, each with a `/fr/` equivalent.

Frontmatter is validated by `src/content.config.ts`:

| Field | Notes |
|---|---|
| `title`, `description` | from the original `og:` tags |
| `pubDate`, `updatedDate` | real Wix publish/modify timestamps — never backfill these |
| `author` | the `JMCC` house account on all 11 |
| `category` | `delegate-story` \| `getting-started` \| `workshop` (labels in `src/data/blog-categories.ts`) |
| `cover`, `coverAlt` | full-resolution original; alt text was written by hand, Wix had none |
| `readTime`, `draft` | `draft: true` hides a post without deleting it |
| `lang` | always `en` |

**Archived posts are English and stay English.** The FR routes render the English body
with a note saying so. Translating them is an editorial decision for whoever revives the
blog — do not machine-translate the archive.

**Do not modernize archived copy.** Post #6 covers the *HR Symposium (Symposium GRH)*,
which is now the Management Symposium (SMNG). The old name stays in the archive; the
rename applies only to current site copy in `competitions.json` and the pages.

### ⚠ The Wix archive — back this up

`wix-archive/` at the repo root is **gitignored** and holds the only remaining copy of the
Wix source once the subscription lapses:

| Folder | Contents |
|---|---|
| `wix-archive/html/` | raw HTML of all 11 posts as fetched from Wix |
| `wix-archive/images/` | full-resolution originals (~102 MB) |
| `wix-archive/video/` | the 1080p original of the Symposium post video |

What ships in git is the web-ready copy: images downscaled to a 2400px long edge
(PNG photographs re-encoded as JPEG) and the video re-encoded to 720p. That is enough for
the site, but **copy `wix-archive/` to Drive** — it is not in any clone, and re-fetching
from Wix will not be possible.

### Redirects for the old blog

`public/.htaccess` maps every old Wix blog URL:

- `/post/:slug` → `/blog/:slug` for all 11, using the original slugs verbatim
  (including the awkward `-s-` / `-re-` apostrophe forms)
- the accented `/post/from-montréal-...` and its `%C3%A9` form → the ASCII slug
- `/blog/page/N` → `/blog`

## Redirects

`public/.htaccess` holds all 301s from the old Wix routes. It ships as-is into
`dist/` on build — cPanel/Apache picks it up automatically.

## Forms

The Contact (`/contact`) and Incident (`/report`) forms post to `/api/contact.php`
and `/api/report.php`. The PHP handlers are built in Phase 4; on success they
should redirect back to the form page with `?submitted=1`, which shows the
confirmation state. The incident handler routes to the VP Internal configured in
`src/data/contact.json`.
