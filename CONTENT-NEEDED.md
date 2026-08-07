# Content Needed

Outstanding assets and copy. Each item lists exactly where it goes so it can be
filled in without hunting. TODO markers in the data files match this list.

## Assets & data

| Item | Destination | Status |
|---|---|---|
| ~~Updated photo bank (delegates, events, teams)~~ | `/src/assets/photos/` | ✅ Resolved — 7 photos placed via `src/data/photos.ts`. Raw originals in the gitignored `photo-bank/` |
| Photographer publication rights + credit | `src/data/photos.ts` (`credit` field, if needed) | ⚠ Unconfirmed — Vince Noël Photographe, Guillaume, Karl-Erik, Jean-Daniel. Resolve before launch, not after |
| International competition photography | `/src/assets/photos/` | Pending — internationals are the headline selling point and have zero imagery. TUBC and Eller are this fall |
| Photos without people in them | `/src/assets/photos/` | Pending — every current photo has faces, so no section can put a headline over an image. A few venue/detail shots unlock those layouts |
| Google Form for `/report` | `src/data/site.json` → `incidentFormUrl` (`en` + `fr`) | Pending — page shows a "being set up" state with a direct email. Verify the three Form settings, then set `incidentFormAnonymous` |
| Executive roster: emails, LinkedIn, headshots | `src/data/team.json` (photos in `/src/assets/photos/team/`, referenced as `"team/<file>.jpg"`) | Names + roles in (23 members, 2 groups) — emails/LinkedIn/photos still pending, cards show initials avatars |
| Sponsor list + tiers + logo files | `src/data/sponsors.json` (logos in `/src/assets/sponsors/`, named `sponsor-<name>.png`) | Pending — /sponsors renders a coming-soon state |
| Nationals/internationals competition list | `src/data/competitions.json` → `internationals.items` | Names/hosts/cities/URLs/logos in (7 competitions, grouped Fall 2026 / Winter 2027). Still pending: blurbs |
| 2026–2027 regional competition logos | `/src/assets/competitions/`, referenced from `competitions.json` `logo` fields | 4/5 in — Jeux du Commerce, Management Symposium, Financial Open, Happening Marketing added. JDC Central (JDCC) still pending, they haven't published a logo yet |
| Active sign-up form URL | `src/data/site.json` → `signupUrl` | Pending — Get Involved shows "Applications opening soon" |
| Sign-up deadline / recruitment dates | `src/data/site.json` → `signupDeadline` | Pending |
| JMCC office room number | `src/data/contact.json` → `address.room` | Pending — address renders without a Room line |
| New VP Internal email | `src/data/contact.json` → `vpInternal.email` | Name resolved — Juliette Perreault. Email pending; `/report` falls back to the general address until it is set |
| ~~Instagram URL~~ | `contact.json` | ✅ Resolved — `instagram.com/jmcconline` |
| Portal marketing mock-up | `src/components/PortalPlaceholder.astro` | Optional, later — swap the visual in this one file |
| Transparent shield PNG re-exports | `/src/assets/brand/` (see ASSETS.md) | Pending from Phase 1 |

## FR review — team.json

`team.json`'s `_fr_review` note: French titles use the Quebec institutional
convention of naming the function (« Vice-présidence aux finances ») rather
than the person (« Vice-président »), specifically to avoid gendered
agreement. Confirm with the exec team before launch — some may prefer
gendered forms matching how they refer to themselves.

## Copy review

| Item | Location | Status |
|---|---|---|
| "What Is a Case Competition?" copy | `src/pages/index.astro` | Drafted from the brief — verify against the old Wix site's original definition copy |
| Who We Are section copy | `src/pages/who-we-are.astro` | Drafted from the brief — verify against the old site's content |
| French translations — ALL page copy | `copy.fr` objects in every `src/pages/*.astro`, plus `src/i18n/fr.json` and `fr` fields in `src/data/*.json` | ⚠ Machine-drafted — requires human FR review before launch; do not present as final |
| ~~Blog posts migration~~ | `/src/content/blog/` | ✅ Resolved — all 11 posts migrated and hidden behind `blogPublic: false` |

## Repo hygiene — before handover

| Item | Status |
|---|---|
| Repo in the JMCC org with at least two Owners | ✅ In `jmcc-jmsb`, two admins: `cchadirdjian13`, `jmcc-tech` |
| Branch protection on `master` | ⚠ **Not set.** Decide before handover — see note below |
| `.gitignore` covers `.env`, `config.local.php`, keys, `dist/` | ✅ Covered |
| README explains the stack and how to run locally | ✅ Rewritten |
| Deploy key rotation documented | ✅ In `MAINTENANCE.md` |
| `wix-archive/` backed up off this machine | ⚠ **Not done** — gitignored, and the only copy once Wix lapses |

**Branch protection, deliberately left off.** `master` is currently unprotected, which is
why a single person can merge their own PRs — the workflow used throughout the build.
Turning on "require a pull request before merging" **with required approvals** would block
that entirely while the team is one person. The useful middle ground is to enable
protection with *zero* required approvals plus "block force pushes" and "require status
checks to pass" — that keeps the safety net without needing a second reviewer. Worth
setting once a second person is actively committing.
