// ABOUTME: Shared motion runtime — reduced-motion gate, scroll reveal, sticky nav condense.
// ABOUTME: The only JS in the motion layer; everything is trigger-driven and nothing auto-plays.

/**
 * The global off-switch. When true no observer is constructed at all — running
 * them and discarding the result still costs main-thread work on the devices
 * most likely to need the setting.
 */
export const prefersReducedMotion = (): boolean =>
  window.matchMedia('(prefers-reduced-motion: reduce)').matches;

/**
 * Reveals elements once as they enter the viewport. Never re-triggers on
 * scroll-back — `unobserve` on first intersection, and `.is-revealed` keeps the
 * element out of the next query.
 *
 * `[data-reveal-group]` is observed as a unit rather than per child, so the
 * cascade reads as one movement and a 23-card grid costs one observer instead
 * of 23. The stagger itself is CSS (capped at 6 in global.css).
 */
function initReveal(): void {
  // A [data-reveal] inside a group would stack two effects on one element; the
  // group wins, so direct children are excluded from the individual query.
  const els = [
    ...document.querySelectorAll(
      '[data-reveal]:not(.is-revealed):not([data-reveal-group] > *), [data-reveal-group]:not(.is-revealed)',
    ),
  ];
  if (!els.length) return;

  if (prefersReducedMotion()) {
    els.forEach((el) => el.classList.add('is-revealed'));
    return;
  }

  const reveal = (io: IntersectionObserver) => (entries: IntersectionObserverEntry[]) => {
    for (const entry of entries) {
      if (!entry.isIntersecting) continue;
      entry.target.classList.add('is-revealed');
      io.unobserve(entry.target);
    }
  };

  // Content: pre-trigger. The positive bottom margin extends the root *below* the
  // viewport so an element settles just before it scrolls into sight — content is
  // never caught still hidden. (A negative margin does the opposite: it shrinks the
  // root and delays the trigger until the element is well inside the viewport.)
  // threshold 0, because a band taller than the viewport can never reach a
  // fractional threshold before it already fills the screen.
  let contentIo: IntersectionObserver;
  contentIo = new IntersectionObserver((e) => reveal(contentIo)(e), {
    threshold: 0,
    rootMargin: '0px 0px 20% 0px',
  });

  // The scratch draw is the opposite case: it is the effect, not a way of getting
  // content on screen. Pre-triggering it meant the gashes finished drawing below the
  // fold and you only ever saw the result, so this one waits until it is properly in
  // view.
  //
  // "Properly in view" is expressed as a negative rootMargin — shrink the root to its
  // middle 70% — rather than a fractional threshold. The divider is rotated 90° and
  // sits inside an overflow:hidden strip, and a fractional threshold never fires on
  // it: the same element reports intersectionRatio 1 at threshold 0 and nothing at
  // all at 0.6. threshold 0 against a shrunken root is the reliable primitive.
  let drawIo: IntersectionObserver;
  drawIo = new IntersectionObserver((e) => reveal(drawIo)(e), {
    threshold: 0,
    rootMargin: '-15% 0px -15% 0px',
  });

  for (const el of els) {
    (el.getAttribute('data-reveal') === 'draw' ? drawIo : contentIo).observe(el);
  }
}

let navObserver: IntersectionObserver | null = null;

/**
 * Condenses the sticky nav once the page has scrolled past the sentinel (120px
 * tall, anchored to the document origin, zero layout footprint).
 *
 * Deliberately two-way: the nav must expand again at the top of the page. This
 * is the one effect in the layer that is not fire-once. It never hides the nav.
 */
function initNavCondense(): void {
  navObserver?.disconnect();
  navObserver = null;

  const sentinel = document.getElementById('nav-sentinel');
  const header = document.querySelector('header');
  if (!sentinel || !header || prefersReducedMotion()) return;

  navObserver = new IntersectionObserver(
    ([entry]) => header.classList.toggle('is-condensed', !entry.isIntersecting),
    { threshold: 0 },
  );
  navObserver.observe(sentinel);
}

/**
 * Measures each gash once and publishes its length as --draw-len, which the CSS uses
 * for both stroke-dasharray and the starting stroke-dashoffset.
 *
 * This has to be measured rather than declared: the three gashes are 9450, 11597 and
 * 8185 user units, so a single hardcoded value would leave two of them either
 * finishing early or never finishing. Running it before any reveal fires is what
 * keeps the divider hidden until it draws.
 */
function initScratchDraw(): void {
  if (prefersReducedMotion()) return;
  for (const path of document.querySelectorAll<SVGPathElement>('.claw-draw path')) {
    if (path.dataset.drawLen) continue;
    path.dataset.drawLen = '1';
    path.style.setProperty('--draw-len', String(Math.ceil(path.getTotalLength())));
  }
}

export function initMotion(): void {
  initScratchDraw();
  initReveal();
  initNavCondense();
}
