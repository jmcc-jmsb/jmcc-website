# ABOUTME: Tests for the /newsletter page as built: the form, its CASL consent, the CSP that lets it
# ABOUTME: reach HubSpot, and the mailing-list buttons that lead to it once recruitment closes.
#
# Run: pwsh tests/test-newsletter.ps1   (builds the site twice; needs no server)
#
# The sign-up logic itself (validation, the payload, HubSpot's replies) is unit-tested in
# tests/newsletter.test.ts. This checks what ships: the page, the header, the links.

$ErrorActionPreference = "Stop"
$repo = Split-Path $PSScriptRoot -Parent
$data = Join-Path $repo "src\data\site.json"
$backup = Join-Path ([System.IO.Path]::GetTempPath()) "site.json.bak"
$pass = 0; $fail = 0
$noBom = New-Object System.Text.UTF8Encoding $false

function Check($name, $condition, $detail = "") {
    if ($condition) { $script:pass++; "  PASS  $name" }
    else { $script:fail++; "  FAIL  $name  $detail" }
}

function Build {
    # A failing build writes to stderr; keep it from throwing so the check reports it.
    $ErrorActionPreference = "Continue"
    Push-Location $repo
    try { $out = npm run build 2>&1 | Out-String } finally { Pop-Location }
    return @{ ok = ($LASTEXITCODE -eq 0); out = $out }
}

function Read-Page($relative) {
    $path = Join-Path $repo "dist\$relative"
    if (-not (Test-Path $path)) { return "" }
    [System.IO.File]::ReadAllText($path)
}

# The opening tag of the first element matching a name attribute, so attribute order
# in the markup does not matter to the assertions.
function Input-Tag($html, $name) {
    [regex]::Match($html, "<input[^>]*name=""$([regex]::Escape($name))""[^>]*>").Value
}

$json = Get-Content $data -Raw -Encoding utf8 | ConvertFrom-Json
$nl = $json.newsletter

Copy-Item $data $backup -Force
try {
    "== the page =="
    $r = Build
    Check "site builds" $r.ok $r.out
    $en = Read-Page "newsletter\index.html"
    $fr = Read-Page "fr\newsletter\index.html"
    Check "/newsletter/ is built" ($en -ne "")
    Check "/fr/newsletter/ is built" ($fr -ne "")
    Check "French page is in French" ($fr -match '<html lang="fr"')

    Check "site.json names the HubSpot form" ($nl.portalId -and $nl.formGuid -and $nl.subscriptionTypeId) "newsletter: $($nl | ConvertTo-Json -Compress)"
    Check "form carries the portal ID" ($en -match "data-portal-id=""$($nl.portalId)""")
    Check "form carries the form GUID" ($en -match "data-form-guid=""$($nl.formGuid)""")
    Check "form carries the subscription type ID" ($en -match "data-subscription-type-id=""$($nl.subscriptionTypeId)""")

    foreach ($page in @(@{ lang = "EN"; html = $en }, @{ lang = "FR"; html = $fr })) {
        $h = $page.html; $l = $page.lang
        Check "${l}: first name field" ((Input-Tag $h "firstname") -match 'autocomplete="given-name"')
        Check "${l}: last name field" ((Input-Tag $h "lastname") -match 'autocomplete="family-name"')
        $email = Input-Tag $h "email"
        Check "${l}: email field is type=email and required" ($email -match 'type="email"' -and $email -match '\brequired\b') $email
        $consent = Input-Tag $h "consent"
        Check "${l}: consent is a required checkbox" ($consent -match 'type="checkbox"' -and $consent -match '\brequired\b') $consent
        # CASL: consent must be an active opt-in, never a pre-ticked box.
        Check "${l}: consent box starts unticked" (-not ($consent -match '\bchecked\b')) $consent
        Check "${l}: honeypot field is present" ((Input-Tag $h "website") -match 'tabindex="-1"')
        Check "${l}: links to the privacy policy" ($h -match 'href="(/fr)?/privacy/"')
        Check "${l}: form never posts anywhere by itself" (-not ($h -match '<form[^>]*id="newsletter-form"[^>]*action=')) "a no-JS submit would go nowhere useful"
    }
    Check "EN consent names the sender and the unsubscribe" ($en -match 'John Molson Competition Committee' -and $en -match 'unsubscribe')
    Check "FR consent names the sender and the unsubscribe" ($fr -match 'Comit' -and $fr -match 'sabonner')

    "== the privacy policy describes the form as it now works =="
    $privacyEn = Read-Page "privacy\index.html"
    $privacyFr = Read-Page "fr\privacy\index.html"
    Check "EN policy no longer calls the sign-up a HubSpot-hosted page" (-not ($privacyEn -match 'not part of this website'))
    Check "FR policy no longer calls the sign-up a HubSpot-hosted page" (-not ($privacyFr -match 'ne fait pas partie de ce site'))
    Check "EN policy says the browser sends the sign-up to HubSpot" ($privacyEn -match 'directly to <a[^>]*>HubSpot</a>')
    Check "FR policy says the browser sends the sign-up to HubSpot" ($privacyFr -match 'directement \S{1,8} <a[^>]*>HubSpot</a>')

    "== the security policy lets the form reach HubSpot, and nothing else =="
    $csp = [regex]::Match([System.IO.File]::ReadAllText((Join-Path $repo "public\.htaccess")), 'Content-Security-Policy "([^"]*)"').Groups[1].Value
    Check "connect-src allows api.hsforms.com" ($csp -match "connect-src 'self' https://api\.hsforms\.com;") $csp
    Check "form-action is still 'self' only" ($csp -match "form-action 'self';") $csp
    Check "script-src loads nothing from HubSpot" (-not ([regex]::Match($csp, 'script-src[^;]*').Value -match 'hs')) $csp

    "== recruitment closed: the buttons lead to /newsletter/ =="
    $text = [System.IO.File]::ReadAllText($data)
    [System.IO.File]::WriteAllText($data, ($text -replace '"recruitmentOpen":\s*true', '"recruitmentOpen": false'), $noBom)
    $r = Build
    Check "site builds with recruitmentOpen: false" $r.ok $r.out
    foreach ($p in @(
        @{ page = "get-involved\index.html"; href = "/newsletter/" },
        @{ page = "fr\get-involved\index.html"; href = "/fr/newsletter/" },
        @{ page = "index.html"; href = "/newsletter/" },
        @{ page = "fr\index.html"; href = "/fr/newsletter/" }
    )) {
        $link = [regex]::Match((Read-Page $p.page), "<a[^>]*href=""$([regex]::Escape($p.href))""[^>]*>").Value
        Check "$($p.page) links to $($p.href)" ($link -ne "")
        Check "$($p.page) opens it in the same tab" (-not ($link -match 'target="_blank"')) $link
    }
    # Checked here, not on the first build: the mailing-list buttons only render while
    # recruitment is closed, so that is when a stale link would show up.
    $stale = @(Get-ChildItem (Join-Path $repo "dist") -Recurse -Filter *.html |
        Where-Object { [System.IO.File]::ReadAllText($_.FullName) -match '\.share(-\w+)?\.hsforms\.com' } |
        ForEach-Object { $_.FullName.Substring($repo.Length) })
    Check "no page links to HubSpot's hosted form" ($stale.Count -eq 0) ($stale -join ", ")
}
finally {
    Copy-Item $backup $data -Force
    Remove-Item $backup -Force -ErrorAction SilentlyContinue
    # dist/ is left holding the last test build; the next `npm run build` overwrites it.
}

""
"passed: $pass   failed: $fail"
if ($fail -gt 0) { exit 1 }
