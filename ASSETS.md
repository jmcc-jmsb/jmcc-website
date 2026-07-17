# Brand Asset Inventory

Assets are in `/src/assets/brand/`. Source files remain in `/brand-assets/` for reference.

## JMCC Shield

| File | Notes |
|---|---|
| `jmcc-shield-color.jpg` | Color version on white JPEG background — use on light (cream) backgrounds |
| `jmcc-shield-textured-gold.png` | Textured sand/gold decorative variant — used in Footer on ink bg |

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

Live delegate / event photos should go in `/src/assets/photos/`. The directory is created and `.gitkeep`-tracked.
