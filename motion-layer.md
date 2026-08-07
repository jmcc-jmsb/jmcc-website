# Motion Layer — Signature Animation

Adds a distinctive motion identity to the site. Slots in **after Phase 2**, runs
**parallel to `pre-server-work.md`** — no server dependency.

Baseline motion (view transitions, scroll reveal, hover states) is already
specified in `phase-2-pages.md` §0.3. This document covers the layer above that:
the wolf/claw motif that makes the site feel like JMCC rather than a competent
generic template.

---

## Principle: restraint is the whole design

The failure mode here is obvious and common — claw marks on every section, wolves
running through every transition, and a site that feels like a 2011 Flash intro.

**Budget: one signature moment per page. Two on the homepage, maximum.**

Everything else stays in the quiet baseline layer. The claw motif earns its
impact from scarcity. If it appears five times on a page, it reads as decoration;
if it appears once at the right moment, it reads as brand.

Three tests before adding any effect:
1. Would a delegate notice it once and remember it, or notice it every time and
   find it tiring?
2. Does it delay reading anything? If yes, cut it.
3. Does it still work at 3× speed, and when disabled entirely?

---

## The signature: claw tear

A section boundary where the page appears to be torn open by claw marks,
revealing the section beneath.

### Where it belongs
| Location | Treatment |
|---|---|
| Home — hero into stats band | **Primary moment.** Full claw tear on scroll. |
| Competitions — internationals into regionals | Secondary tear, lighter weight. |
| Get Involved — into the sign-up band | Tear reveals the gold CTA. High-intent moment. |
| Everywhere else | Static scratch divider, no animation. |

### How it works
Not a video, not a GIF, not a sprite sheet. **SVG `clipPath` driven by scroll
position.**

1. The incoming section sits in the DOM normally, clipped by an SVG path shaped
   like three claw gashes.
2. As the boundary enters the viewport, the clip path scales from the gash
   shapes outward until the section is fully revealed.
3. Progress is driven by `IntersectionObserver` plus a small scroll-progress
   calculation — **never a raw `scroll` event listener**.

```
Scroll progress 0.0 ──────────────────────────► 1.0
Clip:  three thin gashes  →  gashes widen  →  full section visible
```

- Animate `transform: scale()` on the clip path group. Do **not** animate `d`,
  `mask-size`, or `mask-position` — those force repaint and will tank the
  performance budget.
- The gash edges carry a 1–2px `sand` (#d8af74) stroke so the tear reads as an
  edge rather than a soft wipe.
- Reveal completes by the time the boundary reaches the viewport centre. Content
  must never be unreadable because someone stopped scrolling mid-tear.

### Prefers-reduced-motion
Section renders fully visible, unclipped, with the **static** scratch graphic as
a divider. Not a degraded version — a deliberate one.

---

## Supporting motion

Small, quiet, used more freely than the tear.

### Scratch stroke-draw
The scratch divider draws itself on entry — `stroke-dasharray` /
`stroke-dashoffset` from full offset to zero, ~600ms, `ease-out`, staggered
across the three gashes by ~80ms. Once per page load. Cheap, and it makes the
existing divider feel intentional.

### Wolf scroll companion
The running wolf silhouette, small and low-opacity, sitting in the page margin
and translating on scroll progress. Runs across the viewport once between two
anchor points, then stops.

**Risky — build it last and cut it without hesitation** if it distracts. On
mobile there is no margin to spare, so it should not render below the tablet
breakpoint at all.

### Card hover — claw flick
On competition and blog card hover: three short gash strokes flick across the
card corner, 180ms, `sand` at low opacity. Subtle enough to feel like a texture,
not an animation. Touch devices skip it entirely.

### Headline entry
Unbounded headlines rise 12–16px with a fade on entry. Already in the baseline —
listed here so it is not duplicated with something heavier.

### Page transitions
Astro View Transitions, ~200ms crossfade. **Do not use the claw tear between
pages.** It is a scroll gesture; on navigation it would fire before the person
has any context, and it would fire on every single click.

---

## Motion tokens — define these before building anything

Cohesion comes from shared timing, not from shared imagery. Two effects using
the same easing feel like one system; twelve effects with ad-hoc durations feel
like twelve plugins. Define these in Tailwind theme config and **never write a
raw duration or cubic-bezier in a component.**

```css
@theme {
  /* Durations */
  --duration-instant: 120ms;  /* button press, focus ring */
  --duration-quick:   180ms;  /* hover, small state change */
  --duration-base:    280ms;  /* the default — most transitions */
  --duration-slow:    480ms;  /* section reveals, larger movement */
  --duration-tear:    700ms;  /* claw tear only */

  /* Easings */
  --ease-out:  cubic-bezier(0.16, 1, 0.3, 1);    /* entrances — default */
  --ease-in:   cubic-bezier(0.7, 0, 0.84, 0);    /* exits */
  --ease-soft: cubic-bezier(0.4, 0, 0.2, 1);     /* hovers, small states */

  /* Stagger */
  --stagger: 60ms;   /* between siblings in a grid or list */
}
```

Rules that hold everywhere:
- **Entrances use `--ease-out`.** Things arrive decisively and settle. Never
  `ease-in-out` on an entrance — it reads as sluggish.
- **One direction per page.** Content rises on entry. It does not rise in one
  section and slide in from the left in the next.
- **Stagger caps at 6 items.** A 25-card team grid staggering at 60ms each takes
  1.5 seconds; cap the cascade and let the remainder appear together.
- Nothing exceeds `--duration-slow` except the tear.

---

## Connective motion

The quiet layer. Used freely, unlike the claw. This is what makes the site feel
alive between signature moments.

### Section entry
Content rises 16px with a fade as it enters, using `--duration-slow` and
`--ease-out`. Fires once. Grids stagger children by `--stagger`, capped at 6.

Applies to: section headings, body blocks, card grids, stat bands.

### Sticky nav condense
The nav shrinks on scroll past ~120px — reduced height, smaller logo, a subtle
shadow or `border` bottom appearing. `--duration-base`. This is one of the
highest-value effects on the list: it signals the page is responsive to you and
costs almost nothing.

Never hide the nav on scroll-down. Hiding navigation to reclaim 60px is a
constant small frustration.

### Background rhythm transition
The page alternates `cream` → photo/ink → `cream` → `primary`. Rather than hard
edges, let the boundary crossfade slightly as it enters the viewport
(`--duration-slow`). Makes the color rhythm feel like one continuous page
instead of stacked blocks.

Cheap to do — animate `opacity` on a boundary overlay, not `background-color`.

### Image reveal
Images scale from 1.04 → 1.0 with a fade on entry, `--duration-slow`. Subtle
enough to read as settling rather than zooming.

**This is not parallax.** It completes on entry and stops. Nothing continues to
move as you keep scrolling.

### Stat odometer
Counters roll to their value on first view, `--duration-slow`, easing out so the
last digits settle rather than snapping. Already specified in Phase 2 — listed
here so the timing matches everything else.

### Link underline sweep
Nav and inline links: underline draws from left on hover, `--duration-quick`,
`--ease-soft`. Uses `transform: scaleX()` on a pseudo-element, not
`border-bottom` width. Small, but it's the effect people feel most often.

### Button feedback
`--duration-instant` scale to 0.98 on press, back on release. Gold CTA buttons
also lift 1–2px on hover. Immediate physical feedback matters more than
elaborate hover states.

### Competition group filter
If the Competitions page gets term or group filtering, transition the grid with
a fade-and-reposition (`--duration-base`) rather than an instant swap. Items
leaving fade out, remaining items move to new positions, entering items fade in.

### Language toggle
Crossfade the content on EN/FR switch, `--duration-quick`. A hard swap between
languages is jarring; a brief fade makes it feel like a deliberate change of
state. Do not animate layout — only opacity, since text length differs between
languages and animating reflow looks broken.

### Form states
Focus ring appears at `--duration-instant`. Validation messages fade and expand
at `--duration-quick`. Submit button transitions to a pending state without
changing width — a button that resizes mid-submit shifts everything around it.

### Smooth anchor scroll
`scroll-behavior: smooth` on in-page anchors, disabled under reduced-motion
(covered by the global guard).

### Accordion / disclosure
If Who We Are or a FAQ uses disclosure panels, animate height with
`--duration-base` and `--ease-soft`. Use `grid-template-rows: 0fr → 1fr` rather
than animating `height: auto`, which does not transition.

---

## What connective motion must never do

- **Auto-play.** Nothing moves without the person scrolling, hovering, or
  clicking. No marquees, no auto-rotating anything, no looping ambient drift.
  (This is also why the old sponsor carousel is being removed.)
- **Re-trigger.** Reveals fire once. Scrolling back up does not replay them.
- **Delay reading.** If someone scrolls fast, content is already there. Reveals
  are a nicety for normal scrolling, not a gate.
- **Move layout on hover.** Cards may lift and shift color; they may not resize
  and push siblings around.
- **Stack.** Two effects should not run on the same element at the same time.
  Pick one.

---



| Asset | Status | Notes |
|---|---|---|
| Claw scratch as **SVG paths** | ⛔ **Blocking** | Current asset is a PNG. Animation needs real vector paths — three separate paths, one per gash, so they can be staggered and clipped independently. |
| Running wolf as SVG | ⚠️ Check | PNG will not scale cleanly at low opacity in a margin. |
| Static scratch PNG | ✅ Have | Reduced-motion fallback and non-animated dividers. |

**The SVG claw is the one real blocker.** Options, in order of preference:
1. Export from the original Canva/Illustrator source as SVG — cleanest.
2. Trace the PNG in Illustrator or Inkscape and hand-clean the paths.
3. Draw three gashes from scratch — honestly viable, since the shape is simple
   and a hand-drawn path may animate better than a traced one.

Target: **under 4 KB inlined**, three paths, no embedded raster, no filters.

---

## Assets required

| Asset | Status | Notes |
|---|---|---|
| Claw scratch as **SVG paths** | ⛔ **Blocks the signature only** | Current asset is a PNG. Animation needs real vector paths — three separate paths, one per gash, so they can be staggered and clipped independently. Connective motion does not depend on this. |
| Running wolf as SVG | ⚠️ Check | PNG will not scale cleanly at low opacity in a margin. |
| Static scratch PNG | ✅ Have | Reduced-motion fallback and non-animated dividers. |

Options for the SVG claw, in order of preference:
1. Export from the original Canva/Illustrator source as SVG — cleanest.
2. Trace the PNG in Illustrator or Inkscape and hand-clean the paths.
3. Draw three gashes from scratch — honestly viable, since the shape is simple
   and a hand-drawn path may animate better than a traced one.

Target: **under 4 KB inlined**, three paths, no embedded raster, no filters.

---

## Technical constraints

### Performance
- **Only animate `transform` and `opacity`.** Nothing else is compositor-safe.
- **No animation library.** No GSAP (~70 KB), no Framer Motion. Use the Web
  Animations API and CSS. If something genuinely needs orchestration, Motion One
  is ~5 KB and the ceiling.
- `IntersectionObserver` for triggers. Never a raw `scroll` listener; if scroll
  progress is genuinely needed, throttle via `requestAnimationFrame`.
- `will-change` applied only during animation, removed after — leaving it on
  permanently costs memory on every element that has it.
- Reveal animations fire **once**. Nothing re-triggers on scroll-back.
- Total added JS for the entire motion layer: **under 8 KB gzipped.**
- Lighthouse performance must stay ≥ 90. Measure before and after; if the tear
  costs more than 3 points, simplify it.

### Accessibility — non-negotiable
- `prefers-reduced-motion: reduce` disables **everything** in this document.
  Wrap it once, globally:
  ```css
  @media (prefers-reduced-motion: reduce) {
    *, *::before, *::after {
      animation-duration: 0.01ms !important;
      animation-iteration-count: 1 !important;
      transition-duration: 0.01ms !important;
      scroll-behavior: auto !important;
    }
  }
  ```
  Plus a JS check so observers do not run at all rather than running invisibly.
- **No parallax, no auto-zoom, no spin, no continuous loops.** These are
  vestibular triggers.
- No content is unreachable or unreadable while an animation is mid-flight.
- Nothing animates in a way that could read as flashing.
- Keyboard navigation is entirely unaffected. Focus never lands on an element
  that is mid-reveal and invisible.

### Mobile
- The claw tear renders, but with a shorter travel distance and fewer path
  points. Test on a real mid-range Android, not just a desktop viewport resize.
- Wolf companion does not render below the tablet breakpoint.
- Hover effects do not exist on touch — no sticky hover states.
- If frame rate drops below ~50fps on the tear, cut it to a fade on mobile.

---

## Build order

**Connective motion first, signature second.** The ambient layer does more for
perceived quality than the claw does, and it is not blocked on any asset.

1. **Motion tokens** in Tailwind config. Everything downstream depends on them.
2. **Global reduced-motion guard** and a shared `useReveal` utility.
3. **Connective layer** — section entry, sticky nav condense, link underline,
   button feedback, image reveal, stat odometer. This is the bulk of the work
   and the bulk of the payoff.
4. Background rhythm transition, language toggle crossfade, form states.
5. **Measure Lighthouse.** Establish the baseline before adding the signature.
6. Scratch stroke-draw on dividers — proves the SVG pipeline.
7. Claw tear on the homepage hero → stats boundary. **Measure again.**
8. Card hover flick.
9. Claw tear on Competitions and Get Involved, reusing the component.
10. Wolf scroll companion — last, and cut freely.

Steps 1–4 can start immediately. Steps 6–9 wait on the SVG claw asset.

Build the tear as a **single reusable component** taking direction, weight, and
trigger offset as props. Three bespoke implementations would be three things to
maintain.

---

## Verification

- [ ] Reduced-motion: every animation disabled, layout intact, static scratch
      dividers render
- [ ] Lighthouse performance ≥ 90 on Home with all motion enabled
- [ ] Added JS under 8 KB gzipped
- [ ] 60fps on the tear on desktop; ≥ 50fps on a mid-range Android
- [ ] No animation re-fires on scroll-back
- [ ] Keyboard navigation unaffected; no focus on invisible elements
- [ ] Touch devices show no hover artifacts
- [ ] Content readable if scrolling stops mid-animation
- [ ] Works with JavaScript disabled — everything visible, nothing hidden
- [ ] No `will-change` left applied after animations complete
- [ ] No raw durations or easings in components — all reference tokens
- [ ] Nothing auto-plays; all motion is scroll-, hover-, or click-triggered
- [ ] Grid stagger caps at 6 items (check the 25-card team grid)
- [ ] Language toggle animates opacity only, no layout reflow
- [ ] Submit button does not change width when entering pending state

---

## Explicitly out of scope

Things that will be tempting and should not be built:

- Claw tear on page navigation (fires without context, every click)
- Animated wolf mascot following the cursor
- Scratch marks on button hover (too frequent, becomes noise)
- Sound effects
- Animated page loader — this is a static site, there is nothing to load
- Parallax anything
- Text scrambling or typewriter effects on headlines
- More than two signature moments on any single page
