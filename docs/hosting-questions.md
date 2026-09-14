# Hosting questions for CASA IT (Ryan)

All six questions are **answered** (2026-09-05 to 2026-09-14), and staging is deployed and
passing `tests/check-redirects.ps1` live. This file is now the record of what CASA
confirmed and what each answer means for us. If a new question comes up, add it at the
bottom and send the file as-is.

---

## The setup at a glance

| Item | Value |
|---|---|
| cPanel account | `jmccjmsb`. wecompete.ca is its **main domain**; jmccjmsb.ca points at it |
| Server and SSH | `www2.casajmsb.net`, port 22, user `jmccjmsb` |
| SSH host key | RSA `SHA256:pTYFHSka8zmZ+K6ojtI35remKk4qVelvYXYvFlXZv2k`, confirmed by Ryan and pinned in `CPANEL_KNOWN_HOSTS` |
| Production document root | `/home/jmccjmsb/public_html` |
| Staging document root | `/home/jmccjmsb/staging.jmccjmsb.ca`. It serves staging.wecompete.ca; the folder kept its old name, which is harmless |
| Form state | `/home/jmccjmsb/form-state` (production), `/home/jmccjmsb/staging-form-state` (staging) |
| PHP | CloudLinux selector, `mail()` available |
| PHP error log | `/home/jmccjmsb/logs/php.error.log`, set by cPanel. See MAINTENANCE.md → "Files cPanel keeps in the document root" |
| DNS | This account's cPanel **Zone Editor**, for both domains (nameservers `ns1`/`ns2.casajmsb.net`) |

## 1. Are `.htaccess` overrides enabled? (`AllowOverride All`) — ✅ Yes, 2026-09-05

`public/.htaccess` takes effect as written, so nothing has to move into the vhost config.

This was the one dependency underneath the canonical-host and HTTPS redirects, all the
blog and Wix redirects, `ErrorDocument 404`, the caching rules, `Options -Indexes`, the
file denials and the whole security header set. Had it come back restricted, every one
of them would have been absent in production with no error to notice it by.

## 2. CloudLinux selector or mod_php? — ✅ CloudLinux selector, 2026-09-13

Either works; the CloudLinux selector is the default and the better choice. `mail()` is
available. (Ryan also offered a Gmail API service account for more control over sending;
not needed.) `php.ini` files load per domain and `.user.ini` works per directory, but for
any INI change Ryan would rather set it server-wide, so ask him first.

## 3. SPF and DKIM for wecompete.ca — ✅ Covered, 2026-09-13

wecompete.ca's SPF includes `_spf.casajmsb.ca`, which lists the server's IP. `contact.php`
sends with `-f website@wecompete.ca`, so SPF both passes and aligns with the From domain —
enough for DMARC on its own. DKIM is signed automatically for `mail()`. DMARC is
`p=reject`.

⚠ wecompete.ca has **one** SPF record (`_spf.casajmsb.ca` plus HubSpot). A new sender on
the bare domain must be merged into it, never added as a second record. Ryan's email
mentioned `_spf.casajmsb.net` once; that name does not exist, and `_spf.casajmsb.ca` is
correct. DMARC's `sp=reject` covers subdomains too, so a new sending subdomain needs its
DKIM record in place before its first send.

## 4. Document roots for production and staging — ✅ 2026-09-13

wecompete.ca used to sit on a separate cPanel account from before the Wix migration.
That account was absorbed into `jmccjmsb`, which made wecompete.ca the main domain. Its
DNS zone came across intact: Workspace MX, both DKIM keys, DMARC, the SPF record and
Google site verification.

The roots are in the table above. They are the `CPANEL_DEPLOY_PATH` variables on the
`production` and `staging` GitHub environments. The PHP user owns everything under
`/home/jmccjmsb`, so both state directories are writable.

## 5. SSH hostname, port and deploy key — ✅ 2026-09-13, key replaced 2026-09-14

Connection details and the host key fingerprint are in the table above. The first deploy
key's GitHub secret turned out to be unreadable. It was replaced on 2026-09-14 with a new
key, `jmcc-deploy`, which we imported ourselves through cPanel → SSH Access, so no CASA
involvement was needed. See MAINTENANCE.md → "Rotating the deploy key".

rsync was **not** available to the account at first (`bash: rsync: command not found`).
CASA enabled it on 2026-09-14. If a deploy ever fails with that error again, ask CASA to
re-enable rsync for `jmccjmsb` (CageFS).

## 6. Will SSL cover both domains and staging? — ✅ AutoSSL, 2026-09-13

AutoSSL covers all of them. wecompete.ca already has a certificate for `wecompete.ca`
and `*.wecompete.ca`, which covers www and staging.

⚠ jmccjmsb.ca still points at Wix. When its DNS moves here, its certificate is invalid
until AutoSSL's next run, so ask Ryan to trigger one right after the switch. HSTS
(`.htaccess` section 4) stays off until that certificate is live.

---

## Cutover: moving jmccjmsb.ca off Wix

- Give Ryan **at least 3 days' notice, a week preferred**. He schedules it at a time we pick.
- Do it only after production on wecompete.ca is confirmed working.
- Once jmccjmsb.ca resolves here, `.htaccess` rule A sends every request to
  `https://www.wecompete.ca` with its path, and the path rules take it from there. Both
  domains are in our account, so no redirect is needed on CASA's side.
- Afterwards: AutoSSL run, then HSTS, then Google Search Console → **Change of address**
  from jmccjmsb.ca to wecompete.ca. Both domains already carry verification records.

## Keep cPanel's "Force HTTPS Redirect" off

It is off and must stay off. `.htaccess` does http → https itself in one hop. cPanel's
toggle would fire first and add a second hop on every legacy link, which
`check-redirects.ps1` would flag.

## Staging decisions — settled

**Staging is `staging.wecompete.ca`, not `staging.jmccjmsb.ca`** (2026-09-12), so absolute
URLs and domain-sensitive behaviour match production.

**Staging carries `noindex` on every page.** `.htaccess` sets
`X-Robots-Tag: noindex, nofollow` on any host beginning `staging.`, reusing the prefix the
canonical-host rule already exempts. It is scoped by host rather than by a staging build
on purpose: an env-var-driven noindex would leave the live site one wrong artifact away
from being deindexed, on a green deploy with nothing visibly broken. `robots.txt` is
deliberately not swapped for staging, because a crawler has to fetch a page to see the
header. `tests/check-redirects.ps1` asserts both directions.

---

## Who owns which redirect

| Layer | Owner | What |
|---|---|---|
| DNS and SSL | CASA IT | Points both domains at this server (jmccjmsb.ca only from the cutover above); AutoSSL issues the certificates |
| Everything else | us, in `public/.htaccess` | jmccjmsb.ca → wecompete.ca, apex → www, http → https, and every path rewrite (`/regionals` → `/competitions/`, `/post/:slug` → `/blog/:slug/`, …) |

Because both domains now live in our account, a visitor on `jmccjmsb.ca/regionals`
reaches `https://www.wecompete.ca/competitions/` entirely through our `.htaccess`, in two
hops at most: domain first, then path.
