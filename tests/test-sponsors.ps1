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

$json = Get-Content $data -Raw | ConvertFrom-Json

Copy-Item $data $backup -Force
try {
    "== the current lineup =="
    $r = Build
    Check "site builds" $r.ok $r.out
    $en = Read-Page "sponsors\index.html"
    $fr = Read-Page "fr\sponsors\index.html"
    # Astro inlines small stylesheets and links larger ones, so check both places.
    $css = $en + ((Get-ChildItem (Join-Path $repo "dist\_astro") -Filter *.css |
        ForEach-Object { [System.IO.File]::ReadAllText($_.FullName) }) -join "`n")

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

    "== logos =="
    # A logo filename that matches no file in src/assets/sponsors/ silently falls back
    # to the name, so assert each named logo actually became an image.
    foreach ($s in @($json.tiers.sponsors | Where-Object { $_.logo })) {
        Check "$($s.name) renders its logo" ($en -match "<img[^>]*alt=""$([regex]::Escape($s.name))""")
    }

    "== standard-tier logos are maroon until hovered =="
    # The tint wrapper carries the logo's own URL as its mask, so maroon takes its shape.
    $tinted = @([regex]::Matches($en, '<span[^>]*class="[^"]*logo-tint[^"]*"[^>]*>') | ForEach-Object { $_.Value })
    foreach ($tier in $json.tiers) {
        foreach ($s in @($tier.sponsors | Where-Object { $_.logo })) {
            $file = [regex]::Escape([System.IO.Path]::GetFileNameWithoutExtension($s.logo))
            $isTinted = @($tinted | Where-Object { $_ -match "--logo:\s*url\([^)]*$file" }).Count -eq 1
            if ($tier.prominence -eq 'large') {
                Check "$($s.name) ($($tier.label.en)) keeps its own colours" (-not $isTinted)
            } else {
                Check "$($s.name) ($($tier.label.en)) is tinted maroon" $isTinted
            }
        }
    }
    Check "the tint masks the brand maroon onto the logo" (
        $css -match 'logo-tint' -and $css -match 'mask' -and $css -match 'var\(--color-primary\)')
    # Touch screens cannot hover to reveal the colour, so the tint applies only where
    # hovering exists; a phone shows every logo in its own colours.
    Check "the tint only applies where hover exists" ($css -match '@media\s*\(hover:\s*hover\)[^@]*logo-tint')
    Check "keyboard focus reveals the colour too" ($css -match 'focus-visible[^{]*logo-tint')
    Check "no logo is greyscaled any more" (-not ($en -match '\bgrayscale\b'))

    "== a sponsor with no logo yet =="
    # Every sponsor without a logo file must still read as a name, never a broken image.
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
