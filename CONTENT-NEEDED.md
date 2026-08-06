# Content Needed

Outstanding assets and copy. Each item lists exactly where it goes so it can be
filled in without hunting. TODO markers in the data files match this list.

## Assets & data

| Item | Destination | Status |
|---|---|---|
| Updated photo bank (delegates, events, teams) | `/src/assets/photos/` | Pending — heroes currently use the editorial wolf photos |
| Executive roster: names, roles, emails, headshots | `src/data/team.json` (photos in `/src/assets/photos/team/`, referenced as `"team/<file>.jpg"`) | Pending — /team renders a coming-soon state until real entries land |
| Sponsor list + tiers + logo files | `src/data/sponsors.json` (logos in `/src/assets/sponsors/`, named `sponsor-<name>.png`) | Pending — /sponsors renders a coming-soon state |
| Nationals/internationals competition list | `src/data/competitions.json` → `internationals.items` | Pending — section renders a coming-soon state |
| 2026–2027 regional competition logos | `/src/assets/competitions/`, referenced from `competitions.json` `logo` fields | Pending — cards show the branded placeholder |
| Active sign-up form URL | `src/data/site.json` → `signupUrl` | Pending — Get Involved shows "Applications opening soon" |
| Sign-up deadline / recruitment dates | `src/data/site.json` → `signupDeadline` | Pending |
| JMCC office room number | `src/data/contact.json` → `address.room` | Pending — address renders without a Room line |
| New VP Internal name + email | `src/data/contact.json` → `vpInternal` | Pending — needed for the Phase 4 report handler |
| ~~Instagram URL~~ | `contact.json` | ✅ Resolved — `instagram.com/jmcconline` |
| Portal marketing mock-up | `src/components/PortalPlaceholder.astro` | Optional, later — swap the visual in this one file |
| Transparent shield PNG re-exports | `/src/assets/brand/` (see ASSETS.md) | Pending from Phase 1 |

## Copy review

| Item | Location | Status |
|---|---|---|
| "What Is a Case Competition?" copy | `src/pages/index.astro` | Drafted from the brief — verify against the old Wix site's original definition copy |
| Who We Are section copy | `src/pages/who-we-are.astro` | Drafted from the brief — verify against the old site's content |
| French translations — ALL page copy | `copy.fr` objects in every `src/pages/*.astro`, plus `src/i18n/fr.json` and `fr` fields in `src/data/*.json` | ⚠ Machine-drafted — requires human FR review before launch; do not present as final |
| Blog posts migration | `/src/content/blog/` | Phase 3 |
