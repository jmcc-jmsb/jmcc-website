# ABOUTME: Checks every internal link in the built site points at a page's final URL, so a
# ABOUTME: click never costs a redirect, and that the nav still marks the current page.
#
# Run: pwsh tests/test-links.ps1   (builds the site once; needs no server)
#
# Every page builds to a folder (who-we-are/index.html), and Apache answers a slashless
# /who-we-are with a 301 to /who-we-are/. A link without the slash therefore works, but
# costs every visitor an extra round trip on every click — invisible unless tested.

$ErrorActionPreference = "Stop"
$repo = Split-Path $PSScriptRoot -Parent
$dist = Join-Path $repo "dist"
$pass = 0; $fail = 0

function Check($name, $condition, $detail = "") {
    if ($condition) { $script:pass++; "  PASS  $name" }
    else { $script:fail++; "  FAIL  $name  $detail" }
}

function Read-Page($relative) {
    [System.IO.File]::ReadAllText((Join-Path $dist $relative))
}

Push-Location $repo
try {
    # A failing build writes to stderr; keep it from throwing so the check below reports it.
    $ErrorActionPreference = "Continue"
    $out = npm run build 2>&1 | Out-String
    $built = $LASTEXITCODE -eq 0
    $ErrorActionPreference = "Stop"
} finally { Pop-Location }

"== build =="
Check "site builds" $built $out
if (-not $built) { ""; "passed: $pass   failed: $fail"; exit 1 }

""
"== internal links =="
$pages = Get-ChildItem $dist -Recurse -Filter *.html
$links = 0
$offenders = @{}
foreach ($page in $pages) {
    $html = [System.IO.File]::ReadAllText($page.FullName)
    # Root-relative only: absolute URLs (canonical, hreflang, external) and protocol-
    # relative //host links are not ours to route.
    foreach ($m in [regex]::Matches($html, 'href="(/(?!/)[^"]*)"')) {
        $links++
        $path = ($m.Groups[1].Value -split '[?#]', 2)[0]
        # A trailing slash is the folder's final URL; an extension is a real file.
        if ($path.EndsWith('/') -or $path -match '\.[A-Za-z0-9]+$') { continue }
        $from = $page.FullName.Substring($dist.Length).Replace('\', '/')
        if (-not $offenders.ContainsKey($path)) { $offenders[$path] = $from }
    }
}
# Guards against the check passing vacuously if the href pattern ever stops matching.
Check "found internal links to check" ($links -gt 100) "only $links"
$list = ($offenders.Keys | Sort-Object | Select-Object -First 15 |
         ForEach-Object { "$_ (e.g. on $($offenders[$_]))" }) -join "; "
Check "no internal link needs a redirect" ($offenders.Count -eq 0) "$($offenders.Count) slashless: $list"

$homePage = Read-Page "index.html"
Check "home links the French home at its final URL" ($homePage -match 'href="/fr/"')
$comps = Read-Page "competitions\index.html"
Check "a link with a query string keeps the slash before the ?" ($comps -match 'href="/trophy-cabinet/\?competition=')

""
"== the nav still marks the current page =="
# aria-current sits on the top-level item: the page's own, or the parent of a child page.
$current = 'href="{0}"[^>]*aria-current="page"'
Check "a top-level page marks its own item" ((Read-Page "who-we-are\index.html") -match ($current -f '/who-we-are/'))
Check "a child page marks its parent" ((Read-Page "team\index.html") -match ($current -f '/who-we-are/'))
Check "a French page marks its French item" ((Read-Page "fr\competitions\index.html") -match ($current -f '/fr/competitions/'))

""
"passed: $pass   failed: $fail"
if ($fail -gt 0) { exit 1 }
