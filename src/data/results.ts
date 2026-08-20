// ABOUTME: Trophy cabinet data — reads results.json, validates every slug against competitions.json
// ABOUTME: at build time, and derives the totals and lookups the cabinet, home and cross-links use.
import competitions from './competitions.json';
import resultsData from './results.json';
import { photos } from './photos';
import type { Locale } from '../i18n/utils';

export type Placement = 1 | 2 | 3 | 'finalist' | 'honourable';

export interface Result {
  competition: string;
  discipline?: string | null;
  placement: Placement;
  note?: { en: string; fr: string };
}

export interface Season {
  season: string;
  /** Optional key from photos.ts. The newest season that sets one supplies the cabinet's banner. */
  photo?: string;
  results: Result[];
}

// Competition slugs are matched with their edition year stripped: competitions.json
// carries 'tubc-2026' because it lists this season's lineup, but a result belongs to
// the competition, not the edition — otherwise every historical entry would need a
// slug that only exists for one year.
const baseSlug = (slug: string) => slug.replace(/-\d{4}$/, '');

const competitionNames = new Map<string, { en: string; fr: string }>();
for (const item of competitions.internationals.items) {
  if (!item.slug.startsWith('TODO')) competitionNames.set(baseSlug(item.slug), item.name);
}
for (const group of competitions.regionals) {
  for (const item of group.items) {
    if (!item.slug.startsWith('TODO')) competitionNames.set(baseSlug(item.slug), item.name);
  }
}
// Competitions that only exist in past seasons live in results.json, not competitions.json:
// that file is this season's lineup and adding a 2021 competition to it would put a dead
// card on /competitions.
for (const [slug, name] of Object.entries(resultsData._historical?.competitions ?? {})) {
  competitionNames.set(slug, name);
}

const disciplineNames = new Map<string, { en: string; fr: string }>();
for (const d of competitions.disciplines.items) {
  if (!d.slug.startsWith('TODO')) disciplineNames.set(d.slug, d.name);
}
// Same for disciplines a competition has since renamed or dropped.
for (const [slug, name] of Object.entries(resultsData._historical?.disciplines ?? {})) {
  disciplineNames.set(slug, name);
}

const PLACEMENTS: Placement[] = [1, 2, 3, 'finalist', 'honourable'];

// Fails the build rather than rendering a filter that silently matches nothing. This
// is data nobody looks at for a year at a time; a typo has to surface the day it is
// made, not the season after.
function validate(seasons: Season[]): void {
  const problems: string[] = [];
  for (const s of seasons) {
    const where = `season "${s.season}"`;
    if (!/^\d{4}-\d{4}$/.test(s.season)) {
      problems.push(`${where}: season must read like "2025-2026"`);
    }
    if (s.photo && !(s.photo in photos)) {
      problems.push(`${where}: photo "${s.photo}" is not a key in src/data/photos.ts`);
    }
    for (const r of s.results) {
      if (!competitionNames.has(baseSlug(r.competition))) {
        problems.push(
          `${where}: competition "${r.competition}" matches nothing in competitions.json or _historical — fix the slug, or add the competition to one of them first`,
        );
      }
      if (r.discipline && !disciplineNames.has(r.discipline)) {
        problems.push(
          `${where}: discipline "${r.discipline}" matches nothing in competitions.json or _historical — fix the slug, or leave it out for a single-case competition`,
        );
      }
      if (!PLACEMENTS.includes(r.placement)) {
        problems.push(
          `${where}: placement "${r.placement}" is not 1, 2, 3, "finalist" or "honourable"`,
        );
      }
    }
  }
  if (problems.length > 0) {
    throw new Error(`src/data/results.json is invalid:\n  - ${problems.join('\n  - ')}`);
  }
}

// Newest first everywhere. Season strings sort correctly as strings ("2025-2026").
export const seasons: Season[] = (resultsData.seasons as unknown as Season[])
  .slice()
  .sort((a, b) => b.season.localeCompare(a.season));

validate(seasons);

export const hasResults = seasons.some((s) => s.results.length > 0);

export const isPodium = (p: Placement) => p === 1 || p === 2 || p === 3;

const allResults = seasons.flatMap((s) => s.results.map((r) => ({ ...r, season: s.season })));

export const totals = {
  podiums: allResults.filter((r) => isPodium(r.placement)).length,
  golds: allResults.filter((r) => r.placement === 1).length,
  competitions: new Set(allResults.map((r) => baseSlug(r.competition))).size,
  seasons: seasons.filter((s) => s.results.length > 0).length,
};

/** Podium count per competition, keyed by slug with the edition year stripped. */
export const podiumsByCompetition = new Map<string, number>();
for (const r of allResults) {
  if (!isPodium(r.placement)) continue;
  const key = baseSlug(r.competition);
  podiumsByCompetition.set(key, (podiumsByCompetition.get(key) ?? 0) + 1);
}

/** Every result for a discipline, newest season first. Drives the /disciplines line. */
export const resultsByDiscipline = new Map<string, typeof allResults>();
for (const r of allResults) {
  if (!r.discipline) continue;
  const list = resultsByDiscipline.get(r.discipline) ?? [];
  list.push(r);
  resultsByDiscipline.set(r.discipline, list);
}

export const podiumsFor = (competitionSlug: string) =>
  podiumsByCompetition.get(baseSlug(competitionSlug)) ?? 0;

/** Earliest season a competition appears in, for "12 podiums since 2022". */
export const podiumsSince = (competitionSlug: string): string | null => {
  const key = baseSlug(competitionSlug);
  const years = allResults
    .filter((r) => baseSlug(r.competition) === key && isPodium(r.placement))
    .map((r) => r.season.slice(0, 4));
  return years.length > 0 ? years.sort()[0] : null;
};

/** The newest season's podiums, best placement first — the home page strip (max 4). */
export const highlights = (() => {
  const latest = seasons.find((s) => s.results.some((r) => isPodium(r.placement)));
  if (!latest) return [];
  return latest.results
    .filter((r) => isPodium(r.placement))
    .sort((a, b) => Number(a.placement) - Number(b.placement))
    .slice(0, 4)
    .map((r) => ({ ...r, season: latest.season }));
})();

export const competitionName = (slug: string, lang: Locale) =>
  competitionNames.get(baseSlug(slug))?.[lang] ?? slug;

export const disciplineName = (slug: string, lang: Locale) =>
  disciplineNames.get(slug)?.[lang] ?? slug;

/** Filter keys the cabinet's selects are built from — only what the data actually uses. */
export const usedCompetitions = [...new Set(allResults.map((r) => baseSlug(r.competition)))];
export const usedDisciplines = [
  ...new Set(allResults.map((r) => r.discipline).filter((d): d is string => Boolean(d))),
];

export { baseSlug };
