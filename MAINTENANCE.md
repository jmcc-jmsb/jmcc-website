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
| **Open or close delegate recruitment** | `src/data/site.json` (`signupForms` + `recruitmentOpen`) |
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

#### If a new post shows its alt text instead of its image, restart the dev server

Only ever seen locally, and it is **not** a problem with your image or your JSON. A dev
server that was already running before you added the file can fail to process it, serving
`500 MissingSharp` for that one image while every image it had already handled keeps
working — so exactly the new post looks broken and the older ones look fine.

Stop and restart it (`astro dev stop`, then `astro dev --background`) and the image
appears. Nothing to fix and nothing to commit.

Worth knowing so nobody re-crops a perfectly good image chasing this: **the published
site is unaffected.** `npm run build` starts fresh every time, so it processes the new
image correctly even while the running dev server is failing on it. If you want to
confirm before pushing, run `npm run build` — a real problem with the file fails the
build, this one does not.

#### Collecting the posts without being handed them

`@jmcconline` is a public profile, so the posts can be read straight off the web
without an API, an access token, or a login. This is how the 2026-08-24 refresh was
done, and it is repeatable:

1. Open `https://www.instagram.com/jmcconline/`. Logged out, the page still renders
   the post grid. Each tile is a link — `/jmcconline/p/<id>/` for a photo or carousel,
   `/jmcconline/reel/<id>/` for a reel. **Those URLs are the permalinks**, and they are
   in newest-first order, so the first six tiles are the six you want.
2. Open each post URL. The page carries everything else needed:
   - `<time datetime="…">` — the post date, for the `YYYY-MM-DD-` filename prefix.
   - `og:description` — likes, comments, date and the **full caption**, which is what
     the alt text should be written from.
   - The post image itself in the DOM at full resolution (1080×1350 or larger).
     Take the one whose `naturalWidth` is ≥ 1000; anything smaller is a
     "more posts from" thumbnail from the sidebar, not this post.
3. Download that image URL and resize it to 512×640, quality ~80. The CDN links are
   **signed and short-lived** — download them in the same sitting you collected them
   in, or they expire and you have to re-open the post.
4. Continue from step 2 above: write the bilingual alt text, then edit
   `instagram.json`.

Two caveats worth knowing before relying on this:

- It depends on Instagram's public markup, which they change without notice. When it
  breaks, the fallback is what it always was — save the images by hand and copy the
  permalinks out of the address bar.
- It was verified on **photo posts** (`/p/`). Reel pages are laid out the same way, but
  the 2026-08-24 refresh did not need one, so that path is untested. Reel covers are
  9:16 and still need the top crop described above.

### Open and close delegate recruitment ⚠ every sign-up period

The team makes **new forms every cycle**, so the links can never be preset — they get pasted
in when they exist. Two values in `src/data/site.json` do the whole job, and the page is
built so that neither a missing link nor a mistimed toggle can produce a dead button.

**To open recruitment:**

1. Add each form to `signupForms` — a `url` and a `label` in `en` and `fr`. There can be one
   form or several; each renders as its own gold button on Get Involved, in array order.
   **Put the broadest form first.**
2. Set `recruitmentOpen` to `true`.
3. Push. Get Involved shows the buttons; the Home recruitment band switches to "Get Involved"
   and links to that page.

**To close it:**

1. Set `recruitmentOpen` back to `false`. Push.

That is the whole close — the mailing-list CTA returns on its own. Leave the old entries
sitting in `signupForms`: nothing reads them while the flag is off, and they are a record of
which forms ran last cycle.

**Labels are the button text**, so write them as the applicant would recognise their stream
("General Involvement", "Rugby — SMNG"), not as a generic "Apply now". With more than one
form on the page, the label is the only thing telling someone which one is theirs.

**The Home band never links to a form.** It routes to Get Involved, because it is a single
button and there is no safe way for it to pick one form on the visitor's behalf. This holds
whether there is one form or five — do not special-case it back to a direct link.

The CTA slot has three states, and none of them is a dead link, so **unset URLs never
block a launch**:

| `recruitmentOpen` | `signupForms` | What renders on Get Involved |
|---|---|---|
| `true`  | at least one real URL | one gold button per form |
| `false` | anything              | "Join the mailing list" → `mailingListUrl` |
| `true`  | empty, or all `TODO_` | "Applications opening soon" + a link to follow the Instagram |

That third row is the safety net: flipping the flag before the URLs are in cannot break the
page. It also means **if you set the flag and see "Applications opening soon" instead of the
buttons, the URLs are the thing that is missing** — check `signupForms` before anything else.

Two things to check on the Google Form itself before announcing it:

- **Use the published `/forms/d/e/<long-id>/viewform` URL** from Send > `<>`, never a
  `/forms/d/<doc-id>/` one. The doc-id variant leaks the editable document ID into public
  page source. Same rule as the incident form.
- **Check whether it requires a Google sign-in.** Both forms live as of 2026-08-24 do —
  `/viewform` redirects to `accounts.google.com`, so an applicant without a Google account
  cannot submit. That may be intentional (it is how you get one response per person), but it
  is worth knowing it is a filter, and it is invisible from our side of the link.

Note: `signupDeadline` in the same file is **not rendered anywhere** — it was reserved for a
deadline line that was never built. Setting it does nothing today.

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

### The Wix archive — backed up in Drive

`wix-archive/` at the repo root is **gitignored**, so it is in no clone. Its copy lives in
the **team Google Drive** (confirmed 2026-08-20) — that is the one to protect, because it
holds the only remaining copy of the Wix source once the subscription lapses:

| Folder | Contents |
|---|---|
| `wix-archive/html/` | raw HTML of all 11 posts as fetched from Wix |
| `wix-archive/images/` | full-resolution originals (~102 MB) |
| `wix-archive/video/` | the 1080p original of the Symposium post video |

What ships in git is the web-ready copy: images downscaled to a 2400px long edge
(PNG photographs re-encoded as JPEG) and the video re-encoded to 720p. That is enough for
the site, but the Drive copy is what survives — re-fetching from Wix will not be possible.
**Carry it through every exec handover**, and re-check it is still there whenever Drive
ownership moves between accounts.

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

### Staging is noindexed by host, not by build

`.htaccess` sets `X-Robots-Tag: noindex, nofollow` on any host beginning `staging.`. Scoping
it by host rather than by a staging build means one artifact deploys unchanged to both
environments, and no wrong-artifact deploy can ever deindex production.

Host-scoped rules cannot be checked by sending a `Host` header: the local harness rewrites
`Host` at post-read-request, before mod_rewrite sees it. Tell the harness which host to
pretend to be instead:

```
npm run build
powershell -NoProfile -File tests/serve-apache.ps1 -SimulateHost staging.wecompete.ca
powershell -NoProfile -File tests/check-redirects.ps1 -BaseUrl http://localhost:8080 -SimulateHost staging.wecompete.ca
```

Omit `-SimulateHost` on both and the suite asserts the opposite case — that a non-staging
host receives no such header. Run it both ways after touching the header block.

**This file only works because the host allows it.** CASA confirmed `AllowOverride` is
enabled (question 1 in [`docs/hosting-questions.md`](docs/hosting-questions.md)). If that
ever changes, none of it applies and the rules must move into the vhost config.

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

### Undo a bad deploy

Every deploy comes from a merge on `master`, so undoing a deploy means undoing the merge:

1. On GitHub, open the pull request that caused it and click **Revert**. That opens a new
   pull request which undoes it.
2. Merge that pull request. Staging updates on its own within a few minutes — check it.
3. Deploy production: Actions → *Build and deploy* → *Run workflow*, target
   **production**, dry run unticked.

Nothing is lost: the original change stays in git history and can be brought back by
reverting the revert. Files that only live on the server (`config.local.php`, the form
state directory, cPanel's `php.ini`) are never touched by a deploy, so a revert leaves
them as they are.

### Deploy settings

Repo settings → **Secrets and variables → Actions**. The deploy steps skip themselves if
the host, user or path is missing. All of these are set as of 2026-09-14.

| Kind | Name | Where | Value |
|---|---|---|---|
| Variable | `CPANEL_SSH_HOST` | repo | `www2.casajmsb.net` |
| Variable | `CPANEL_SSH_USER` | repo | `jmccjmsb` |
| Variable | `CPANEL_SSH_PORT` | repo | `22` |
| Variable | `CPANEL_KNOWN_HOSTS` | repo | the server's SSH host keys, so they are pinned rather than trusted blindly |
| Secret | `CPANEL_SSH_KEY` | repo | private half of the deploy key |
| Variable | `CPANEL_DEPLOY_PATH` | **per environment** | `staging`: `/home/jmccjmsb/staging.jmccjmsb.ca/` · `production`: `/home/jmccjmsb/public_html/` |
| Variable | `SITE_URL` | **per environment** | `staging`: `https://staging.wecompete.ca` · `production`: `https://www.wecompete.ca` (used by the smoke test) |

Keep `CPANEL_DEPLOY_PATH` on the environments, never on the repo. Every push to `master`
deploys to the `staging` environment, so a repo-level path would send ordinary pushes
wherever it pointed.

### Files cPanel keeps in the document root

The deploy runs `rsync --delete`, so anything on the server that is not in `dist/` is
removed unless `deploy.yml` excludes it. cPanel puts these in every document root:

| File | What the deploy does with it |
|---|---|
| `.well-known/` | Excluded — AutoSSL renews the certificates through it |
| `php.ini`, `.user.ini` | Excluded — cPanel's PHP settings. `.htaccess` denies fetching them |
| `.htaccess` | **Replaced** by `public/.htaccess`. cPanel's PHP error-log block is copied into section 9 of ours |

If anyone changes a setting in cPanel → **MultiPHP INI Editor**, copy the new
`# BEGIN cPanel-generated` block from the server's `.htaccess` into section 9 of
`public/.htaccess` as well, or the next deploy quietly reverts it.

### Rotating the deploy key

Do this when a VP Tech hands over, or if the key may have been exposed.

In PowerShell, somewhere outside the repo (`cd $env:TEMP`):

1. Generate a new pair: `ssh-keygen -t ed25519 -C "jmcc-deploy" -f jmcc-deploy`. Press
   Enter twice for no passphrase; GitHub Actions cannot type one.
2. Upload the **private** half straight from the file:
   `cmd /c "gh secret set CPANEL_SSH_KEY --repo jmcc-jmsb/jmcc-website < jmcc-deploy"`.
   Do not paste it into the web form, and do not pipe it from PowerShell. Both can alter
   line endings, and a mangled key fails with `Load key ...: error in libcrypto`. That is
   how the first key broke.
3. Copy the **public** half: `Get-Content jmcc-deploy.pub | Set-Clipboard`. In cPanel →
   **SSH Access → Manage SSH Keys → Import Key**, paste it into the *public* key box.
   Leave the private key and passphrase boxes empty; clear the passphrase box if the
   browser auto-filled it. Then click **Manage → Authorize**.
4. Run the workflow with dry run ticked to confirm it connects.
5. Once it does, delete the old key in cPanel and both local files.

Never commit a key. `.gitignore` covers `*.pem`, `id_rsa*`, and `.ssh/`, but the safest
habit is to generate keys outside the repo folder entirely.

## Who to contact

- **Hosting, DNS, SSL, server access** — CASA IT (Ryan). Everything CASA has confirmed is
  recorded in [`docs/hosting-questions.md`](docs/hosting-questions.md); add any new
  question at its bottom and send the file as-is.
- **Incident form, anything about `/report`** — the VP Internal named in
  `src/data/contact.json`.

## Domain

`www.wecompete.ca` is canonical. It is set **once**, in `astro.config.mjs → site`, and
every canonical tag, `hreflang`, and sitemap entry derives from it. Never hardcode a
hostname in a component.

`jmccjmsb.ca` is legacy: it 301s to wecompete.ca preserving the path, so old bookmarks
and the Wix-era URLs keep working.

**Who owns what:**

| Layer | Owner | What |
|---|---|---|
| DNS and SSL | CASA IT (Ryan) | Points both domains at this server (jmccjmsb.ca still points at Wix until the cutover in `docs/hosting-questions.md`); AutoSSL issues the certificates |
| Every redirect | us, in `public/.htaccess` | jmccjmsb.ca → wecompete.ca, apex → `www`, http → https, `/regionals` → `/competitions`, `/post/:slug` → `/blog/:slug`, and the rest |

Both domains live in our cPanel account, so our `.htaccess` handles the whole chain
for a visitor hitting `jmccjmsb.ca/regionals`. Keep cPanel's **Force HTTPS Redirect**
off: it would add a second hop in front of ours.

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
mkdir -p /home/jmccjmsb/form-state && chmod 700 /home/jmccjmsb/form-state
```

The home directory is the **cPanel account name** (`jmccjmsb`), not the project name.

It holds the rate-limit counters, the signing key, and `contact.log`. It **must** sit
outside the deploy target: deploys run `rsync --delete`, which would wipe it every time,
resetting rate limits and rotating the signing key out from under open forms.

The path is `STATE_DIR` in `public/api/config.php`. If the directory is missing and PHP
cannot create it, the endpoint returns 500 rather than quietly running without spam
protection — so a broken contact form is the visible symptom of a missing state dir.

All configuration — recipient, sender, limits, paths — is in `public/api/config.php`.
No secrets live there: the signing key is generated into the state directory on first use.

#### ⚠ Staging needs its own `config.local.php`

Without one, staging inherits the production defaults: `MAIL_TRANSPORT` is `'mail'`, so
**every test submission emails the real recipient**, and `STATE_DIR` is production's, so
staging traffic burns production rate-limit counters and writes real personal data into
production's `contact.log`.

Create this once in the staging document root, at `api/config.local.php`:

```php
<?php
// Compose messages to STATE_DIR/mail.log and send nothing.
define('MAIL_TRANSPORT', 'file');
// Separate state so staging never touches production's counters, key, or log.
define('STATE_DIR', '/home/jmccjmsb/staging-form-state');
```

```
mkdir -p /home/jmccjmsb/staging-form-state && chmod 700 /home/jmccjmsb/staging-form-state
```

It is loaded first by `contact.php`, and every value in `config.php` is guarded with
`defined() || define()` so anything set here wins. It is gitignored, excluded from the
rsync in `deploy.yml`, and denied by `.htaccess` — so it must be placed on the server by
hand and will survive deploys.

Do **not** commit a `config.local.php.example` to `public/`: everything under `public/`
ships to the document root, so the example would be publicly fetchable.

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
