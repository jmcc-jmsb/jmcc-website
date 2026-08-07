# JMCC — wecompete.ca

Website for the **John Molson Competition Committee**, JMSB's case competition program.

Bilingual (EN/FR), statically generated, deployed to CASA cPanel.

- **Editing content?** You almost certainly want [`MAINTENANCE.md`](MAINTENANCE.md), not this file.
- **Hosting/DNS questions?** [`docs/hosting-questions.md`](docs/hosting-questions.md).
- **Asset inventory?** [`ASSETS.md`](ASSETS.md).
- **What content is still missing?** [`CONTENT-NEEDED.md`](CONTENT-NEEDED.md).

---

## Stack

| | |
|---|---|
| Framework | [Astro](https://docs.astro.build) — static output, no server rendering |
| Styling | Tailwind CSS v4, via the Vite plugin (no `tailwind.config`; tokens live in `src/styles/global.css`) |
| Content | Astro content collections — blog posts are markdown in `src/content/blog/` |
| i18n | `/` is English, `/fr/` is French. FR pages import the EN page and detect language from the URL |
| Forms | One PHP 8.2 endpoint (`public/api/contact.php`). No framework, no Composer |
| Hosting | CASA cPanel, Apache. Redirects and headers in `public/.htaccess` |

The canonical domain is **`https://www.wecompete.ca`**, set once in `astro.config.mjs`.
`jmccjmsb.ca` is legacy and 301s here. Never hardcode a hostname anywhere else.

## Running locally

```sh
npm install
npm run dev          # http://localhost:4321
```

| Command | What it does |
|---|---|
| `npm run dev` | Dev server with hot reload |
| `npm run build` | Production build into `dist/` |
| `npm run preview` | Serve the built site (static only — no PHP, no `.htaccess`) |

### Testing the contact form locally

`npm run preview` serves static files only, so the PHP endpoint will not run. Use PHP's
built-in server instead — the test script does this for you:

```sh
powershell -NoProfile -File tests/test-contact.ps1
```

Requires PHP 8.2+ on PATH. It builds the site, starts a server, points the endpoint at a
throwaway state directory, forces the file mail transport (so nothing is actually emailed),
and asserts 33 behaviours: spam handling, validation, header injection, the composed
message, and that runtime state survives a deploy.

### Testing redirects locally

`.htaccess` needs **real Apache**. Neither Astro's preview nor PHP's built-in server reads
it, so both will report every redirect as failing. Start the local Apache first:

```sh
npm run preview:apache      # builds, then serves dist/ on http://localhost:8080
npm run test:redirects      # in a second terminal
```

One-time setup — both must end up on PATH (restart the shell afterwards):

```sh
winget install ApacheLounge.httpd
winget install PHP.PHP.8.2     # the thread-safe build, which ships php8apache2_4.dll
```

`tests/serve-apache.ps1` runs Apache in the foreground with `tests/apache-local.conf`
(mod_rewrite, mod_headers, mod_deflate, mod_filter, mod_expires, mod_php, `AllowOverride
All`). Nothing is installed as a service; logs and the writable form state land in the
gitignored `.apache-local/`. Ctrl+C stops it.

The same script runs unchanged against staging and production:

```sh
powershell -NoProfile -File tests/check-redirects.ps1 -BaseUrl https://staging.wecompete.ca
```

> **What this proves, and what it does not.** The local Apache verifies the rules are
> *correct*. It cannot verify they are *permitted*: it sets `AllowOverride All`, whereas
> CASA's cPanel may restrict overrides, and may run PHP through CloudLinux's selector
> rather than mod_php. If overrides are disabled on the real host, none of `.htaccess`
> applies and the rules must move into the vhost config. That is question 1 in
> [`docs/hosting-questions.md`](docs/hosting-questions.md).

The canonical-host assertions self-skip when the base URL is not a real `wecompete.ca`
domain. Locally the config presents the request as already being on the canonical host
over HTTPS, so section 1 of `.htaccess` stays inert and everything below it is what gets
exercised — without that, every request would 301 straight out to the live site.

## Project structure

```
src/
  assets/        images processed by Astro (optimised, hashed at build)
    blog/        one folder per post
    brand/       logos, wolf graphics, textures
    photos/      delegate photography — see ASSETS.md
  components/    shared UI
  content/blog/  the 11 migrated Case & Point posts
  data/          ← content lives here: JSON edited by non-developers
  i18n/          translation strings and helpers
  layouts/       BaseLayout — head, canonical, hreflang, OG, JSON-LD
  pages/         routes; pages/fr/ mirrors them for French
public/          copied verbatim to the site root
  api/           the PHP contact endpoint
  .htaccess      redirects, security headers, caching
tests/           runnable checks (PowerShell)
docs/            notes for humans, not the build
```

Two large directories are **gitignored** and exist only on a local machine:

- `photo-bank/` — ~220 raw photo originals (2 GB)
- `wix-archive/` — the raw HTML and full-resolution images from the old Wix site (193 MB)

`wix-archive/` is the only remaining copy of the old site once the Wix subscription lapses.
**Back it up.**

## Deploying

GitHub Actions (`.github/workflows/deploy.yml`) builds on every push and rsyncs `dist/` to
cPanel. The deploy steps **skip cleanly** until the host variables are set, so the workflow
is safe to merge before server access exists.

Repo variables to fill in: `CPANEL_SSH_HOST`, `CPANEL_SSH_USER`, `CPANEL_DEPLOY_PATH`,
`CPANEL_SSH_PORT`, `CPANEL_KNOWN_HOSTS`, `SITE_URL`. Secret: `CPANEL_SSH_KEY`.

Run it manually with **dry run** ticked first — it previews exactly what rsync would change
without writing anything.

## Conventions

- Every new file starts with a two-line `ABOUTME:` comment block.
- Colour tokens and the dark-background-only rule are in [`AGENTS.md`](AGENTS.md).
  `CLAUDE.md` is a symlink to it.
- Every user-facing string carries both `en` and `fr`. Fill both.
- Never commit directly to `master` — branch, open a PR.
