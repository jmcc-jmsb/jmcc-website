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

## Domain

`www.wecompete.ca` is canonical. It is set **once**, in `astro.config.mjs → site`, and
every canonical tag, `hreflang`, and sitemap entry derives from it. Never hardcode a
hostname in a component.

`jmccjmsb.ca` is legacy: it 301s to wecompete.ca preserving the path, so old bookmarks
and the Wix-era URLs keep working.

**Two layers, two owners — neither covers the other:**

| Layer | Owner | What |
|---|---|---|
| Domain → server, SSL | CASA IT (Ryan) | Points both domains at this document root; 301s jmccjmsb.ca → wecompete.ca |
| Path → path | us, in `public/.htaccess` | `/regionals` → `/competitions`, `/post/:slug` → `/blog/:slug`, and the rest |

A visitor hitting `jmccjmsb.ca/regionals` needs *both*. Apex `wecompete.ca` → `www` is
handled in our `.htaccess`.

## Forms

### Contact — `/contact` → `public/api/contact.php`

PHP 8.2+, no Composer, standard library only. JSON in, JSON out; the page renders the
result inline without navigating. Sends to the address in `config.php`, with `Reply-To`
set to the submitter so replies work straight from the inbox.

Spam handling is layered, no CAPTCHA:
1. **Honeypot** — an off-screen `website` field. Filled means bot: the response is a
   normal success and the message is discarded, so the bot gets no signal.
2. **Timing** — the endpoint issues an HMAC-signed timestamp on `GET`; the page fetches
   one on load and returns it on submit. Under 3 seconds is treated as a bot; tokens
   expire after 2 hours.
3. **Rate limit** — 5 per IP per hour, counted in files.

#### ⚠ Create the state directory before first use

```
mkdir -p /home/jmcc/form-state && chmod 700 /home/jmcc/form-state
```

It holds the rate-limit counters, the signing key, and `contact.log`. It **must** sit
outside the deploy target: deploys run `rsync --delete`, which would wipe it every time,
resetting rate limits and rotating the signing key out from under open forms.

The path is `STATE_DIR` in `public/api/config.php`. If the directory is missing and PHP
cannot create it, the endpoint returns 500 rather than quietly running without spam
protection — so a broken contact form is the visible symptom of a missing state dir.

All configuration — recipient, sender, limits, paths — is in `public/api/config.php`.
No secrets live there: the signing key is generated into the state directory on first use.

### Incident report — `/report` → embedded Google Form

No backend. The page wraps a Google Form; set the embed URLs in
`src/data/site.json → incidentFormUrl` (`en` and `fr`). Until they are set, the page
renders a "being set up" state with a direct email address — never a blank iframe.

#### ⚠ Verify on the Form itself before launch

Several Workspace defaults are wrong for this use case:

| Setting | Required | Why |
|---|---|---|
| Restrict to users in your organization | **OFF** | On by default; forces a Concordia login, which destroys anonymity |
| Collect email addresses | **OFF** | Otherwise every submission is identified |
| Limit to 1 response | **OFF** | Requires sign-in — same problem |
| Response destination | confirm | Should notify a role address, not a personal one |
| Confirmation message | review | Should say what happens next |

Then set `site.json → incidentFormAnonymous`:

- `true` — only after confirming all three are off. This is what makes the page say
  "you may submit anonymously".
- `false` — if any cannot be turned off. **The page must not claim anonymity it does
  not provide**; raise it with the VP Internal instead.
- `null` (current) — unverified, so the page makes no claim either way.

**Bilingual approach is the VP Internal's call**, and it is not yet made. Options, best
first: two Forms (EN + FR, cleanest, needs two response sheets); one bilingual Form
(single destination, cluttered); one English Form on both routes (acceptable short-term,
weak for a bilingual organisation in Quebec). `incidentFormUrl` takes two URLs, so any
option works — put the same URL in both fields for the third.

The page discloses that the Form is Google-hosted and keeps a prominent
"open in a new tab" fallback, since privacy extensions routinely block third-party
iframes and would otherwise leave a blank box.
