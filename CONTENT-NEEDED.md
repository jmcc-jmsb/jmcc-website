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
| ~~Google Form for `/report`~~ | `src/data/site.json` → `incidentFormUrl` (`en` + `fr`) | ✅ Resolved — live Form embedded on both routes, and `incidentFormAnonymous` is `true` (settings verified 2026-08-14, so the page states the anonymity claim). ⚠ Still open: the **bilingual approach is the VP Internal's call and is not yet made** — both languages currently point at the same English Form. See MAINTENANCE.md for the three options |
| Executive roster: headshots | `src/data/team.json` (photos in `/src/assets/photos/team/`, referenced as `"team/<file>.jpg"`) | Names, roles and all 25 LinkedIn URLs in (25 members, 2 groups) — **photos still pending**, cards show initials avatars. Emails are not needed: exec emails are never rendered (phase-2b §1), general enquiries route to `/contact` |
| Sponsor list + tiers + logo files | `src/data/sponsors.json` (logos in `/src/assets/sponsors/`, named `sponsor-<name>.png`) | Pending — /sponsors renders a coming-soon state |
| Nationals/internationals competition list | `src/data/competitions.json` → `internationals.items` | Names/hosts/cities/URLs/logos in (7 competitions, grouped Fall 2026 / Winter 2027). **Still pending: all 6 blurbs.** These were deliberately not drafted — the card already shows name, host, city and country, so a blurb written from that metadata alone would only repeat it, and anything more (format, history, how many schools attend) cannot be sourced from this repo. One or two sentences each from the competition's own site is all that is needed. ✅ URLs are now complete again: MICC, UNICC, BBICC and archived JMUCC were blanked by the marketing-supplied file in `07cff7a` and have been restored. ⚠ BBICC's site returned 503 on 2026-08-17 — re-check before launch |
| 2026–2027 regional competition logos | `/src/assets/competitions/`, named `<competition-slug>.<ext>` | Done — all 5 in (Jeux du Commerce, Management Symposium, Financial Open, Happening Marketing, JDC Central). **Logos resolve by slug, not from the `logo` field** — drop in `<slug>.png` and it appears. Management Symposium's is still the pre-rename asset; a fresh one was requested |
| **Discipline descriptions, EN + FR (40 entries)** | `src/data/competitions.json` → `disciplines.items[].description` | ⚠ Drafted, needs VP Academics sign-off — all 40 written, no `TODO` left. The 15 Jeux du Commerce entries are adapted from [jeuxducommerce.ca/fr/volets](https://jeuxducommerce.ca/fr/volets/); the Financial Open, Management Symposium and Happening Marketing entries are written from the discipline name alone, because those sites publish their cases as PDFs with no on-page blurbs — those are the ones to check first. FR is machine-drafted |
| ~~Happening Marketing discipline list~~ | `src/data/competitions.json` → each discipline's `competitions[]` | ✅ Resolved — 12 mapped. 7 new marketing entries added; Surprise, Quiz, Sports, Social and Participation reuse existing entries |
| Tax/Taxation, HR/HRM, Accounting split | `src/data/competitions.json` → `disciplines.items` | ⚠ Decision needed. Kept as separate entries because each competition names them differently. **Tax/Taxation no longer differ at all** — JDC renamed theirs to Taxation for 2026, so the two entries now share a name in EN *and* FR (« Fiscalité ») and carry identical descriptions; only the competition they map to differs. They are strong merge candidates. Slug `tax` is cross-referenced from `regionals[].disciplines`, so a merge means updating that array too |
| ~~Discipline categories + assignments~~ | `src/data/competitions.json` → `disciplines.categories` | ✅ Resolved — two categories, Academic (36) and Involvement (4). Jump nav is live |
| ~~Which competition runs which discipline~~ | `src/data/competitions.json` → `competitions[]` | ✅ Resolved — all 40 mapped; drives the "Runs at" line and the `?comp=` filter |
| ~~Which 5–6 disciplines feature on Home~~ | `src/data/competitions.json` → `featured: true` | ✅ Resolved — 6 flagged: Finance, Marketing, Human Resources, Strategy, 24-Hour Interactive, Debate |
| Alumni employer list + logos | `src/data/alumni-companies.json` (logos in `/src/assets/alumni/`) | Pending — Home strip is hidden while empty. ⚠ Confirm JMCC is comfortable displaying each mark; `logo: null` renders the name as text, which avoids the trademark question entirely |
| Testimonials (with permission to publish) | `src/data/testimonials.json` | Pending — donate section hidden while empty. Needs the quote, the attribution each person agreed to, and their role |
| FAQ questions and answers | `src/data/faq.json` | Pending — `/faq` shows a coming-soon state. Four categories are scaffolded |
| Instagram posts (3–4) | `src/data/instagram.json` (images in `/src/assets/instagram/`) | Pending — Home section hidden while empty. ⚠ **The only part of the site needing periodic manual refresh** — see MAINTENANCE.md |
| Active sign-up form URL | `src/data/site.json` → `signupUrl` | Pending — currently masked: `recruitmentOpen` is `false`, so the mailing-list CTA renders instead. Needed **before** that flag is flipped, or Get Involved falls through to "Applications opening soon" |
| ~~Mailing list URL~~ | `src/data/site.json` → `mailingListUrl` | ✅ Resolved — HubSpot hosted page, live as the delegate waitlist CTA. ⚠ `/privacy` commits to CASL terms (opt-in only, sender identification, working unsubscribe in every message) — verify the list is configured that way **before the first send** |
| Sign-up deadline / recruitment dates | `src/data/site.json` → `signupDeadline` | Pending |
| **Privacy policy — exec sign-off** | `src/pages/privacy.astro` | ⚠ Decision needed. Page is live and drafted from what the code actually does, but it makes commitments on JMCC's behalf and has **not been reviewed by anyone at CASA or Concordia**. Confirm before it is treated as the official policy |
| Privacy officer | `src/pages/privacy.astro` → `officer` | ⚠ Decision needed. Currently "the President of JMCC" — Law 25's default is whoever holds the highest authority unless the role is formally delegated in writing. If exec delegates it (VP Internal is typical), change this constant and record the delegation |
| Retention periods | `src/pages/privacy.astro` → "How long we keep it" | ⚠ Half resolved. The **12-month log limit is now enforced in code**: `contact.php` sweeps `contact.log` and expired rate-limit files once a day, driven by `LOG_RETENTION_SECONDS` in `public/api/config.php`, with test coverage in `tests/test-contact.ps1`. Change that constant and the policy text in the same commit. **The 24-month limit on contact messages is still unenforced** and cannot be automated — those live in the committee inbox, so it needs someone to actually delete them, or the sentence needs changing |
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
| FR brand terms | same files | ✅ Audited — "We Compete" and "Wolfpack" stay in English in FR copy and are never translated, italicised, or glossed (phase-2b §9) |
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
| `wix-archive/` backed up off this machine | ⚠ **Not done** — gitignored, and the only copy once Wix lapses |
| Dangling doc references | ⚠ **Decision needed.** `photo-placement.md` and the **phase-2b spec** are cited from `ASSETS.md`, `src/data/photos.ts`, and `_note` fields in `site.json`, `faq.json`, `instagram.json`, `alumni-companies.json` and several components — but neither file is in the repo or its history. Either commit them or strip the references. A handover doc that points at files nobody can open is worse than one that does not mention them |

**Branch protection, deliberately left off.** `master` is currently unprotected, which is
why a single person can merge their own PRs — the workflow used throughout the build.
Turning on "require a pull request before merging" **with required approvals** would block
that entirely while the team is one person. The useful middle ground is to enable
protection with *zero* required approvals plus "block force pushes" and "require status
checks to pass" — that keeps the safety net without needing a second reviewer. Worth
setting once a second person is actively committing.
