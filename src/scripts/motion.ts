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

let tearObserver: IntersectionObserver | null = null;
let tearFrame = 0;
const activeTears = new Set<HTMLElement>();

/**
 * Maps the boundary's position to 0–1: 0 when it crosses the bottom of the
 * viewport (later, if triggerOffset says so), 1 by the time it reaches the
 * centre. Completing at the centre is what guarantees nobody who stops scrolling
 * is left looking at half-clipped content.
 */
function updateTear(el: HTMLElement): void {
  // One-way. Progress drives the opening, but once open it stays open: scrolling
  // back up must not re-close and replay it. Cheap guard, and it also means a tear
  // left behind costs nothing even if it somehow stays in the active set.
  if (el.classList.contains('is-torn')) return;

  const offset = parseFloat(el.dataset.triggerOffset ?? '0') || 0;
  const start = window.innerHeight * (1 - offset);
  const end = window.innerHeight * 0.5;
  const { top } = el.getBoundingClientRect();
  const span = start - end;
  const p = span <= 0 ? 1 : Math.min(Math.max((start - top) / span, 0), 1);

  el.style.setProperty('--tear-p', p.toFixed(3));
  // Past the finish line the clip is dropped entirely, so the section is provably
  // fully visible rather than relying on the gashes having grown enough to meet.
  el.classList.toggle('is-torn', p >= 0.995);
}

function tearTick(): void {
  tearFrame = 0;
  for (const el of activeTears) {
    updateTear(el);
    // Finished tears drop out of the loop and stop being watched, so a page that
    // has been scrolled through runs no per-frame work at all.
    if (el.classList.contains('is-torn')) {
      activeTears.delete(el);
      tearObserver?.unobserve(el);
    }
  }
  if (activeTears.size) tearFrame = requestAnimationFrame(tearTick);
}

/**
 * Drives the tear from scroll position without a scroll listener: the observer
 * decides *whether* a tear is close enough to matter, and a rAF loop runs only
 * while at least one is. Scroll past everything and the loop stops completely.
 */
function initTears(): void {
  tearObserver?.disconnect();
  tearObserver = null;
  activeTears.clear();
  if (tearFrame) {
    cancelAnimationFrame(tearFrame);
    tearFrame = 0;
  }

  const tears = document.querySelectorAll<HTMLElement>('[data-tear]');
  if (!tears.length || prefersReducedMotion()) return;

  tearObserver = new IntersectionObserver(
    (entries) => {
      for (const entry of entries) {
        const el = entry.target as HTMLElement;
        if (entry.isIntersecting) {
          activeTears.add(el);
        } else {
          activeTears.delete(el);
          // One last update so a tear scrolled past in a single flick settles on
          // its terminal state instead of freezing mid-tear.
          updateTear(el);
        }
      }
      if (activeTears.size && !tearFrame) tearFrame = requestAnimationFrame(tearTick);
    },
    { rootMargin: '25% 0px 25% 0px' },
  );
  tears.forEach((t) => {
    // A tear already on screen at load never had a scroll gesture to drive it.
    // Opening it outright beats rendering the section half-clipped and leaving it
    // that way until someone happens to scroll.
    if (t.getBoundingClientRect().top < window.innerHeight) t.classList.add('is-torn');
    updateTear(t);
    tearObserver!.observe(t);
  });
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
  initTears();
}
