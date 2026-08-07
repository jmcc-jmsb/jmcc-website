# Hosting questions for CASA IT (Ryan)

Everything buildable without server access is done. These six answers unblock the rest.
**Question 1 first** — it is cheap to ask and expensive to discover late.

---

## 1. Are `.htaccess` overrides enabled? (`AllowOverride All`)

**Why it matters most:** the entire redirect strategy lives in `public/.htaccess` — the
canonical host, HTTPS forcing, all 11 blog post redirects, the Wix legacy paths, security
headers, and caching. If `AllowOverride` is restricted, none of it takes effect and the
rules have to move into the vhost config, which only CASA can edit.

Asking after cutover means discovering that every old link 404s in production.

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
(currently assumed `/home/jmcc/form-state`). The deploy runs `rsync --delete`, which would
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

## Two things to flag rather than ask

**Staging should be `staging.wecompete.ca`, not `staging.jmccjmsb.ca`.** Staging ought to
mirror production's domain so absolute URLs and any domain-sensitive behaviour act the
same. Either works technically.

**Staging must carry `noindex` on every page**, or it will compete with production in
search results. The site supports this, but the staging deploy has to set it.

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
