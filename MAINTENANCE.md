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

Posts live in `/src/content/blog/` as markdown with `title`, `date`, and optional
`description`, `category` (e.g. `delegate-story`), `lang` frontmatter. Old
`/post/:slug` URLs already 301 to `/blog/:slug` via `public/.htaccess`.

## Redirects

`public/.htaccess` holds all 301s from the old Wix routes. It ships as-is into
`dist/` on build — cPanel/Apache picks it up automatically.

## Forms

The Contact (`/contact`) and Incident (`/report`) forms post to `/api/contact.php`
and `/api/report.php`. The PHP handlers are built in Phase 4; on success they
should redirect back to the form page with `?submitted=1`, which shows the
confirmation state. The incident handler routes to the VP Internal configured in
`src/data/contact.json`.
