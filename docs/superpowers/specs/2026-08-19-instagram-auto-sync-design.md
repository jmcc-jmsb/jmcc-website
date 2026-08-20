# Instagram grid: automated sync — design note

**Status:** parked idea, not yet implemented or scheduled. Written up during
brainstorming on 2026-08-19 so the idea isn't lost; pick this back up when
ready to build it.

## Problem

The "Latest on Instagram" grid on Home (`src/data/instagram.json`,
rendered in `src/pages/index.astro`) is currently **manually curated** — no
API, no widget, nothing refreshes itself (see `MAINTENANCE.md` → "Update the
Instagram section"). That's a deliberate decision documented in the code
and in `instagram.json`'s own `_note` field: local images only, no
third-party script, no API token, and the section renders nothing rather
than show stale posts.

The ask: make the 6 posts update automatically as new posts go up on
@jmcconline, instead of requiring a manual edit every time.

## Chosen approach

Instagram Graph API + a scheduled GitHub Actions rebuild — **not** a
third-party embed widget, and not a PR-for-review flow. Fully automatic,
auto-committing to `master`.

Prerequisite already confirmed true: @jmcconline is a Business/Creator
account linked to a Facebook Page, with a Meta App already set up.

## Architecture

A new script, `scripts/fetch-instagram.mjs`, runs inside a new GitHub
Actions workflow (`instagram-sync.yml`) on a **daily** cron (plus
`workflow_dispatch` for manual runs). It calls the Instagram Graph API for
the latest media, downloads and crops images, and — only if everything
succeeds — overwrites `src/data/instagram.json` and
`src/assets/instagram/*`, then commits and pushes to `master`. That push
triggers the existing "Build and deploy" workflow unchanged; no separate
deploy logic needed.

## Data flow

- Fetch the top 6 items from `GET /{ig-user-id}/media` (photos directly;
  reels via `thumbnail_url`; carousels via the first `children` item).
- Reels (9:16) get cropped to 4:5 **from the top** via `sharp`, matching the
  existing manual convention (headline sits near the top). Photos get
  center-cropped/resized to the same 512×640 convention.
- Alt text: the Instagram `caption` field is copied into **both** `en` and
  `fr` fields as-is. (Known limitation, accepted trade-off: captions are
  marketing copy, not screen-reader descriptions, and are usually only in
  one language. Chosen over AI-generated alt text or a generic fallback
  for simplicity — no extra API calls, no review step.)
- All-or-nothing write: if any of the 6 fails to fetch/process, **nothing
  is touched** — the grid keeps showing the last successfully fetched 6
  posts rather than emptying or partially updating. This was chosen over
  literally following the current "stale is worse than none" philosophy,
  because a token hiccup or transient API error shouldn't blank the
  section on the homepage.
- Stale/removed images get pruned from `src/assets/instagram/` when no
  longer in the top 6.
- **Token refresh:** the long-lived IG access token (60-day expiry) is
  refreshed each run and written back to the `IG_ACCESS_TOKEN` GitHub
  secret via the REST API, using a separate fine-grained PAT
  (`GH_PAT_FOR_SECRETS`) — the default `GITHUB_TOKEN` cannot write repo
  secrets.

## Error handling

Any failure (bad token, API error, download failure, missing carousel
child) fails the Action run without committing anything. GitHub's default
failure-email to repo watchers is the alert mechanism. A fully
expired/revoked token needs manual re-auth — refreshing only extends a
still-valid token, it can't recover one that's already expired. Document
that recovery step when this gets built.

## Testing

- Unit tests for the crop math (top-crop for 9:16 input, center-crop for
  near-4:5 input) against fixture images.
- Integration test mocking Graph API responses, verifying
  `instagram.json` output shape and the all-or-nothing rollback path. No
  live API calls in CI.
- No automated e2e against a real Instagram account — verify manually via
  `workflow_dispatch` and checking the deployed homepage.

## Setup required before this can go live

Repo secrets to add:

- `IG_ACCESS_TOKEN` — initial long-lived token
- `IG_BUSINESS_ACCOUNT_ID`
- `GH_PAT_FOR_SECRETS` — fine-grained PAT scoped to this repo's secrets
  only, used to write back the refreshed token

## Docs to update when this ships

- `MAINTENANCE.md` → "Update the Instagram section" (currently documents
  this as the one manual recurring job — that becomes untrue)
- `src/pages/index.astro` comment at the Instagram grid (currently says
  "no third-party script, no API token")
- `src/data/instagram.json` → `_note` / `_schema` fields (currently
  describe manual curation)

## Options considered and rejected

- **Third-party embed widget** (SnapWidget, Behold, Elfsight): far less
  setup, no token management — but breaks the site's "no third-party
  script" rule, has free-tier limits/branding, and can't produce the
  hand-written bilingual alt text or top-cropped reel covers.
- **Semi-automated (fetch + auto-crop, hold for PR review):** keeps a
  human quality-control step on alt text, but reintroduces manual grunt
  work the automation was meant to remove. Rejected in favor of full auto.
