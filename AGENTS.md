## Domain

Canonical: **`https://www.wecompete.ca`** (`www`, not the apex). Set once in
`astro.config.mjs → site`; every absolute URL derives from it. Never hardcode a hostname
in a component or page.

`jmccjmsb.ca` is **legacy redirect only** — it 301s to wecompete.ca preserving the path.
Do not write it into copy, links, or config. See `MAINTENANCE.md` for which redirect
layer CASA IT owns and which is ours.

## Color tokens

| Token     | Hex       | Usage                                                        |
|-----------|-----------|---------------------------------------------------------------|
| `primary` | `#680009` | Brand maroon — backgrounds, primary buttons                   |
| `cream`   | `#f7f3ec` | Light background                                               |
| `ink`     | `#000000` | Dark background, body text on cream                            |
| `border`  | `#95323f` | Borders, dividers                                              |
| `gold`    | `#fabb20` | Dark-background-only — text on `primary`/`ink`, `cta` button fill |
| `sand`    | `#d8af74` | Dark-background-only — text on `primary`/`ink`                 |
| `muted`   | `#5e5c5a` | Muted/secondary text on light (`cream`) backgrounds             |

**Rule:** `sand` and `gold` are dark-background-only. They may be used as text on `primary` or `ink` backgrounds, or as background fills (e.g. the gold `cta` button). Never use them as text on `cream` or other light backgrounds — use `muted` instead.

## Development

When starting the dev server, use background mode:

```
astro dev --background
```

Manage the background server with `astro dev stop`, `astro dev status`, and `astro dev logs`.

## Documentation

Full documentation: https://docs.astro.build

Consult these guides before working on related tasks:

- [Adding pages, dynamic routes, or middleware](https://docs.astro.build/en/guides/routing/)
- [Working with Astro components](https://docs.astro.build/en/basics/astro-components/)
- [Using React, Vue, Svelte, or other framework components](https://docs.astro.build/en/guides/framework-components/)
- [Adding or managing content](https://docs.astro.build/en/guides/content-collections/)
- [Adding styles or using Tailwind](https://docs.astro.build/en/guides/styling/)
- [Supporting multiple languages](https://docs.astro.build/en/guides/internationalization/)
