# Hosting questions for CASA IT (Ryan)

All six questions are **answered** (2026-09-05 to 2026-09-14). Production has been live on
www.wecompete.ca since 2026-09-15, and jmccjmsb.ca moved off Wix on 2026-09-16 (see
*Cutover* below). This file is now the record of what CASA
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

jmccjmsb.ca's certificate (`jmccjmsb.ca` and `*.jmccjmsb.ca`) was already valid on the
server before its DNS moved here, so the cutover needed no AutoSSL run. It expires
2026-12-11; check that AutoSSL has renewed it before then.

---

## Cutover: moving jmccjmsb.ca off Wix

✅ **Done 2026-09-16.** Ryan confirmed we could change the DNS ourselves, so no notice
was needed. Production on wecompete.ca had been live since 2026-09-15.

What it took, in order:

1. **Document root.** jmccjmsb.ca is an *addon domain* in cPanel → Domains (no checkbox,
   and a `?` instead of its own Force HTTPS toggle). The merge had left its document root
   at `/jmccjmsb.ca/public_html`, a folder without our `.htaccess`, so the server answered
   jmccjmsb.ca with a bare Apache 403/404. It was changed to `/public_html` through
   **Manage → New Document Root**. Without this step, the DNS switch would have sent every
   old link to an error page.
2. **Test before touching DNS.** `--resolve` sends the request to our server while public
   DNS still points elsewhere:
   ```powershell
   curl.exe -sI --resolve "jmccjmsb.ca:443:34.225.86.76" https://jmccjmsb.ca/regionals
   ```
   Expect `Server: Apache`, `301` and `location: https://www.wecompete.ca/regionals`. A
   response with `x-wix-*` headers means the `--resolve` host did not match the URL
   exactly, and the request went to Wix.
3. **DNS.** cPanel → **Zone Editor** → jmccjmsb.ca. Only these two records changed; MX,
   SPF, DKIM, DMARC and Google verification were left alone.

   | Record | Before (Wix), the rollback values | After |
   |---|---|---|
   | `jmccjmsb.ca.` A | `185.230.63.107` | `34.225.86.76` |
   | `www.jmccjmsb.ca.` CNAME | `pointing.wixdns.net` | `jmccjmsb.ca` |

4. **Verified.** Google and Cloudflare resolvers returned the new records within minutes,
   and `tests/check-redirects.ps1 -BaseUrl https://www.wecompete.ca` passed 86/0.
   `.htaccess` rule A sends every jmccjmsb.ca request to `https://www.wecompete.ca` with
   its path, and the path rules take it from there.

Follow-ups:

- **Google Search Console, Change of address** from jmccjmsb.ca to wecompete.ca: started by
  Ryan on 2026-09-17. Both domains already carry verification records. Google asks
  for the redirects to stay for at least a year; keep the jmccjmsb.ca ones indefinitely.
- **Cancel the Wix plan:** handed to the previous VP Tech, who holds the Wix login, on
  2026-09-17. The domain is registered with Go Get Canada, not Wix, so cancelling does not
  touch it. The blog archive in the team Drive was confirmed up to date first (see
  MAINTENANCE.md → "The Wix archive").
- **HSTS** (`.htaccess` section 4): still to do, after about a week without problems on
  both domains, so not before 2026-09-23.

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
| DNS and SSL | us, in cPanel → Zone Editor (CASA IT set it up) | Points both domains at this server (jmccjmsb.ca since the cutover above); AutoSSL issues the certificates |
| Everything else | us, in `public/.htaccess` | jmccjmsb.ca → wecompete.ca, apex → www, http → https, and every path rewrite (`/regionals` → `/competitions/`, `/post/:slug` → `/blog/:slug/`, …) |

Because both domains now live in our account, a visitor on `jmccjmsb.ca/regionals`
reaches `https://www.wecompete.ca/competitions/` entirely through our `.htaccess`, in two
hops at most: domain first, then path.
