# ABOUTME: Round-trip tests for public/api/contact.php — spam, validation, and message content.
# ABOUTME: Run: pwsh tests/test-contact.ps1   (starts its own PHP server against dist/)
#
# Requires PHP 8.2+ on PATH. Builds the site, starts PHP's built-in server, points the
# endpoint at a throwaway state directory, and forces the file mail transport so the
# composed message can be asserted without a mail server.

param(
    [string]$Port = "8123"
)

$ErrorActionPreference = "Stop"
$repo = Split-Path $PSScriptRoot -Parent
$base = "http://127.0.0.1:$Port/api/contact.php"
$state = Join-Path ([System.IO.Path]::GetTempPath()) "jmcc-form-state-test"
$pass = 0; $fail = 0

function Check($name, $condition, $detail = "") {
    if ($condition) { $script:pass++; "  PASS  $name" }
    else { $script:fail++; "  FAIL  $name  $detail" }
}

function Send($body) {
    # Body must go out as UTF-8 bytes. Handing Invoke-WebRequest a string makes it
    # encode as ISO-8859-1, which mangles accents into invalid UTF-8 — json_decode
    # then rejects the payload and the test measures the harness, not the endpoint.
    $bytes = [Text.Encoding]::UTF8.GetBytes(($body | ConvertTo-Json -Compress))
    try {
        $r = Invoke-WebRequest -Uri $base -Method POST -ContentType "application/json; charset=utf-8" `
             -Body $bytes -UseBasicParsing -TimeoutSec 20
        return @{ code = [int]$r.StatusCode; json = ($r.Content | ConvertFrom-Json) }
    } catch {
        $resp = $_.Exception.Response
        $code = if ($resp) { [int]$resp.StatusCode } else { 0 }
        $text = ""
        if ($resp) { $sr = New-Object IO.StreamReader($resp.GetResponseStream()); $text = $sr.ReadToEnd() }
        $j = try { $text | ConvertFrom-Json } catch { $null }
        return @{ code = $code; json = $j; raw = $text }
    }
}

function ResetRate { Get-ChildItem $state -Filter "rate-*.json" -ErrorAction SilentlyContinue | Remove-Item -Force }
function MailLog   { Get-Content (Join-Path $state "mail.log") -Raw -ErrorAction SilentlyContinue }
function ClearMail { Remove-Item (Join-Path $state "mail.log") -Force -ErrorAction SilentlyContinue }
function Token     { (Invoke-WebRequest -Uri $base -UseBasicParsing -TimeoutSec 20).Content | ConvertFrom-Json }

function Valid($tok, $overrides = @{}) {
    $b = @{ name = "Test Person"; email = "test@example.com"; subject = "Hello"
           message = "This is a test message."; lang = "en"; website = ""
           ts = $tok.ts; sig = $tok.sig }
    foreach ($k in $overrides.Keys) { $b[$k] = $overrides[$k] }
    return $b
}

# --- setup -----------------------------------------------------------------
New-Item -ItemType Directory -Force $state | Out-Null
Get-ChildItem $state -File -ErrorAction SilentlyContinue | Remove-Item -Force
$env:JMCC_FORM_STATE = $state

# Force the file transport for the duration of the run. Removed in the finally block.
# Written WITHOUT a BOM: PowerShell's -Encoding UTF8 adds one, and PHP echoes those
# bytes before any output, which corrupts the JSON response and breaks header sending.
$localCfg = Join-Path $repo "public\api\config.local.php"
[System.IO.File]::WriteAllText($localCfg,
    "<?php`ndefine('MAIL_TRANSPORT', 'file');`n",
    (New-Object System.Text.UTF8Encoding $false))

Push-Location $repo
try {
    npm run build 2>&1 | Select-String -Pattern "Complete!" | Select-Object -First 1
    $server = Start-Process -FilePath "php" -ArgumentList "-S","127.0.0.1:$Port","-t","dist" `
              -WindowStyle Hidden -PassThru
    Start-Sleep -Seconds 2

    "== GET: signed token =="
    $tok = Token
    Check "GET returns ts and sig" ($tok.ts -and $tok.sig)
    Check "sig is a sha256 hex digest" ($tok.sig -match '^[0-9a-f]{64}$')

    "== method guard =="
    try {
        Invoke-WebRequest -Uri $base -Method PUT -UseBasicParsing -TimeoutSec 20 | Out-Null
        Check "PUT rejected" $false
    } catch { Check "PUT rejected with 405" ([int]$_.Exception.Response.StatusCode -eq 405) }

    "== honeypot =="
    ResetRate; ClearMail
    $r = Send (Valid $tok @{ website = "http://spam.example" })
    Check "honeypot returns 200 ok=true" ($r.code -eq 200 -and $r.json.ok -eq $true)
    Check "honeypot sent nothing" ([string]::IsNullOrEmpty((MailLog)))

    "== timing =="
    ResetRate; ClearMail
    $fresh = Token
    $r = Send (Valid $fresh)
    Check "sub-3s submission accepted-but-discarded" ($r.code -eq 200 -and $r.json.ok -eq $true)
    Check "sub-3s sent nothing" ([string]::IsNullOrEmpty((MailLog)))

    "== token forgery =="
    ResetRate
    Check "bad signature rejected 400" ((Send (Valid $tok @{ sig = ("0" * 64) })).code -eq 400)
    Check "non-numeric ts rejected 400" ((Send (Valid $tok @{ ts = "nope" })).code -eq 400)
    $old = @{ ts = "$([int](Get-Date -UFormat %s) - 99999)"; sig = "x" }
    Check "expired token rejected 400" ((Send (Valid $old)).code -eq 400)

    # Everything below needs a token older than the 3-second floor.
    $aged = Token
    Start-Sleep -Seconds 4

    "== validation =="
    ResetRate
    $r = Send (Valid $aged @{ email = "not-an-email" })
    Check "bad email rejected 422" ($r.code -eq 422)
    Check "bad email names the field" ($r.json.fields -contains "email")
    ResetRate
    $r = Send (Valid $aged @{ message = "" })
    Check "empty message rejected 422" ($r.code -eq 422 -and $r.json.fields -contains "message")
    ResetRate
    $r = Send (Valid $aged @{ subject = ("x" * 500) })
    Check "over-length subject rejected 422" ($r.code -eq 422 -and $r.json.fields -contains "subject")
    ResetRate
    $r = Send (Valid $aged @{ message = ("x" * 6000) })
    Check "oversized payload rejected 422" ($r.code -eq 422 -and $r.json.fields -contains "message")

    "== header injection =="
    ResetRate
    $r = Send (Valid $aged @{ name = "Evil`r`nBcc: victim@example.com" })
    Check "CRLF in name rejected 422" ($r.code -eq 422 -and $r.json.fields -contains "name")
    ResetRate
    $r = Send (Valid $aged @{ subject = "Subject`nBcc: victim@example.com" })
    Check "LF in subject rejected 422" ($r.code -eq 422 -and $r.json.fields -contains "subject")
    ResetRate; ClearMail
    $r = Send (Valid $aged @{ email = "a@b.com`r`nCc: victim@example.com" })
    Check "CRLF in email rejected 422" ($r.code -eq 422)
    Check "no message written for injection attempt" ([string]::IsNullOrEmpty((MailLog)))

    "== bilingual =="
    ResetRate
    Check "French error for lang=fr" ((Send (Valid $aged @{ email = "bad"; lang = "fr" })).json.error -match "courriel")
    ResetRate
    Check "English error for lang=en" ((Send (Valid $aged @{ email = "bad"; lang = "en" })).json.error -match "email address")

    "== composed message =="
    ResetRate; ClearMail
    $r = Send (Valid $aged @{ name = "Ada Lovelace"; email = "ada@example.com"
                              subject = "Sponsorship enquiry"; message = "We would like to sponsor." })
    $log = MailLog
    Check "valid submission returns 200 ok" ($r.code -eq 200 -and $r.json.ok -eq $true)
    Check "message written" (-not [string]::IsNullOrEmpty($log))
    Check "Reply-To is the submitter" ($log -match 'Reply-To:.*ada@example\.com')
    Check "From is on the canonical domain" ($log -match 'From:.*@wecompete\.ca')
    Check "subject carries the [JMCC Website] prefix" (
        $log -match 'Subject: =\?UTF-8\?B\?([A-Za-z0-9+/=]+)\?=' -and
        ([Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($Matches[1]))) -like "*[JMCC Website]*Sponsorship enquiry*")
    Check "body carries name, email and message" (
        $log -match 'Ada Lovelace' -and $log -match 'ada@example\.com' -and $log -match 'We would like to sponsor')
    Check "charset declared utf-8" ($log -match 'charset=utf-8')

    "== accents survive encoding =="
    ResetRate; ClearMail
    $null = Send (Valid $aged @{ subject = "Réunion à Montréal"; message = "Été" })
    $log = MailLog
    Check "accented subject round-trips" (
        $log -match 'Subject: =\?UTF-8\?B\?([A-Za-z0-9+/=]+)\?=' -and
        ([Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($Matches[1]))) -like "*Réunion à Montréal*")

    "== rate limit =="
    ResetRate
    $codes = @(); for ($i = 1; $i -le 7; $i++) { $codes += (Send (Valid $aged)).code }
    Check "allows 5 then blocks the rest" (($codes | Where-Object { $_ -eq 429 }).Count -eq 2) ("codes=" + ($codes -join ","))
    ResetRate
    Check "counter reset restores access" ((Send (Valid $aged)).code -ne 429)

    "== retention =="
    # Files are written without a BOM: PHP would see the BOM as part of the first line
    # and the "[" date check would miss it, so the test would measure the harness.
    $logFile = Join-Path $state "contact.log"
    $stamp = Join-Path $state "last-prune"
    $ancient = (Get-Date).ToUniversalTime().AddDays(-400).ToString("yyyy-MM-ddTHH:mm:ss") + "+00:00"
    $recent = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss") + "+00:00"
    $noBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($logFile, "[$ancient] sent from ancient@example.com`n[$recent] sent from recent@example.com`n", $noBom)
    $spentRate = Join-Path $state "rate-spent.json"; $liveRate = Join-Path $state "rate-live.json"
    [System.IO.File]::WriteAllText($spentRate, "[1]", $noBom); [System.IO.File]::WriteAllText($liveRate, "[1]", $noBom)
    (Get-Item $spentRate).LastWriteTime = (Get-Date).AddHours(-2)
    Remove-Item $stamp -Force -ErrorAction SilentlyContinue
    $null = Token
    $after = Get-Content $logFile -Raw
    Check "log line past retention dropped" ($after -notmatch 'ancient@example\.com')
    Check "log line within retention kept" ($after -match 'recent@example\.com')
    Check "spent rate-limit counter deleted" (-not (Test-Path $spentRate))
    Check "live rate-limit counter kept" (Test-Path $liveRate)

    # The stamp is what keeps this off the hot path; without it every request rewrites the log.
    [System.IO.File]::WriteAllText($logFile, "[$ancient] sent from ancient@example.com`n", $noBom)
    $null = Token
    Check "prune runs at most once a day" ((Get-Content $logFile -Raw) -match 'ancient@example\.com')

    "== state survives a deploy =="
    $keyBefore = (Get-FileHash (Join-Path $state "contact.key")).Hash
    Remove-Item (Join-Path $repo "dist") -Recurse -Force
    npm run build 2>&1 | Select-String -Pattern "Complete!" | Out-Null
    Check "signing key survives wiping the deploy target" (
        (Get-FileHash (Join-Path $state "contact.key")).Hash -eq $keyBefore)
    Check "state dir is outside the deploy target" (
        -not $state.StartsWith((Join-Path $repo "dist")))
}
finally {
    if ($server -and -not $server.HasExited) { Stop-Process -Id $server.Id -Force }
    Remove-Item $localCfg -Force -ErrorAction SilentlyContinue
    Pop-Location
}

""
"passed: $pass   failed: $fail"
if ($fail -gt 0) { exit 1 }
