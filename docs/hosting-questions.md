# Hosting questions for CASA IT (Ryan)

Everything buildable without server access is done. Question 1 is **answered**; the five
below it are what still block the rest.

---

## 1. Are `.htaccess` overrides enabled? (`AllowOverride All`) — ✅ ANSWERED 2026-09-05

**CASA confirmed overrides are enabled.** `public/.htaccess` takes effect as written, so
nothing has to move into the vhost config.

That single answer is what makes the following actually work in production, rather than
being silently ignored: the canonical-host and HTTPS redirects, all 11 blog post
redirects, the Wix legacy paths, `ErrorDocument 404` (so the custom `/404.html` is served
instead of Apache's default), the caching rules, `Options -Indexes`, the `/dev` 404 block,
the `config.local.php` denial, and the whole security header set — CSP,
`X-Frame-Options`, `X-Content-Type-Options`, `Referrer-Policy`, `Permissions-Policy`.

Worth keeping in mind that this was the one dependency underneath all of them: had it
come back restricted, every header above would have been absent in production with no
error to notice it by.

**Still gated on question 6, not on this one:** HSTS stays commented out at
`.htaccess:117` until SSL is confirmed on *both* wecompete.ca and jmccjmsb.ca.

## 2. Is PHP run through the CloudLinux selector or mod_php?

The contact form is a single PHP 8.2 file with no Composer dependencies, so either works.
It changes two things worth knowing in advance: which `php.ini` applies, and whether
`mail()` is available or the host expects SMTP.

## 3. Does SPF for **wecompete.ca** authorise the cPanel server? Is DKIM available?

The contact form sends `From: website@wecompete.ca`. Now that the site and the mailbox are
both on wecompete.ca this is no longer a cross-domain send, which removes the main
deliverability risk — but SPF still has to list the sending server or mail lands in spam.

If DKIM is available, enabling it is worth the few minutes.

## 4. Confirmed document roots for production and staging

Needed for the rsync deploy target. Both, please — the deploy workflow takes them as
variables and cannot be finished without them.

Note: the form's writable state directory must sit **outside** the document root
(`/home/jmccjmsb/form-state`, matching the cPanel account name - please confirm). The deploy runs `rsync --delete`, which would
otherwise wipe the rate-limit counters and signing key on every deploy. Confirm that path
is writable by the PHP user.

## 5. SSH hostname and port, and how to add a deploy key

GitHub Actions deploys over rsync/SSH. We need the hostname, the port if it is not 22, and
the SSH username. We will generate a dedicated deploy keypair and send the public half —
no password ever needs to be shared.

Also useful: the server's SSH host key fingerprint, so the workflow can pin it rather than
trusting whatever answers on first connection.

## 6. Will SSL cover **both** wecompete.ca and jmccjmsb.ca?

cPanel AutoSSL should handle it, but confirm jmccjmsb.ca is included. If the legacy domain
has no valid certificate, a visitor with an old bookmark gets a browser security warning
**before** the redirect ever runs — which looks considerably worse than a dead link.

The staging subdomain needs a certificate too.

---

## Two things we flagged rather than asked - both now settled

**Staging should be `staging.wecompete.ca`, not `staging.jmccjmsb.ca`.** - RESOLVED
2026-09-12. wecompete.ca is now the main domain with jmccjmsb.ca pointing at it, so staging
belongs on the canonical domain where absolute URLs and domain-sensitive behaviour match
production.

One thing to check with Ryan before anyone revisits this: if the jmccjmsb.ca to
wecompete.ca redirect lives at the DNS or vhost layer rather than in `.htaccess`, it would
swallow `staging.jmccjmsb.ca` before Apache ever saw the request - making a staging
subdomain on the legacy domain unreachable rather than merely inadvisable.

**Staging must carry `noindex` on every page.** - IMPLEMENTED 2026-09-12. `.htaccess` sets
`X-Robots-Tag: noindex, nofollow` on any host beginning `staging.`, reusing the same
`^staging.` prefix the canonical-host rule already exempts.

Scoped by host rather than by a staging build on purpose: an env-var-driven noindex would
leave the live site one wrong artifact away from being deindexed, on a green deploy with
nothing visibly broken to notice it by. This rule can only ever match a `staging.*` host, so
the same artifact ships to both environments unchanged.

`robots.txt` is deliberately not swapped for staging - a crawler has to be able to fetch a
page to see the header, and disallowing would leave staging URLs eligible as bare links with
no snippet. `tests/check-redirects.ps1` asserts both directions: header present on a staging
host, absent on every other. See MAINTENANCE.md for running it.

---

## What we already handle, so nobody assumes otherwise

Redirects come in two layers and **each side only covers one**:

| Layer | Owner | Examples |
|---|---|---|
| Domain → server, SSL | CASA IT | Point wecompete.ca and jmccjmsb.ca at the right document root; 301 jmccjmsb.ca → wecompete.ca preserving the path |
| Path → path | us, in `public/.htaccess` | `/regionals` → `/competitions`, `/post/:slug` → `/blog/:slug`, `/about-3` → `/donate` |

A visitor hitting `jmccjmsb.ca/regionals` needs **both**: CASA's routing to land on the
server, and our rewrite to reach `/competitions`. Neither layer covers the other, so the
main risk is each side assuming the other handled the legacy paths.
