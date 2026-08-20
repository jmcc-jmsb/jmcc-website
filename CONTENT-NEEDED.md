# Content Needed

Outstanding assets and copy. Each item lists exactly where it goes so it can be
filled in without hunting. TODO markers in the data files match this list.

## Assets & data

| Item | Destination | Status |
|---|---|---|
| ~~Updated photo bank (delegates, events, teams)~~ | `/src/assets/photos/` | ✅ Resolved — 7 photos placed via `src/data/photos.ts`. Raw originals in the gitignored `photo-bank/` |
| ~~Photographer publication rights + credit~~ | `src/data/photos.ts` | ✅ Resolved 2026-08-18 — rights confirmed for all four (Vince Noël Photographe, Guillaume, Karl-Erik, Jean-Daniel). **No on-page credit required**, so no `credit` field. Revisit only if that arrangement changes |
| International competition photography | `/src/assets/photos/` | Pending — internationals are the headline selling point and have zero imagery. TUBC and Eller are this fall |
| Photos without people in them | `/src/assets/photos/` | Pending — every current photo has faces, so no section can put a headline over an image. A few venue/detail shots unlock those layouts |
| ~~Google Form for `/report`~~ | `src/data/site.json` → `incidentFormUrl` (`en` + `fr`) | ✅ Resolved — live Form embedded on both routes, and `incidentFormAnonymous` is `true` (settings re-verified 2026-08-18 — 'Collect email addresses' still Off, so the page states the anonymity claim). ⚠ Still open: the **bilingual approach is the VP Internal's call and is not yet made** — both languages currently point at the same English Form. See MAINTENANCE.md for the three options |
| Executive roster: headshots | `src/data/team.json` (photos in `/src/assets/photos/team/`, referenced as `"team/<file>.jpg"`) | Names, roles and all 25 LinkedIn URLs in (25 members, 2 groups) — **photos still pending**, cards show initials avatars. Emails are not needed: exec emails are never rendered, general enquiries route to `/contact` |
| Sponsor list + tiers + logo files | `src/data/sponsors.json` (logos in `/src/assets/sponsors/`, named `sponsor-<name>.png`) | Pending — /sponsors renders a coming-soon state |
| ~~Nationals/internationals competition list~~ | `src/data/competitions.json` → `internationals.items` | ✅ Resolved 2026-08-18 — names, hosts, cities, URLs, logos and now **all 6 blurbs** are in (7 competitions, grouped Fall 2026 / Winter 2027). Blurbs were written from each competition's own site; see the `_blurbs` note in the file. ⚠ They carry live figures (edition number, university and country counts, case lengths) that go stale — **re-check each season**. ⚠ **BBICC's site 503'd again on 2026-08-18**, and the alternate `bbicc.org` is suspended at its registrar; its blurb is sourced from the Faculty of Organizational Sciences' 2026 write-up instead. Re-check the URL before launch |
| 2026–2027 regional competition logos | `/src/assets/competitions/`, named `<competition-slug>.<ext>` | Done — all 5 in (Jeux du Commerce, Management Symposium, Financial Open, Happening Marketing, JDC Central). **Logos resolve by slug, not from the `logo` field** — drop in `<slug>.png` and it appears. Management Symposium's is still the pre-rename asset; a fresh one was requested |
| **Discipline descriptions, EN + FR (40 entries)** | `src/data/competitions.json` → `disciplines.items[].description` | ⚠ Needs VP Academics sign-off — all 40 written, no `TODO` left. ✅ **19 are now sourced from official guides** (2026-08-18): the 12 **JDC** entries from the JDC 2027 Individual Case Guides, and the 7 **Management Symposium** entries from the SMNG Academic Guide. See `_descriptions`, `_jdc_naming` and `_smng_guide` in the data file. ⚠ **Financial Open and Happening Marketing are still written from the discipline name alone** — guides for both are what would close them. ⚠ **JDC Central** shares 8 entries with JDC and now carries JDC's wording; its own guide has not been seen, and JDC names three of them differently (see `_jdc_naming`). FR is machine-drafted |
| ~~Happening Marketing discipline list~~ | `src/data/competitions.json` → each discipline's `competitions[]` | ✅ Resolved — 12 mapped. 7 new marketing entries added; Surprise, Quiz, Sports, Social and Participation reuse existing entries |
| ~~Tax/Taxation, HR/HRM, Accounting split~~ | `src/data/competitions.json` → `disciplines.items` | ✅ Decided 2026-08-18 — **keep all of them separate as they are.** Each competition names its discipline differently and the entries mirror that. No merge, no change to `regionals[].disciplines` |
| ~~Discipline categories + assignments~~ | `src/data/competitions.json` → `disciplines.categories` | ✅ Resolved — two categories, Academic (36) and Involvement (4). Jump nav is live |
| ~~Which competition runs which discipline~~ | `src/data/competitions.json` → `competitions[]` | ✅ Resolved — all 40 mapped; drives the "Runs at" line and the `?comp=` filter |
| ~~Which 5–6 disciplines feature on Home~~ | `src/data/competitions.json` → `featured: true` | ✅ Resolved — 6 flagged: Finance, Marketing, Human Resources, Strategy, 24-Hour Interactive, Debate |
| Alumni employer list + logos | `src/data/alumni-companies.json` (logos in `/src/assets/alumni/`) | Pending — Home strip is hidden while empty. ⚠ Confirm JMCC is comfortable displaying each mark; `logo: null` renders the name as text, which avoids the trademark question entirely |
| Testimonials (with permission to publish) | `src/data/testimonials.json` | Pending — donate section hidden while empty. Needs the quote, the attribution each person agreed to, and their role |
| ~~FAQ questions and answers~~ | `src/data/faq.json` | ✅ Resolved — 13 questions drafted across the four categories, EN + FR |
| ~~Instagram posts (3–4)~~ | `src/data/instagram.json` (images in `/src/assets/instagram/`) | ✅ Resolved — 6 posts in, grid renders three across at 4:5. ⚠ **Still the only part of the site needing periodic manual refresh** — see MAINTENANCE.md |
| Active sign-up form URL | `src/data/site.json` → `signupUrl` | Pending — currently masked: `recruitmentOpen` is `false`, so the mailing-list CTA renders instead. Needed **before** that flag is flipped, or Get Involved falls through to "Applications opening soon" |
| ~~Mailing list URL~~ | `src/data/site.json` → `mailingListUrl` | ✅ Resolved — HubSpot hosted page, live as the delegate waitlist CTA. ⚠ `/privacy` commits to CASL terms (opt-in only, sender identification, working unsubscribe in every message) — verify the list is configured that way **before the first send** |
| Sign-up deadline / recruitment dates | `src/data/site.json` → `signupDeadline` | Pending |
| **Competition results** | `src/data/results.json` | ⚠ **The blocker for the trophy cabinet.** The page, filters, summary band, home strip and podium counts are all built and tested; there is simply no result data. Needs placements dug out of past exec, old Instagram posts, or the REFAEC/JDC archives — several seasons, not one. Format and rules in MAINTENANCE.md → "Add a season to the trophy cabinet". While it is empty `/trophy-cabinet` holds a coming-soon state, stays out of the nav, and is noindexed |
| Podium photos tagged by season | `/src/assets/photos/` | Optional — a season can name a key from `src/data/photos.ts` in its `photo` field and that shot runs under the season heading. `foPodiumTrophy` and `celebrationTrio` already fit 2025–2026 |
| ~~**Privacy policy — exec sign-off**~~ | `src/pages/privacy.astro` | ✅ Resolved 2026-08-19 — execs have signed off. Still not reviewed by CASA or Concordia; that was never a blocker for our own policy |
| ~~Privacy officer~~ | `src/pages/privacy.astro` → `officer` | ✅ Resolved 2026-08-19 — stays with the President of JMCC, no delegation. Law 25's default, so nothing to record in writing |
| ~~Minors under 14~~ | `src/pages/privacy.astro` | ✅ Resolved 2026-08-19 — "Children under 14" clause added in EN and FR: nothing directed at children, parental consent required under 14, we delete what we learn we hold without it |
| ~~Photo takedown process~~ | `src/pages/privacy.astro` → "Photos and video" | ✅ Resolved 2026-08-19 — VP Technology & Innovation handles takedown requests and removes the photo where the reason is valid. No turnaround time is promised on the page; add one if exec wants to commit to it |
| Mailing list unsubscribe | `src/pages/privacy.astro` → "Our mailing list" | ⚠ Deferred to a future PR — nobody on the tech side has HubSpot access yet. The page commits to CASL terms (opt-in only, sender ID, working unsubscribe in every message); verify the list is configured that way before the first send. The commitment is live even though `mailingListUrl` is not |
| ~~Retention periods~~ | `src/pages/privacy.astro` → "How long we keep it" | ✅ Resolved 2026-08-18. The **12-month log limit is enforced in code**: `contact.php` sweeps `contact.log` and expired rate-limit files once a day, driven by `LOG_RETENTION_SECONDS` in `public/api/config.php`, with test coverage in `tests/test-contact.ps1`. Change that constant and the policy text in the same commit. The unenforceable **24-month cap on contact messages was removed** rather than left as a promise nobody keeps — the policy now says we delete them once there is no reason to keep them, which is what actually happens |
| ~~JMCC office room number~~ | `src/data/contact.json` → `address.room` | ✅ Resolved — MB S1-455, 1450 Guy Street (John Molson Building) |
| ~~New VP Internal email~~ | `src/data/contact.json` | ✅ No longer needed — incident reports go through the embedded Google Form, not email, so `/report` uses the general address and `contact.json` records that decision. Nothing to fill in |
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
| French translations — ALL page copy | `copy.fr` objects in every `src/pages/*.astro`, plus `src/i18n/fr.json` and `fr` fields in `src/data/*.json` | ⚠ Machine-drafted — requires human FR review before launch; do not present as final. Competition names and discipline terms especially, where the JDC/REFAEC circuit has established French usage |
| FR brand terms | same files | ✅ Audited — "We Compete" and "Wolfpack" stay in English in FR copy and are never translated, italicised, or glossed |
| ~~Blog posts migration~~ | `/src/content/blog/` | ✅ Resolved — all 11 posts migrated and hidden behind `blogPublic: false` |

## Repo hygiene — before handover

| Item | Status |
|---|---|
| Repo in the JMCC org with at least two Owners | ✅ In `jmcc-jmsb`, two admins: `cchadirdjian13`, `jmcc-tech` |
| Branch protection on `master` | ⚠ **Not set.** Decide before handover — see note below |
| `.gitignore` covers `.env`, `config.local.php`, keys, `dist/` | ✅ Covered |
| README explains the stack and how to run locally | ✅ Rewritten |
| Deploy key rotation documented | ✅ In `MAINTENANCE.md` |
| Automated tests run in CI | ✅ `test-contact.ps1` runs on every PR and gates the deploy. `check-redirects.ps1` stays manual — it needs a real Apache |
| `wix-archive/` backed up off this machine | ✅ Resolved 2026-08-20 — in the team Google Drive. Still gitignored, so Drive is the copy that has to survive exec handovers |
| Dangling doc references | ✅ Resolved. `photo-placement.md` and the phase-2b spec were never in the repo or its history, so the citations to them were stripped from `ASSETS.md`, `src/data/photos.ts`, `motion-layer.md`, the `_note` fields and the component comments. The reasoning each one carried was kept inline; only the pointer to the unopenable file is gone |

**Branch protection, deliberately left off.** `master` is currently unprotected, which is
why a single person can merge their own PRs — the workflow used throughout the build.
Turning on "require a pull request before merging" **with required approvals** would block
that entirely while the team is one person. The useful middle ground is to enable
protection with *zero* required approvals plus "block force pushes" and "require status
checks to pass" — that keeps the safety net without needing a second reviewer. Worth
setting once a second person is actively committing.
