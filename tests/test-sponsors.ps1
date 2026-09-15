# ABOUTME: Tests for the sponsors page — tiers render in order in both languages, a sponsor
# ABOUTME: without a logo falls back to its name, and moreToAnnounce drives the "more soon" line.
#
# Run: pwsh tests/test-sponsors.ps1   (builds the site twice; needs no server)
#
# The lineup changes through the year as sponsors sign, so "more partners soon" is an
# explicit flag in sponsors.json rather than something inferred from the data.

$ErrorActionPreference = "Stop"
$repo = Split-Path $PSScriptRoot -Parent
$data = Join-Path $repo "src\data\sponsors.json"
$backup = Join-Path ([System.IO.Path]::GetTempPath()) "sponsors.json.bak"
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
    [System.IO.File]::ReadAllText((Join-Path $repo "dist\$relative"))
}

# The tier headings, in page order, from the <h2>s inside the sponsor section.
function Tier-Headings($html) {
    $section = [regex]::Match($html, '(?s)<section class="bg-cream py-24.*?</section>').Value
    [regex]::Matches($section, '(?s)<h2[^>]*>\s*(.*?)\s*</h2>') | ForEach-Object { $_.Groups[1].Value }
}

$moreSoonEn = 'more partners will be announced soon'
$moreSoonFr = 'autres partenaires seront annonc'

Copy-Item $data $backup -Force
try {
    "== the current lineup =="
    $r = Build
    Check "site builds" $r.ok $r.out
    $en = Read-Page "sponsors\index.html"
    $fr = Read-Page "fr\sponsors\index.html"

    Check "tiers render in order" (((Tier-Headings $en) -join " | ") -eq "Title Sponsor | Gold | Bronze") `
        ("got: " + ((Tier-Headings $en) -join " | "))
    Check "French tiers render in order" (((Tier-Headings $fr) -join " | ") -eq "Commanditaire en titre | Or | Bronze") `
        ("got: " + ((Tier-Headings $fr) -join " | "))
    foreach ($name in "VA Capital", "Ardian", "Scotiabank", "Fidelity", "Accenture", "KPMG") {
        Check "$name is on the page" ($en -match [regex]::Escape($name))
    }
    Check "sponsors link out in a new tab" ($en -match 'href="https://www\.fidelity\.ca/"[^>]*target="_blank"')
    Check "no placeholder text leaks onto the page" (-not ($en -match 'TODO'))
    Check "moreToAnnounce: true shows the line" ($en -match $moreSoonEn)
    Check "moreToAnnounce: true shows the French line" ($fr -match $moreSoonFr)

    "== a sponsor with no logo yet =="
    # Every sponsor without a logo file must still read as a name, never a broken image.
    $json = Get-Content $data -Raw | ConvertFrom-Json
    $noLogo = @($json.tiers.sponsors | Where-Object { -not $_.logo })
    foreach ($s in $noLogo) {
        Check "$($s.name) falls back to its name" ($en -match ">\s*$([regex]::Escape($s.name))\s*</span>")
    }
    if ($noLogo.Count -eq 0) { "  SKIP  every sponsor has a logo" }

    "== a finished lineup =="
    $text = [System.IO.File]::ReadAllText($data)
    [System.IO.File]::WriteAllText($data, ($text -replace '"moreToAnnounce":\s*true', '"moreToAnnounce": false'), $noBom)
    $r = Build
    Check "site builds with moreToAnnounce: false" $r.ok $r.out
    Check "moreToAnnounce: false hides the line" (-not ((Read-Page "sponsors\index.html") -match $moreSoonEn))
    Check "moreToAnnounce: false hides the French line" (-not ((Read-Page "fr\sponsors\index.html") -match $moreSoonFr))
}
finally {
    Copy-Item $backup $data -Force
    Remove-Item $backup -Force -ErrorAction SilentlyContinue
    # dist/ is left holding the last test build; the next `npm run build` overwrites it.
}

""
"passed: $pass   failed: $fail"
if ($fail -gt 0) { exit 1 }
