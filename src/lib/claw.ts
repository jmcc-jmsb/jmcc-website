// ABOUTME: Build-time helpers that inline jmcc-claw.svg for animation, without touching the asset.
// ABOUTME: Exports the whole SVG for dividers and the bare gash group for clip paths and edges.
import clawSvg from '../assets/brand/jmcc-claw.svg?raw';

/**
 * The full SVG, for the divider's stroke-draw.
 *
 * No `pathLength="1"` normalisation: it is not honoured for dash calculations here
 * (getTotalLength still reports the raw 8k–12k unit lengths), so a dasharray of 1
 * paints as a solid line and the draw silently does nothing. motion.ts measures each
 * path once instead and writes the real length into --draw-len.
 *
 * ids are stripped for the same reason as `clawGashes`: a page can hold more than
 * one divider — Home renders one directly and another inside ClawTear's
 * reduced-motion fallback — and `id="claw-1"` twice is invalid. The draw stagger
 * selects by nth-child, so nothing needs them.
 */
export const clawDrawSvg = clawSvg.replace(/\sid="[^"]*"/g, '');

/**
 * Just the `<g>` holding the three gashes, ready to drop inside a <clipPath> or a
 * bare <svg>. The asset's own translate/scale stays on the group, so path data is
 * untouched — callers wrap this in whatever transform their coordinate space needs.
 *
 * `id` attributes are stripped: the tear inlines this twice (once to clip, once to
 * stroke the sand edge) and a page may hold several tears, so keeping them would
 * emit duplicate element ids. Nothing references the gashes by id — order in the
 * document is left-to-right, which is all the stagger rules need.
 */
export const clawGashes = (() => {
  const group = clawSvg.match(/<g\b[^>]*>[\s\S]*<\/g>/);
  if (!group) throw new Error('jmcc-claw.svg: expected a <g> wrapping the three gash paths');
  return group[0].replace(/\sid="[^"]*"/g, '').replace(/<path /g, '<path class="tear-gash" ');
})();

/**
 * Maps the claw's 410×608 portrait box onto a 0–1 objectBoundingBox square with the
 * long axis running horizontally — a transpose, so the gashes read as three roughly
 * parallel slashes across the width of whatever is being torn open.
 * matrix(a,b,c,d,e,f) => x' = a·x + c·y + e ; y' = b·x + d·y + f
 *   x' = y / 608   (claw's height becomes the output width)
 *   y' = x / 410   (claw's width becomes the output height)
 */
export const CLAW_TO_UNIT_BOX = `matrix(0, ${1 / 410}, ${1 / 608}, 0, 0, 0)`;
