# Maintenance

**This guide is written for whoever runs the site next, not for a developer.** You do not
need to understand Astro to keep the site current. Almost everything that changes year to
year is a small edit to a text file — no page code involved.

---

## The short version

| I want to… | Edit this |
|---|---|
| Update the numbers on the homepage | `src/data/stats.json` |
| Change the executive roster | `src/data/team.json` |
| Add or remove a sponsor | `src/data/sponsors.json` |
| Change competitions or their descriptions | `src/data/competitions.json` |
| Change the email, address, or social links | `src/data/contact.json` |
| Change the disciplines list or which ones feature on Home | `src/data/competitions.json` (`disciplines`) |
| **Refresh the Instagram grid on Home** | `src/data/instagram.json` + images in `src/assets/instagram/` |
| Add an FAQ entry | `src/data/faq.json` |
| Add a donate-page testimonial | `src/data/testimonials.json` |
| Add an alumni employer to the Home strip | `src/data/alumni-companies.json` |
| Set the delegate sign-up link | `src/data/site.json` |
| Set the mailing-list link (shown while recruitment is closed) | `src/data/site.json` |
| Set the incident form link | `src/data/site.json` |
| Turn the blog back on | `src/data/site.json` |
| Replace the portal placeholder | `src/pages/portal.astro` |

Everything in `src/data/` is a **JSON file**: a list of labelled values. The rules are:

1. **Every quote, comma, and bracket matters.** Change the text between the quotes, not the
   punctuation around it.
2. **Every visible string has an `en` and an `fr` version.** Fill both. If you genuinely
   have no French yet, put the English in both rather than leaving one empty.
3. **Anything starting with `TODO_` is a placeholder.** The site is built to hide those
   gracefully — an unset sign-up link shows "Applications opening soon" instead of a dead
   button. Replacing the placeholder is what switches the real thing on.
4. **Lines starting with `_` are notes to you**, not content. They are ignored by the site.

After any edit, the site rebuilds and redeploys automatically when the change is pushed.
See *How a deploy happens* below.

---

## Common jobs, step by step

### Update the homepage numbers

`src/data/stats.json`. Change `value`; leave `suffix` (the `+`) alone unless you mean to.

### Add a sponsor

1. Save the logo into `src/assets/sponsors/`, named `sponsor-<name>.png`.
2. Add an entry to `src/data/sponsors.json` under the right tier, with the name, the logo
   filename, and their website.

A sponsor with `"logo": null` still renders — it shows the name as text rather than a
broken image.

### Update the exec roster

1. Headshots go in `src/assets/photos/team/`.
2. Edit `src/data/team.json` — name, role (with `en` and `fr`), email, headshot filename.

Missing headshots fall back to a branded placeholder, so it is safe to add someone before
their photo arrives.

### Add photos to the site

Full guidance is in [`ASSETS.md`](ASSETS.md). The short version:

- Site photos live in `src/assets/photos/` and are registered in `src/data/photos.ts`
  with their alt text (both languages) and a focal point.
- **Never overlay a headline on a photo containing people** — that is a standing brand
  rule. Use a split layout instead.
- The focal point controls what stays visible when a photo is cropped into a narrow band.
  If a photo starts showing people's chests instead of their faces, that value needs
  lowering.

### Update the Instagram section ⚠ the one recurring manual job

The "Latest on Instagram" grid on Home is **manually curated** — no API, no widget,
nothing refreshes itself. It is the only part of the site that needs periodic manual
updating. If nobody updates it, delete the entries — the section then disappears
entirely, which is better than showing months-old posts.

1. Save **3 or 6** post images into `src/assets/instagram/` (any filename, jpg/png/webp).
   The grid is 3 across, so those two counts fill their rows; 4 or 5 leave a lone card
   dangling on the last row.
2. Save them at **4:5** (e.g. 512×640) — the shape Instagram graphics are designed in.
   Reel covers download as 9:16; crop those to 4:5 from the **top**, where the headline
   sits, or the headline gets cut off.
3. Edit `src/data/instagram.json` — for each post: the image filename, alt text in
   `en` and `fr`, and the post's full `instagram.com` permalink.
4. Push. Done — the grid links each image to its post and the section header links
   to the profile.

### Add a season to the trophy cabinet ⚠ every year, after the season ends

`/trophy-cabinet` is built from `src/data/results.json` and is **the only page with a
standing annual obligation**. It belongs to **VP Academics**, not VP Tech — whoever holds
that role knows the results. Put it in the handover.

1. Add a season object to `seasons`: `season` reads `"2025-2026"`, then one entry per
   result with a `competition` slug, an optional `discipline` slug, and a `placement`
   of `1`, `2`, `3`, `"finalist"` or `"honourable"`.
2. Slugs must match `src/data/competitions.json`. **A slug that matches nothing fails the
   build** with the offending value in the error — that is deliberate, so a typo shows up
   the day it is made rather than as an empty filter a season later. Competition slugs are
   matched without their edition year, so `tubc` matches `tubc-2026`.
3. **Never list delegate names.** Results stay institutional: naming people means consent
   from every one of them, and it dates badly as rosters turn over.
4. Optionally set `photo` on the season to a key from `src/data/photos.ts` to run that
   season's podium shot under its heading.
5. `npm run test:results` checks all of this without a server.

While `seasons` is empty the page holds a coming-soon state, is noindexed, and the home
strip and podium counts stay hidden. **The route is deliberately not in the nav yet** —
add it to `src/components/Nav.astro` under Competitions once there are results worth
showing.

### Replace the portal placeholder

`src/pages/portal.astro` currently renders a "coming soon" panel via
`src/components/PortalPlaceholder.astro`. Replace the placeholder with the real content
when the delegate portal exists. The page is already noindexed.

---

## Yearly content updates — reference

Everything that changes year to year lives in `/src/data/` — never edit page files for these:

| What | File |
|---|---|
| Home page stat counters | `src/data/stats.json` |
| Executive roster | `src/data/team.json` (headshots in `/src/assets/photos/team/`) |
| Sponsors and tiers | `src/data/sponsors.json` (logos in `/src/assets/sponsors/`, named `sponsor-<name>.png`) |
| Competitions (internationals + regionals) | `src/data/competitions.json` (logos in `/src/assets/competitions/`) |
| Contact details, socials, VP Internal | `src/data/contact.json` |
| Sign-up URL, donation URL, deadlines | `src/data/site.json` |
| Competition results (trophy cabinet) | `src/data/results.json` — **VP Academics, every season** |

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

`public/.htaccess` holds all 301s from the old Wix routes, plus the canonical host rule,
security headers, compression, and caching. It ships as-is into `dist/` on build —
cPanel/Apache picks it up automatically.

Verify it after any change, against whichever environment you are testing:

```
powershell -NoProfile -File tests/check-redirects.ps1 -BaseUrl https://staging.wecompete.ca
```

It asserts that every legacy path returns 301, lands on the right page, and does so in
**one hop** — redirect chains are the usual way this file quietly degrades.

⚠ **This file only works if the host allows it.** If `AllowOverride` is restricted on
CASA's server, none of it applies and the rules must move into the vhost config. That is
question 1 in [`docs/hosting-questions.md`](docs/hosting-questions.md).

---

## How a deploy happens

1. A change is pushed to `master` (via a pull request).
2. GitHub Actions builds the site and checks the build did not leak the old domain.
3. It rsyncs the built `dist/` folder to the cPanel document root.
4. It requests the homepage and fails the run if it does not return 200.

**How to tell it worked:** open the repo on GitHub → **Actions** tab. A green tick on the
most recent run means the deploy succeeded. Click into a run to see what it did.

**If it is red**, the site is unchanged — the deploy either failed before uploading or the
smoke test caught a broken homepage. Nothing is half-deployed; rsync either completes or
it does not.

**To deploy manually** (Actions → *Build and deploy* → *Run workflow*): leave **dry run**
ticked the first time. That previews exactly which files would change without writing
anything.

### Before the first real deploy

The deploy steps skip themselves until these are set in the repo settings:

| Kind | Name | What |
|---|---|---|
| Variable | `CPANEL_SSH_HOST` | server hostname |
| Variable | `CPANEL_SSH_USER` | SSH username |
| Variable | `CPANEL_SSH_PORT` | if not 22 |
| Variable | `CPANEL_DEPLOY_PATH` | document root |
| Variable | `CPANEL_KNOWN_HOSTS` | server's SSH host key, so it is pinned rather than trusted blindly |
| Variable | `SITE_URL` | used by the smoke test |
| Secret | `CPANEL_SSH_KEY` | private half of the deploy key |

### Rotating the deploy key

Do this when a VP Tech hands over, or if the key may have been exposed.

1. Generate a new pair: `ssh-keygen -t ed25519 -C "jmcc-deploy" -f jmcc-deploy`
2. Send the **public** half (`jmcc-deploy.pub`) to CASA IT to add to the server's
   authorised keys; ask them to remove the old one.
3. Put the **private** half into the repo secret `CPANEL_SSH_KEY`
   (Settings → Secrets and variables → Actions).
4. Delete both local files. Run the workflow with dry run ticked to confirm it connects.

Never commit a key. `.gitignore` covers `*.pem`, `id_rsa*`, and `.ssh/`, but the safest
habit is to generate keys outside the repo folder entirely.

## Who to contact

- **Hosting, DNS, SSL, server access** — CASA IT (Ryan). Open questions are written up in
  [`docs/hosting-questions.md`](docs/hosting-questions.md); send that file as-is.
- **Incident form, anything about `/report`** — the VP Internal named in
  `src/data/contact.json`.

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
result inline without navigating. Sends to `contactFormTo` in `src/data/contact.json` —
the build ships it to `/api/contact.json` and `config.php` reads it at runtime, so the
recipient is never hardcoded in PHP. `Reply-To` is set to the submitter so replies work
straight from the inbox.

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
