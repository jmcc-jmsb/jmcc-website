// ABOUTME: Build-time helper that inlines jmcc-claw.svg, without touching the asset.
// ABOUTME: Exports the bare gash group for clip paths and edges.
import clawSvg from '../assets/brand/jmcc-claw.svg?raw';

/**
 * Just the `<g>` holding the three gashes, ready to drop inside a bare <svg>. The
 * asset's own translate/scale stays on the group, so path data is untouched —
 * callers wrap this in whatever transform their coordinate space needs.
 *
 * `id` attributes are stripped: `id="claw-1"` twice on a page is invalid, and
 * ClawDefs inlines this once per page. Nothing references the gashes by id.
 */
export const clawGashes = (() => {
  const group = clawSvg.match(/<g\b[^>]*>[\s\S]*<\/g>/);
  if (!group) throw new Error('jmcc-claw.svg: expected a <g> wrapping the three gash paths');
  return group[0].replace(/\sid="[^"]*"/g, '').replace(/<path /g, '<path class="tear-gash" ');
})();
