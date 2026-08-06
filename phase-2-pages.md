# Phase 2 — Pages & Content Rework

Build all site pages, EN + FR, replacing the old Wix site's structure and
content. Read `CLAUDE.md` first — brand tokens, i18n conventions, and file
layout rules all apply. This document is the source of truth for structure
and content changes.

Some content (photos, rosters, sponsor lists) is not yet available. Follow the
**Placeholder protocol** below rather than inventing content or leaving blanks.

---

## 0. Global rules — apply to every page

### 0.1 Color distribution (fixes "too much red")

The old site drowned in maroon. Target a roughly 60 / 25 / 12 / 3 split:

| Weight | Role |
|---|---|
| ~60% | `cream` (#f7f3ec) — the default page background |
| ~25% | Photography and `ink` (#000000) blocks |
| ~12% | `primary` (#680009) — anchor sections only |
| ~3% | `gold` (#fabb20) — CTAs and highlights only |

Rules:
- `cream` is the default page background. Maroon is a **punctuation color**, not a base.
- Max **two** full-bleed `primary` sections per page, and never two in a row.
- Alternate section backgrounds in a rhythm: cream → photo/ink → cream → primary → cream.
- Nav and footer stay `primary` (brand anchors) — they don't count toward the page budget.
- `sand`/`gold` remain dark-background-only tokens; use `muted` (#5e5c5a) for secondary text on cream.

### 0.2 Photography rules

- **Never overlay text on photographs containing people.** If a hero or section
  needs a headline over an image, use one of: (a) a split layout with text in a
  solid cream/ink/maroon panel beside the photo, (b) an abstract/architectural/
  detail photo with no faces, or (c) a solid or textured background.
- Every `<img>` must resolve. No empty frames, no broken sources, no
  layout-shift placeholders in production. Build a `SafeImage` wrapper that
  falls back to a branded placeholder (wolf silhouette on cream) so a missing
  file never renders as a blank box.
- All images through Astro `<Image>` — responsive srcsets, explicit width/height
  to prevent CLS, lazy loading below the fold.
- Photos crop to subject, not to frame center. Where a crop focal point matters
  (headshots especially), support a `focal` prop.

### 0.3 Motion

Add flowing transitions — this is an explicit goal, but keep it disciplined:

- Astro View Transitions for page-to-page navigation (fade/slide, ~200ms).
- Scroll-reveal on section entry: subtle fade + 12–16px rise, staggered for
  grids, `IntersectionObserver`, triggers once. No parallax, no bounce.
- Stat counters animate on first view only.
- Hover: 150ms ease on cards (slight lift + border color shift), buttons, nav links.
- **All motion must respect `prefers-reduced-motion: reduce`** — wrap the
  reveal utility so reduced-motion users get instant, fully-visible content.
- Nothing animates that delays content readability. No loading spinners on a static site.

### 0.4 Content architecture

Anything that changes year to year lives in `/src/data/` as JSON, never
hardcoded in a page:

```
/src/data/
  stats.json          Home page counters
  team.json           Executive roster
  sponsors.json       Sponsors by tier
  competitions.json   Internationals + regionals
  contact.json        Address, email, office room, socials
  site.json           Sign-up form URL, donation URL, misc links
```

Every entry that has user-facing copy carries `en` and `fr` fields.

### 0.5 Placeholder protocol

Where content is missing:
1. Put a clearly-marked placeholder value in the relevant JSON file with a
   `"TODO"` marker and a comment field describing what's needed.
2. Render it as a **visually neutral, non-broken** state (e.g. initials avatar
   for a missing headshot, "Coming soon" chip) — never a blank box or lorem ipsum.
3. Log it in a root-level `CONTENT-NEEDED.md` checklist with the file path and
   what's required, so it can be filled in later without hunting.

---

## 1. Route map

New structure (EN shown; every route has an `/fr/...` counterpart):

```
/                     Home
/who-we-are           Who We Are
/team                 Our Team
/sponsors             Sponsors
/get-involved         Get Involved (incl. sign-up)
/competitions         Competitions — internationals + regionals, ONE page
/donate               Donate
/portal               Delegate Portal — work-in-progress screen
/contact              Contact Us
/report               Incident Form
/blog                 Blog — BUILT BUT UNLISTED (see §11)
/blog/[slug]          Blog posts — BUILT BUT UNLISTED
```

### Navigation

Simplify from the old six-group menu:

```
Who We Are  ▾    Competitions    Get Involved    Portal    Contact  ▾
  Our Team                                                    Contact Us
  Sponsors                                                    Report an Incident
                                          [ Donate ]  [EN|FR]
```

- Donate is a `gold` CTA button in the nav, not a buried sub-item.
- Blog does **not** appear in the nav or footer.
- Language toggle preserves the current page.

### Redirects (`.htaccess`, 301)

```
/regionals                        → /competitions
/nationals-internationals         → /competitions
/copy-of-nationals-internationals → /sponsors
/about-3                          → /donate
/our-team                         → /team
/incident-form                    → /report
/jdc-delegates                    → /portal
/jdcc-delegates                   → /portal
/hm-delegates                     → /portal
/copy-of-hm-delegates             → /portal
/hr-sympo-delegates               → /portal
/post/:slug                       → /blog/:slug
```

---

## 2. Home (`/`)

Rebuild section by section. Reference structure:

**2.1 Hero** — "The John Molson Competition Committee" / "We Compete." /
"The World's Largest Case Competition Program". Split layout: Unbounded Bold
headline in a solid panel, delegate photography in the adjacent panel — text
must not sit on top of the people photo (§0.2). Primary CTA to `/get-involved`,
secondary to `/who-we-are`.

**2.2 Stats band** — corrected figures, from `stats.json`:

| Value | Label EN | Label FR |
|---|---|---|
| 30+ | Case Competitions | Compétitions de cas |
| 14+ | Countries | Pays |
| 250+ | Delegates | Délégués |
| 90+ | External Coaches | Coachs externes |

Store value and suffix separately (`{ "value": 15, "suffix": "+" }`) so the
count-up animates the number and the `+` stays put. These change yearly —
one file edit must update the page.

**2.3 What Is a Case Competition?** — keep existing definition copy, restyle
on cream with a `sand` scratch divider.

**2.4 Disciplines** — the 20+ disciplines list. Restyle as a tag cloud or
chip grid rather than run-on text. From `competitions.json`.

**2.5 Where We Compete** — condensed preview: brief intro, logo strip, single
CTA to `/competitions`. Do not duplicate the full competition content here.

**2.6 Social links** — larger and better placed. Implement as a dedicated
band above the footer: `primary` background, 40–44px touch-target icons,
labeled with handle names, hover lift.
**Fix the Instagram URL** — the old site points to `instagram.com/wix`
(an unchanged Wix template default). The correct URL is
`https://www.instagram.com/jmcconline/` — store it in `contact.json`.
Strip any `?hl=` locale parameters from social URLs.

**2.7 REMOVED: article section.** The three-article grid and "Read all
articles" link come off the homepage entirely — no weekly articles this year.
Replace that slot with a **"Join the Wolfpack" recruitment band**: short
value proposition, gold CTA to the sign-up form, wolf graphic accent.
(If a different replacement is preferred, this is the one block to swap.)

**2.8 Footer info** — see §12.

---

## 3. Who We Are (`/who-we-are`)

Content is broadly fine; the problem is formatting. Rework into clear,
scannable blocks rather than dense paragraphs:

- Mission/intro statement — large-type lead paragraph, generous measure (65–75ch).
- Structured sub-sections with Unbounded headings and clear vertical rhythm.
- Pull-quote or stat callout to break up long text.
- Supporting imagery in a split layout, not behind text.
- Ends with links to `/team` and `/get-involved`.

---

## 4. Our Team (`/team`)

Driven entirely by `team.json`. Chris will supply the executive list, headshots,
and emails.

Schema:
```json
{
  "name": "", "role": { "en": "", "fr": "" },
  "email": "", "photo": "", "focal": "center",
  "linkedin": ""
}
```

Requirements:
- **Headshot sizing**: constrained max width (~240–280px on desktop), consistent
  square or 4:5 aspect ratio, `object-fit: cover` with a per-person focal point
  so faces are never cropped off. Uniform sizing across the whole grid — no
  oversized images.
- Grid: 4-up desktop → 2-up tablet → 1–2-up mobile, even gutters.
- Each card: photo, name (Unbounded), role (`muted`), mailto link, optional LinkedIn.
- Group by team/portfolio if the supplied list has that structure.
- Missing headshot → branded initials avatar, same dimensions (never a blank frame).

---

## 5. Sponsors (`/sponsors`)

**Remove the clicking carousel entirely.** Replace with a static tiered grid:

- Sponsors grouped by tier (e.g. Platinum / Gold / Partner — final tiers TBD from
  the supplied list), tier headings in Unbounded.
- Higher tiers get larger logo cells; all logos in uniform white/cream cards with
  consistent padding so mismatched logo shapes look intentional.
- Logos link to sponsor sites, `target="_blank" rel="noopener"`.
- Grayscale-to-color on hover is acceptable; nothing that moves on its own.
- **Rename all sponsor image files** — the old site ships assets literally named
  `Screenshot 2025-05-18 at 7.27.48 PM.png`. Use `sponsor-<name>.png`.
- Closing band: "Interested in partnering with us?" → `/contact`.

---

## 6. Get Involved (`/get-involved`)

- Updated photography, split/panel layouts (§0.2), stronger visual hierarchy.
- **Rename "Organizing Committee" → "Executive Committee"** everywhere it appears,
  EN and FR (« Comité exécutif »).
- **Add a sign-up section**: prominent, above the fold or immediately below the
  hero, `gold` CTA linking to the active sign-up form
  (`site.json → signupUrl`, currently `TODO`). Include deadline/timeline if supplied.
- Lay out the paths to involvement (delegate, exec, coach/volunteer) as clear
  parallel cards rather than stacked prose.
- Recruitment-cycle dates should come from data, not hardcoded.

---

## 7. Competitions (`/competitions`)

Merge `/regionals` and `/nationals-internationals` into **one page**. Internationals
lead — they're the primary selling point.

Order:

1. **Hero + intro** — "Where We Compete", regional → national → international framing.
2. **Nationals & Internationals** (first, most prominent). Existing intro copy about
   competing in more than a dozen national and international competitions, blending
   strategy with HR, marketing, finance, operations. Present the competition list as
   a rich grid or map-style layout — this section should feel like the headline.
3. **Regionals**, in two labeled groups per `competitions.json`:
   - **Group A — JDC / JDCC**: Jeux du Commerce, JDC Central
   - **Group B — SMNG / FO / HM**: Management Symposium, Financial Open, Happening Marketing

**Naming change**: what the old site called "HR Symposium" is now the
**Management Symposium** (SMNG) — « Symposium en Management » in French.
Update every occurrence site-wide: competition cards, `competitions.json`,
alt text, logo filenames, and any nav or body copy. Do not ship "HR Symposium"
anywhere.
   Each group gets a heading and short description; each competition a card with
   logo, name, one-line description, and external link.

**Competition logos must be updated to the 2026–2027 editions** — the current
files are stale and some are screenshot exports. Reference in `competitions.json`
by path; mark any not yet supplied as `TODO` in `CONTENT-NEEDED.md`.

Known external links to preserve: `jeuxducommerce.ca`, `refaec.ca/symposium-grh`,
`refaec.ca/omnium-financier`, `happeningmarketing.ca`, `cabsonline.ca/jdcc`.

---

## 8. Donate (`/donate`)

Full rework. **Delete all screenshots** — the current page shows cropped
screenshots of the Concordia donation portal, which looks unprofessional.

New structure:
- Hero: "Donate to JMCC" + existing impact copy (contribution shapes the next
  generation of business leaders; funds travel, training, development).
- **Single prominent CTA** to `https://engage.concordia.ca/donate/jmsb-undergraduate-case-competitions`
  (from `site.json`), gold button, opens in a new tab.
- Replace the three screenshot steps with a clean **three-step process strip**:
  numbered steps, icon or numeral in `sand`/`gold`, one line of text each
  (open the portal → select JMCC → choose your amount and submit). No images of UI.
- Optional impact band: what donations fund, expressed as short outcome statements.
- Secondary CTA to `/contact` for corporate/major giving inquiries.

---

## 9. Delegate Portal (`/portal`)

The portal is **not functional** and is a separate future project. Build a
polished work-in-progress screen, not a dead link:

- Full-height branded section: wolf graphic, Unbounded headline
  ("Delegate Portal — Coming Soon" / « Portail des délégués — Bientôt disponible »),
  short line explaining it will house delegate resources.
- Designed to fill the space credibly — this is the placeholder a marketing
  mock-up may later replace, so keep the layout modular: a single
  `PortalPlaceholder.astro` component with the visual swappable in one place.
- Optional email/contact link for delegates who need resources in the meantime.
- Reserve `/portal/*` routes; all old `*-delegates` URLs redirect here (§1).
- `noindex` on this page.

---

## 10. Contact Us (`/contact`)

- Rework layout: two-column — form on one side, contact details and map/office
  info on the other. Cream background, maroon accents only.
- Form fields: name, email, subject, message; posts to the PHP handler (Phase 4).
- Contact details pull from `contact.json` (§12).
- Include a clear pointer to `/report` for incidents, so the two are not confused.

---

## 11. Blog (`/blog`) — hidden but preserved

Requirements: not publicly visible, but all articles retained for possible revival,
and the section may later host other marketing projects.

Implementation:
- Keep the Astro content collection and all migrated markdown posts (Phase 3).
- **Build the pages** at `/blog` and `/blog/[slug]` so they remain reachable by
  direct URL and revival is a config flip — but:
  - No links from nav, footer, or any page.
  - `<meta name="robots" content="noindex, nofollow">` on all blog routes.
  - Excluded from `sitemap.xml`.
  - Excluded from any RSS output.
- Gate it behind a single flag in `site.json`: `"blogPublic": false`. When flipped
  to `true`, nav links, sitemap inclusion, and indexing all switch on. Document
  this in `MAINTENANCE.md`.
- Preserve the `delegate-story` category structure and old `/post/:slug` redirects.

---

## 12. Footer & contact info

Applies site-wide:

- **Remove the phone number** (514-576-6443) from footer and all pages.
- Address becomes:
  ```
  1450 Guy Street, Room [TODO]
  Montreal, QC H3H 0A1
  ```
  Room number is a `CONTENT-NEEDED` item; render the address gracefully without it
  until supplied (no empty "Room" label).
- Keep `Info@wecompete.ca`.
- Keep "Join The Wolfpack" tagline.
- Social icons: LinkedIn, Facebook, Instagram — **corrected Instagram URL**,
  larger targets, consistent with the homepage social band.
- CASA attribution logo in the footer.
- No blog link.

---

## 13. Incident Form (`/report`)

- Rebuild with brand styling; must remain usable with **all identity fields blank**
  (anonymous submission supported and clearly stated).
- Routes to the **new VP Internal** — name and email are `CONTENT-NEEDED`; put in
  `contact.json` as `TODO` and do not hardcode.
- Clear, calm layout: short intro on what the form is for and who receives it,
  fields, submit. No maroon-heavy or alarming styling.
- Confirmation state after submit (no dead-end redirect).
- Handler built in Phase 4; wire the front end now with the form action pointed at
  the planned endpoint.

---

## 14. Definition of done

Before this phase is complete:

- [ ] Every EN route has a working FR counterpart; language toggle preserves page.
- [ ] No hardcoded rosters, stats, sponsors, or competition lists in page files.
- [ ] `npm run build` passes with zero errors and zero broken image references.
- [ ] No page exceeds the §0.1 color budget (two `primary` sections max, non-adjacent).
- [ ] No text overlays any photograph containing people.
- [ ] All motion disabled under `prefers-reduced-motion`.
- [ ] Lighthouse: performance ≥ 90, accessibility ≥ 95 on Home, Team, Competitions.
- [ ] All `.htaccess` redirects (§1) present and tested.
- [ ] Blog unreachable from navigation, absent from sitemap, `noindex` confirmed.
- [ ] `CONTENT-NEEDED.md` lists every outstanding asset and copy item with file paths.
- [ ] French copy reviewed — flag machine-drafted FR text explicitly for human review
      rather than presenting it as final.

---

## 15. Outstanding content (seed `CONTENT-NEEDED.md` with this)

| Item | Destination | Status |
|---|---|---|
| Updated photo bank (delegates, events, teams) | `/src/assets/photos/` | Pending |
| Executive roster: names, roles, emails, headshots | `team.json` | Pending |
| Sponsor list + tiers + logo files | `sponsors.json` | Pending |
| 2026–2027 regional competition logos | `/src/assets/competitions/` | Pending |
| Nationals/internationals competition list | `competitions.json` | Pending |
| Active sign-up form URL | `site.json` | Pending |
| ~~Instagram URL~~ | `contact.json` | ✅ Resolved — `instagram.com/jmcconline` |
| JMCC office room number | `contact.json` | Pending |
| New VP Internal name + email | `contact.json` | Pending |
| Portal marketing mock-up | `PortalPlaceholder.astro` | Optional, later |
| French translations of all page copy | `/src/i18n/`, content files | Pending review |
