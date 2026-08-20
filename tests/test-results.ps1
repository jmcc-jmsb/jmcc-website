# ABOUTME: Tests for the trophy cabinet data layer — a bad slug must fail the build, and
# ABOUTME: a good season must render the cabinet, the home strip and the cross-links.
#
# Run: pwsh tests/test-results.ps1   (builds the site twice; needs no server)
#
# The point of the first case is the failure itself. results.json is edited once a year
# by whoever holds VP Academics, and a competition slug that quietly stops matching would
# otherwise show up as an empty filter nobody notices for a season.

$ErrorActionPreference = "Stop"
$repo = Split-Path $PSScriptRoot -Parent
$data = Join-Path $repo "src\data\results.json"
$backup = Join-Path ([System.IO.Path]::GetTempPath()) "results.json.bak"
$pass = 0; $fail = 0
$noBom = New-Object System.Text.UTF8Encoding $false

function Check($name, $condition, $detail = "") {
    if ($condition) { $script:pass++; "  PASS  $name" }
    else { $script:fail++; "  FAIL  $name  $detail" }
}

function Build {
    # Function-scoped: a failing build writes to stderr, which Windows PowerShell wraps
    # in ErrorRecords. Under the script's ErrorActionPreference=Stop that would throw
    # instead of returning — and the failing build is what half these cases assert.
    $ErrorActionPreference = "Continue"
    Push-Location $repo
    try { $out = npm run build 2>&1 | Out-String } finally { Pop-Location }
    return @{ ok = ($LASTEXITCODE -eq 0); out = $out }
}

Copy-Item $data $backup -Force
try {
    "== unmatched slug fails the build =="
    [System.IO.File]::WriteAllText($data, @'
{
  "seasons": [
    { "season": "2025-2026", "results": [
      { "competition": "not-a-real-competition", "discipline": "finance", "placement": 1 }
    ] }
  ]
}
'@, $noBom)
    $r = Build
    Check "build fails on an unmatched competition slug" (-not $r.ok)
    Check "the error names the offending slug" ($r.out -match "not-a-real-competition")

    [System.IO.File]::WriteAllText($data, @'
{
  "seasons": [
    { "season": "2025-2026", "results": [
      { "competition": "jeux-du-commerce", "discipline": "finance", "placement": 7 }
    ] }
  ]
}
'@, $noBom)
    $r = Build
    Check "build fails on a placement that is not 1-3, finalist or honourable" (-not $r.ok)

    "== a real season renders =="
    # tubc carries its edition year in competitions.json (tubc-2026); results reference
    # the competition, not the edition, so this also covers the year-stripped match.
    [System.IO.File]::WriteAllText($data, @'
{
  "seasons": [
    { "season": "2025-2026", "photo": "foPodiumTrophy", "results": [
      { "competition": "financial-open", "discipline": "corporate-finance", "placement": 1 },
      { "competition": "jeux-du-commerce", "discipline": "marketing", "placement": 2 },
      { "competition": "tubc", "placement": 3 },
      { "competition": "jeux-du-commerce", "discipline": "finance", "placement": "finalist" }
    ] },
    { "season": "2024-2025", "results": [
      { "competition": "jeux-du-commerce", "discipline": "accounting", "placement": 1 }
    ] }
  ]
}
'@, $noBom)
    $r = Build
    Check "build succeeds on valid data" $r.ok $r.out

    $cabinet = [System.IO.File]::ReadAllText((Join-Path $repo "dist\trophy-cabinet\index.html"))
    $homePage = [System.IO.File]::ReadAllText((Join-Path $repo "dist\index.html"))
    $comps = [System.IO.File]::ReadAllText((Join-Path $repo "dist\competitions\index.html"))
    $disc = [System.IO.File]::ReadAllText((Join-Path $repo "dist\disciplines\index.html"))
    $frCabinet = [System.IO.File]::ReadAllText((Join-Path $repo "dist\fr\trophy-cabinet\index.html"))

    Check "every result is on the page" (([regex]::Matches($cabinet, 'data-result\s')).Count -eq 5)
    Check "only the newest season opens by default" (([regex]::Matches($cabinet, '<details open')).Count -eq 1)
    # 4 podiums (the finalist does not count), 2 golds, 3 competitions, 2 seasons —
    # every one of them counted from the data, never typed into the page.
    Check "summary band is computed from the data" (
        (([regex]::Matches($cabinet, 'data-target="(\d+)"') | ForEach-Object { $_.Groups[1].Value }) -join ",") -eq "4,2,3,2")
    Check "finalist renders without a medal fill" ($cabinet -match 'border border-cream/40[^>]*>\s*Finalist')
    Check "FR route renders the same results in French" (
        $frCabinet -match 'Palmar' -and ([regex]::Matches($frCabinet, 'data-result\s')).Count -eq 5)

    # -cmatch, not -match: the section's own HTML comment ("Most recent podiums") survives
    # into the output, and a case-insensitive test would match it whether or not the
    # strip rendered — which is exactly the assertion below.
    Check "home strip shows the newest season's podiums" ($homePage -cmatch 'Most Recent Podiums')
    Check "home strip leaves out non-podium results" (-not ($homePage -match 'Finalist'))
    Check "competition card shows its podium count" ($comps -match '\d+ podiums? since \d{4}')
    Check "competition card links into the filtered cabinet" (
        $comps -match 'trophy-cabinet\?competition=tubc')
    Check "discipline links carry both filters" (
        $disc -match 'trophy-cabinet\?competition=jeux-du-commerce&amp;discipline=marketing')

    "== an empty file hides the feature =="
    [System.IO.File]::WriteAllText($data, '{ "seasons": [] }', $noBom)
    $r = Build
    $homePage = [System.IO.File]::ReadAllText((Join-Path $repo "dist\index.html"))
    $cabinet = [System.IO.File]::ReadAllText((Join-Path $repo "dist\trophy-cabinet\index.html"))
    Check "build succeeds with no results" $r.ok
    Check "home strip is absent" (-not ($homePage -cmatch 'Most Recent Podiums'))
    Check "cabinet holds a coming-soon state instead" ($cabinet -match 'Being compiled')
    Check "empty cabinet is noindexed" ($cabinet -match 'name="robots" content="noindex')
}
finally {
    Copy-Item $backup $data -Force
    Remove-Item $backup -Force -ErrorAction SilentlyContinue
    # dist/ is left holding the last test build; the next `npm run build` overwrites it.
}

""
"passed: $pass   failed: $fail"
if ($fail -gt 0) { exit 1 }
