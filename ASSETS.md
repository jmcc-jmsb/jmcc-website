# Brand Asset Inventory

Assets are in `/src/assets/brand/`. Source files remain in `/brand-assets/` for reference.

## JMCC Shield

| File | Notes |
|---|---|
| `jmcc-shield-color.png` | Color shield, transparent background (1627×1417) — works on any background |
| `jmcc-shield-textured-gold.png` | Textured sand/gold decorative variant — used in Footer on ink bg |

Master: `/brand-assets/JMCC Shield Color 2000.png` (2000×2000, transparent, square-padded).
The site copy is that file trimmed of its padding.

**There is no vector source in the repo.** A file named `JMSB Logo SVG.svg` was supplied in
August 2026, but it contains zero paths — it is this same 2000×2000 raster base64-embedded in
an SVG wrapper, so it neither scales past 2000px nor recolors. The white and black variants
below still need a real vector export from whoever built the mark.

### Favicon

`/public/favicon.png` (512×512) is derived from `jmcc-shield-color.png` — cropped to the
shield/wolf crest with the "John Molson Competition Committee" banner excluded, since the
wordmark is illegible at 16px. Regenerate with:

```js
sharp('src/assets/brand/jmcc-shield-color.png')
  .extract({ left: 76, top: 0, width: 1474, height: 858 })  // shield only; banner starts at y=860
  .resize(512, 512, { fit: 'contain', background: { r: 0, g: 0, b: 0, alpha: 0 } })
  .png({ palette: true, compressionLevel: 9 })
  .toFile('public/favicon.png')
```

### Schema.org logo

`/public/logo.png` (600×523) is the whole mark, banner included, and is what the homepage
`Organization` JSON-LD in `BaseLayout.astro` points at. Keep it distinct from
`og-default.png` — that one is a 1200×630 social card with headline copy, wrong for a
`logo` field. Regenerate with:

```js
sharp('src/assets/brand/jmcc-shield-color.png')
  .resize(600)
  .png({ palette: true, compressionLevel: 9 })
  .toFile('public/logo.png')
```

### ⚠ Transparent re-exports needed

The following variants are **missing** and must be re-exported from the original vector source before launch:

| Needed | Where used |
|---|---|
| `jmcc-shield-white.png` | Nav logo on `primary` background (maroon) |
| `jmcc-shield-black.png` | Monochrome / print contexts |

## Wolf Graphics

| File | Use |
|---|---|
| `wolf-portrait.jpg` | Editorial B&W wolf portrait — hero or section accent |
| `wolf-walking.jpg` | Editorial B&W wolf stalking — editorial sections |
| `jmsb-wordmark-wolf.png` | JMSB EST.1973 arch wordmark with running wolf silhouette |

## CASA Logos

| File | Use |
|---|---|
| `casa-logo-burgundy.png` | Footer on light backgrounds |
| `casa-logo-white.png` | Footer on dark (ink) backgrounds ← currently used |
| `casa-logo-black.png` | Monochrome contexts |
| `casa-logo-mixed.png` | Mixed (burgundy dots + black text) variant |
| `casa-x-logo-white.png` | CASA × JMSB co-brand, white |
| `casa-x-logo-black.png` | CASA × JMSB co-brand, black |

## Decorative / Textures

| File | Use |
|---|---|
| `jmcc-scratch-texture.png` | Section dividers via `SectionDivider.astro` |

## Mockups (do not use on website)

| File | Notes |
|---|---|
| `jmcc-flag-mockup.png` | Flag product mockup |
| `jmcc-scarf-mockup.png` | Scarf product mockup |
| `jmcc-lanyard-mockup.png` | Lanyard product mockup |

## Photos

Live delegate / event photos live in `/src/assets/photos/`. Imports, bilingual alt text, and
focal points are centralized in `/src/data/photos.ts` — import from there, not from the asset
path directly. Focal points are tuned so faces stay in frame when a short band crops the image;
re-check them if you change a band's height. Masters are resized to a 2400px long edge on import; Astro emits the responsive set.

**Every photo in this bank contains people, so no headline may be overlaid on one** — split
layouts only. Placement per photo is in the table below.

| File | Placement |
|---|---|
| `jmcc-2026-delegation-stage.jpg` | Home hero, photo panel (eager) — full delegation under the JMCC banner |
| `jmcc-2026-delegation-gala.jpg` | Home, full-width delegation band |
| `jdc-2026-parade-crowd.jpg` | Home, "Join the Wolfpack" recruitment band |
| `jmcc-2026-judges-handshake.jpg` | Who We Are, split beside "What We Do" |
| `jdc-2026-delegation-arch.jpg` | Competitions, Regionals section header |
| `fo-2026-podium-trophy.jpg` | Competitions, SMNG / FO / HM group header (uncropped, 3:4) |
| `jdc-2026-celebration-trio.jpg` | Get Involved, closing band |

Home and Competitions deliberately draw on different events and framings. It is one delegation,
so individual faces do recur across group shots — the rule is that no *small* group is the subject
of a photo on two different pages.

## Raw photo bank

The ~220 full-resolution originals live in `/photo-bank/` at the repo root and are **gitignored**
(about 2 GB). Site copies are resized to a 2400px long edge and renamed on import — never reference
`photo-bank/` from application code, and never commit it.

### ⚠ Before launch

Confirm publication rights and attribution for the four photographers credited in the filenames:
"Vince Noël Photographe", "Guillaume", "Karl-Erik", and "Jean-Daniel". If credit is required, add a
`credit` field in `photos.ts` and render it.

Gaps: no international or people-free photos; only JDC and FO of five regionals.

## Team headshots

Exec and faculty-advisor headshots live in `/src/assets/photos/team/<first-last>.jpg`, one per
member, and are wired up by the `photo` field in `/src/data/team.json` — not by `photos.ts`.
`/team` globs the directory, so a file with no matching `team.json` entry simply goes unused.

Studio set shot Aug 2026: square 2000px PNG masters on the maroon JMCC backdrop, converted on
import to 1000px JPEG (quality 82) — the cards top out at 280px displayed, so the 2x responsive
variant is 560px. `TeamMember` crops square to 4:5 with `object-fit: cover`; the framing has
enough headroom that every member uses `focal: "center"`.
