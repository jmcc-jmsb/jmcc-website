# ABOUTME: Verifies every .htaccess redirect, header, and error page against a running host.
# ABOUTME: Run: pwsh tests/check-redirects.ps1 -BaseUrl https://staging.wecompete.ca
#
# Takes a base URL so the same assertions run against the local Apache now and against
# staging and production later, unchanged. Needs a real Apache with mod_rewrite
# and AllowOverride enabled — PHP's built-in server ignores .htaccess entirely, so this
# will report everything as failing against `php -S`.

param(
    [Parameter(Mandatory = $true)][string]$BaseUrl,
    # Expected canonical origin. Redirect targets are compared against this.
    [string]$Canonical = "https://www.wecompete.ca"
)

$ErrorActionPreference = "Stop"
$BaseUrl = $BaseUrl.TrimEnd('/')
$pass = 0; $fail = 0

function Check($name, $condition, $detail = "") {
    if ($condition) { $script:pass++; "  PASS  $name" }
    else { $script:fail++; "  FAIL  $name  $detail" }
}

# Single request, no automatic following, so each hop can be inspected on its own.
function Hop($url) {
    try {
        $r = Invoke-WebRequest -Uri $url -MaximumRedirection 0 -UseBasicParsing -TimeoutSec 20 `
             -ErrorAction SilentlyContinue
        return @{ code = [int]$r.StatusCode; location = $r.Headers.Location; headers = $r.Headers }
    } catch {
        $resp = $_.Exception.Response
        if (-not $resp) { return @{ code = 0; location = $null; headers = @{} } }
        $loc = $resp.Headers["Location"]
        return @{ code = [int]$resp.StatusCode; location = $loc; headers = $resp.Headers }
    }
}

# Follows manually and counts hops, so a chain is visible rather than silently followed.
function Chain($url, $max = 6) {
    $hops = @(); $current = $url
    for ($i = 0; $i -lt $max; $i++) {
        $h = Hop $current
        $hops += $h
        if ($h.code -lt 300 -or $h.code -ge 400 -or -not $h.location) { break }
        $current = if ($h.location -match '^https?://') { $h.location } else { "$BaseUrl$($h.location)" }
    }
    return $hops
}

# path -> expected destination path
$LEGACY = [ordered]@{
    "/regionals"                        = "/competitions"
    "/nationals"                        = "/competitions"
    "/nationals-internationals"         = "/competitions"
    "/copy-of-nationals-internationals" = "/sponsors"
    "/about-3"                          = "/donate"
    "/our-team"                         = "/team"
    "/incident-form"                    = "/report"
    "/jdc-delegates"                    = "/portal"
    "/jdcc-delegates"                   = "/portal"
    "/hm-delegates"                     = "/portal"
    "/copy-of-hm-delegates"             = "/portal"
    "/hr-sympo-delegates"               = "/portal"
    "/comm299-recruitment"              = "/get-involved"
}

# All 11 archived posts, old slugs verbatim.
$POSTS = @(
    "how-jdcc-debate-works-and-the-four-voices-that-made-it-one",
    "jdcc-2026-from-the-captain-s-chair",
    "leadership-in-action-a-conversation-with-ally-boucher",
    "beyond-the-podium-lessons-from-lily-s-first-jdc-as-a-brand-ambassador",
    "what-recruiters-really-think-about-case-competitions",
    "bringing-home-7-podiums-in-36-hours-the-hr-sympo-story",
    "3-presentation-mistakes-that-kill-your-pitch-and-how-to-fix-them",
    "from-case-to-career-wynter-s-hm-success-story",
    "your-first-case-competition-a-complete-guide",
    "why-we-re-finally-sharing-the-jmcc-playbook"
)

"Target: $BaseUrl"
""

"== legacy Wix paths =="
foreach ($from in $LEGACY.Keys) {
    $to = $LEGACY[$from]
    $hops = Chain "$BaseUrl$from"
    $first = $hops[0]
    $last = $hops[-1]
    Check "$from -> $to is 301" ($first.code -eq 301) "got $($first.code)"
    Check "$from lands on $to" ($first.location -and ($first.location -replace '^https?://[^/]+', '') -match "^$([regex]::Escape($to))/?$") "-> $($first.location)"
    # One hop of redirect only. The final entry is the 200; anything more is a chain.
    # @() is load-bearing: a lone hashtable out of Where-Object reports .Count as its
    # number of keys, so an unwrapped single hop counts as 3 and never matches.
    Check "$from has no redirect chain" ((@($hops | Where-Object { $_.code -ge 300 -and $_.code -lt 400 })).Count -eq 1) `
        ("hops=" + (($hops | ForEach-Object { $_.code }) -join ">"))
}

""
"== archived blog posts =="
foreach ($slug in $POSTS) {
    $h = Hop "$BaseUrl/post/$slug"
    Check "/post/$($slug.Substring(0, [Math]::Min(38, $slug.Length)))... -> /blog" `
        ($h.code -eq 301 -and $h.location -match "/blog/$([regex]::Escape($slug))") "got $($h.code) $($h.location)"
}

"== the accented post, both encodings =="
foreach ($variant in @(
    "/post/from-montr%C3%A9al-to-melbourne-how-you-can-go-global-with-jmcc",
    # Parenthesised: inside an array literal the commas win, and an unbracketed
    # "a" + [char] + "b" becomes three separate elements instead of one string.
    ("/post/from-montr" + [char]0x00E9 + "al-to-melbourne-how-you-can-go-global-with-jmcc")
)) {
    $h = Hop "$BaseUrl$variant"
    Check "accented slug resolves ($($variant.Substring(0,28))...)" `
        ($h.code -eq 301 -and $h.location -match "from-montreal-to-melbourne") "got $($h.code) $($h.location)"
}

$h = Hop "$BaseUrl/blog/page/2"
Check "/blog/page/2 -> /blog" ($h.code -eq 301 -and $h.location -match "/blog/?$") "got $($h.code) $($h.location)"

""
"== canonical host and scheme =="
# Only meaningful against the real domains; skipped locally where the Host header differs.
if ($BaseUrl -match 'wecompete\.ca') {
    $h = Hop "https://wecompete.ca/who-we-are"
    Check "apex -> www in one hop" ($h.code -eq 301 -and $h.location -eq "$Canonical/who-we-are") "-> $($h.location)"
    $h = Hop "http://www.wecompete.ca/who-we-are"
    Check "http -> https in one hop" ($h.code -eq 301 -and $h.location -eq "$Canonical/who-we-are") "-> $($h.location)"
    $hops = Chain "http://wecompete.ca/who-we-are"
    Check "http+apex reaches canonical in ONE redirect" `
        ((@($hops | Where-Object { $_.code -ge 300 -and $_.code -lt 400 })).Count -eq 1) `
        ("hops=" + (($hops | ForEach-Object { $_.code }) -join ">"))
    $h = Hop "$Canonical/who-we-are"
    Check "canonical URL does not redirect (no loop)" ($h.code -eq 200) "got $($h.code)"
} else {
    "  SKIP  canonical host rules (only assertable against the real domain)"
}

""
"== error page =="
$h = Hop "$BaseUrl/this-page-does-not-exist-$(Get-Random)"
Check "unknown path returns 404" ($h.code -eq 404) "got $($h.code)"
try {
    $body = (Invoke-WebRequest -Uri "$BaseUrl/nope-$(Get-Random)" -UseBasicParsing -TimeoutSec 20).Content
} catch {
    # PowerShell has already drained the error response into ErrorDetails, so reading
    # the stream a second time returns nothing. This works on 5.1 and 7 alike.
    $body = $_.ErrorDetails.Message
}
Check "404 page is the branded one" ($body -match "This page doesn" -and $body -match "JMCC") "body did not match"

""
"== internal paths are not public =="
# The component gallery is built into dist/ because a static Astro build cannot omit a
# page. .htaccess is what actually keeps it off the public site, so assert it here
# rather than trusting the noindex meta tag alone.
foreach ($path in @("/dev/", "/dev/components/", "/dev/components/index.html")) {
    $h = Hop "$BaseUrl$path"
    Check "$path is not served" ($h.code -eq 404) "got $($h.code)"
}

""
"== headers =="
$h = Hop "$BaseUrl/"
$hdr = $h.headers
Check "X-Content-Type-Options: nosniff" ("$($hdr['X-Content-Type-Options'])" -eq "nosniff")
Check "Referrer-Policy set" ("$($hdr['Referrer-Policy'])" -eq "strict-origin-when-cross-origin")
Check "X-Frame-Options set" ("$($hdr['X-Frame-Options'])" -eq "DENY")
Check "CSP present" ("$($hdr['Content-Security-Policy'])".Length -gt 0)
Check "CSP allows the Google Forms embed" ("$($hdr['Content-Security-Policy'])" -match "frame-src[^;]*docs\.google\.com")
Check "HTML is revalidated, not cached hard" ("$($hdr['Cache-Control'])" -match "must-revalidate|max-age=0")

$asset = ([regex]::Match((Invoke-WebRequest "$BaseUrl/" -UseBasicParsing -TimeoutSec 20).Content, '/_astro/[^"]+\.css')).Value
if ($asset) {
    $h = Hop "$BaseUrl$asset"
    Check "hashed assets cached immutably" ("$($h.headers['Cache-Control'])" -match "immutable") "got $($h.headers['Cache-Control'])"
} else {
    "  SKIP  hashed asset cache header (no /_astro asset found on the page)"
}

""
"passed: $pass   failed: $fail"
if ($fail -gt 0) { exit 1 }
