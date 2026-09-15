# ABOUTME: Fails if an em dash reaches anything a visitor can see: pages, titles, meta tags,
# ABOUTME: alt text, robots.txt, or the contact form's replies. The archived blog is exempt.
#
# Run: pwsh tests/test-em-dashes.ps1   (builds the site once; needs no server)
#
# House style since 2026-09-15: no em dashes in site copy. Sentences use a comma, colon,
# period or parentheses instead, and page titles use " | " as their separator. The hidden
# blog keeps its archived authors' punctuation (MAINTENANCE.md, "Do not modernize
# archived copy"), so dist/blog/ and dist/fr/blog/ are not scanned.

$ErrorActionPreference = "Stop"
$repo = Split-Path $PSScriptRoot -Parent
$dist = Join-Path $repo "dist"
$pass = 0; $fail = 0
# U+2014, plus the two entity spellings an HTML file could carry it in.
$emDash = [string][char]0x2014
$pattern = [regex]::Escape($emDash) + '|&mdash;|&#8212;|&#x2014;'

function Check($name, $condition, $detail = "") {
    if ($condition) { $script:pass++; "  PASS  $name" }
    else { $script:fail++; "  FAIL  $name  $detail" }
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

function Relative($path) { $path.Substring($dist.Length).Replace('\', '/') }

""
"== pages and served text files =="
$blog = '^/(fr/)?blog/'
$files = Get-ChildItem $dist -Recurse -File -Include *.html, *.xml, *.txt, *.json, *.js, *.css, *.webmanifest |
    Where-Object { (Relative $_.FullName) -notmatch $blog }
$hits = @()
foreach ($f in $files) {
    $text = [System.IO.File]::ReadAllText($f.FullName)
    foreach ($m in [regex]::Matches($text, $pattern)) {
        $start = [Math]::Max(0, $m.Index - 50)
        $snippet = $text.Substring($start, [Math]::Min(100, $text.Length - $start)) -replace '\s+', ' '
        $hits += "$(Relative $f.FullName): ...$snippet..."
    }
}
Check "scanned the built site" ($files.Count -gt 30) "only $($files.Count) files"
Check "no em dash on any page outside the blog" ($hits.Count -eq 0) "$($hits.Count) found"
$hits | Select-Object -First 40 | ForEach-Object { "        $_" }

""
"== the contact form's replies =="
# The endpoint's messages are PHP string literals, shown to the visitor after a submit.
# Comments never leave the server, so only code lines count.
$php = @()
foreach ($f in Get-ChildItem (Join-Path $dist "api") -Filter *.php) {
    $n = 0
    foreach ($line in [System.IO.File]::ReadAllLines($f.FullName)) {
        $n++
        $code = ($line -replace '^\s*(//|#|\*|/\*).*$', '') -replace '\s//\s.*$', ''
        if ($code -match $pattern) { $php += "$($f.Name):$n  $($line.Trim())" }
    }
}
Check "no em dash in a message the endpoint sends" ($php.Count -eq 0) "$($php.Count) found"
$php | ForEach-Object { "        $_" }

""
"passed: $pass   failed: $fail"
if ($fail -gt 0) { exit 1 }
