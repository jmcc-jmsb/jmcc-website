---
name: jmcc-motion
description: Build, debug, and verify scroll-triggered and interaction animations in the JMCC Astro site. Use whenever work involves animation, transitions, reveals, the claw tear, motion tokens, prefers-reduced-motion, or when animations are not firing, not visible, or firing only on hard refresh. Also use when measuring animation performance or frame rate.
---

# JMCC Motion

Animation work in an Astro + Tailwind static site with View Transitions enabled.
Read `motion-layer.md` for the design spec. This skill covers **how to build it
correctly and prove it works.**

## Rule zero: verify visually, never assume

Animation cannot be verified by reading code. If Chrome DevTools MCP is
available, use it on every animation change:

1. Navigate to the page
2. Screenshot the initial state
3. Scroll to the trigger point
4. Screenshot again
5. Compare — did the element actually change?

If the tool is unavailable, say so explicitly rather than claiming an animation
works. "I wrote the code" is not "it animates."

## The four failure modes — check these first when animations don't appear

### 1. Scripts don't re-run after View Transitions navigation
**The most common cause in this codebase — and the best reason to prefer tier 1
CSS, which has no script to re-run at all.** Astro View Transitions swap the DOM
without a full page load, so `DOMContentLoaded` fires once and never again.
Symptom: animations work on hard refresh, break after clicking a nav link.

```js
// WRONG — fires once, dead after client-side navigation
document.addEventListener('DOMContentLoaded', initReveals);

// RIGHT — fires on initial load AND every View Transitions navigation
document.addEventListener('astro:page-load', initReveals);
```

Also disconnect observers on `astro:before-swap` to avoid leaking them across
navigations.

### 2. prefers-reduced-motion is active on the developer's machine
The global guard is working exactly as designed and disabling everything.
Windows: Settings → Accessibility → Visual effects → Animation effects.
macOS: System Settings → Accessibility → Display → Reduce motion.

Verify in DevTools → Rendering → "Emulate CSS media feature
prefers-reduced-motion". Toggle both states and confirm the site behaves
correctly in each. **Never "fix" this by removing the guard.**

### 3. Elements already in the viewport never trigger
`IntersectionObserver` fires on intersection *change*. Content above the fold is
already intersecting at observer creation, so it may stay in its hidden
pre-animation state forever.

Handle the initial state explicitly: check `entry.isIntersecting` on the first
callback, or set a `rootMargin` that accounts for it.

### 4. Tailwind purged the classes
Dynamically constructed class names (`` `animate-${dir}` ``) are not detected by
the compiler and get stripped from the build. Symptom: works in dev, dead in
production. Write complete class names, or safelist them.

## Motion tokens — never write raw values

All durations and easings come from the theme (`--duration-*`, `--ease-*`,
`--stagger`). A raw `300ms` or `cubic-bezier(...)` in a component is a bug, even
if it looks right. Cohesion comes from shared timing.

Entrances use `--ease-out`. Never `ease-in-out` on an entrance — it reads as
sluggish.

## Technique priority — always start at tier 1

Most "rudimentary animation" problems come from hand-rolling what the platform
now does natively. Work down this list; stop at the first tier that works.

1. **Native CSS scroll-driven animations** — `animation-timeline: view()` or
   `scroll()`. The default for anything tied to scroll: reveals, the claw tear,
   background transitions. Zero JS, runs on the compositor, no lifecycle to
   manage, and **immune to the View Transitions re-init bug below** because
   there is no script to re-run.

   ```css
   @supports (animation-timeline: view()) {
     @media (prefers-reduced-motion: no-preference) {
       .reveal {
         animation: rise linear both;
         animation-timeline: view();
         animation-range: entry 0% entry 100%;
       }
     }
   }
   ```

   Support: Chrome/Edge 115+, Safari 26+ full; Firefox behind a flag (~82–84%
   global). Outside `@supports`, content is simply visible — a fine fallback.

2. **Plain CSS transitions** — hover, focus, button press, nav condense.

3. **Motion** (`motion.dev`, `motion/mini`, ~2.5 KB) — only for what CSS cannot
   express: orchestrated sequences, language toggle crossfade, filter reflow.

4. **Hand-rolled `IntersectionObserver`** — last resort only.

**Do not import GSAP.** ScrollTrigger is free and good, but ~70 KB+ for what
tier 1 does natively at zero cost. If an effect cannot be built in tier 1,
simplify the effect rather than adding a library.

## Performance rules

- **Animate only `transform` and `opacity`.** Anything else triggers layout or
  paint. Specifically: never animate SVG `d`, `mask-size`, `mask-position`,
  `height`, `width`, `top/left`, or `background-color`.
- Scroll progress via `IntersectionObserver` plus `requestAnimationFrame`.
  **Never a raw `scroll` listener.**
- **Do not add `will-change` preemptively.** The browser promotes layers
  automatically for scroll-driven animations; a permanent `will-change` costs
  memory on every element carrying it.
- No animation libraries. Web Animations API and CSS only. Budget for the entire
  motion layer is **8 KB gzipped**.
- Reveals fire once and do not re-trigger on scroll-back.

### Verifying performance
Use Chrome DevTools MCP performance tracing, not estimation:
- Record a trace while scrolling through the animated section
- Check for long tasks, layout thrashing, and dropped frames
- Target 60fps desktop, ≥50fps mid-range mobile
- Report the actual Lighthouse delta before and after adding an effect

## Accessibility — non-negotiable

- `prefers-reduced-motion: reduce` disables everything. Guard both in CSS and in
  JS (observers should not run at all, not run invisibly).
- Reduced-motion is a **deliberate alternative**, not a degraded one: content
  fully visible, static scratch dividers in place of animated ones.
- No parallax, auto-zoom, spin, or continuous loops — vestibular triggers.
- Nothing auto-plays. All motion is scroll-, hover-, or click-triggered.
- Focus must never land on an element that is mid-reveal and invisible.
- Content stays readable if the user stops scrolling mid-animation.

## Brand assets

`src/assets/brand/jmcc-claw.svg` — three gashes as separate paths (`claw-1`,
`claw-2`, `claw-3`, left to right), viewBox `0 0 410 608`.
`src/assets/brand/jmcc-wolf-running.svg` — single path, viewBox `0 0 1586 882`.

Both use `fill="currentColor"`. **Inline them** — an `<img>` tag cannot be
animated or recolored. Do not modify or re-export these files.

## Definition of done for any animation change

- [ ] Built at the highest applicable tier — no JS where CSS would do
- [ ] Visually verified with before/after screenshots, not assumed
- [ ] Checked in a browser without scroll-timeline support (or with the
      `@supports` block disabled) — content visible, nothing broken
- [ ] Works on hard load AND after View Transitions navigation
- [ ] Correct behaviour in both reduced-motion states
- [ ] Only `transform`/`opacity` animated
- [ ] No raw durations or easings in components
- [ ] Fires once; no re-trigger on scroll-back
- [ ] Added JS measured, still within budget
- [ ] No `will-change` left applied
