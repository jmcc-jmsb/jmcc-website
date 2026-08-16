# Brand Asset Inventory

Assets are in `/src/assets/brand/`. Source files remain in `/brand-assets/` for reference.

## JMCC Shield

| File | Notes |
|---|---|
| `jmcc-shield-color.jpg` | Color version on white JPEG background — use on light (cream) backgrounds |
| `jmcc-shield-textured-gold.png` | Textured sand/gold decorative variant — used in Footer on ink bg |

### Favicon

`/public/favicon.png` (512×512) is derived from `jmcc-shield-color.png` — cropped to the
shield/wolf crest with the "John Molson Competition Committee" banner excluded, since the
wordmark is illegible at 16px. Regenerate with:

```js
sharp('src/assets/brand/jmcc-shield-color.png')
  .extract({ left: 24, top: 0, width: 464, height: 270 })   // shield only; banner starts at y=272
  .resize(512, 512, { fit: 'contain', background: { r: 0, g: 0, b: 0, alpha: 0 } })
  .png({ palette: true, compressionLevel: 9 })
  .toFile('public/favicon.png')
```

### ⚠ Transparent re-exports needed

The following variants are **missing** and must be re-exported from the original vector source before launch:

| Needed | Where used |
|---|---|
| `jmcc-shield-white.png` | Nav logo on `primary` background (maroon) |
| `jmcc-shield-black.png` | Monochrome / print contexts |
| `jmcc-shield-color-transparent.png` | Color shield with no white fill (replaces workaround in Nav) |

**Current workaround**: Nav uses `mix-blend-multiply` on a cream-circle container to knock out the white JPEG background. Replace with the transparent PNG when available and remove the workaround comment in `Nav.astro`.

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
layouts only (see `photo-placement.md`).

| File | Placement |
|---|---|
| `jmcc-2026-delegation-stage.jpg` | Home hero, photo panel (eager) — full delegation under the JMCC banner |
| `jmcc-2026-delegation-gala.jpg` | Home, full-width delegation band |
| `jdc-2026-spirit-outdoor.jpg` | Home, "Join the Wolfpack" recruitment band |
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

Gaps: no international, exec/team, or people-free photos; only JDC and FO of five regionals.
