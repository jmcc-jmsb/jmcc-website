# ABOUTME: Serves dist/ through a real local Apache + PHP 8.2 so .htaccess can be verified.
# ABOUTME: Run: npm run preview:apache, then tests/check-redirects.ps1. Ctrl+C to stop.
#
# Requires Apache 2.4 (winget install ApacheLounge.httpd) and PHP 8.2 thread-safe
# (winget install PHP.PHP.8.2 - the ZTS build ships php8apache2_4.dll). Both are found
# on PATH; nothing is installed as a service and nothing writes outside .apache-local/.

param(
    [int]$Port = 8080
)

$ErrorActionPreference = "Stop"
$repo = Split-Path $PSScriptRoot -Parent

function Need($exe, $hint) {
    $cmd = Get-Command $exe -ErrorAction SilentlyContinue
    if (-not $cmd) { throw "$exe not found on PATH. $hint" }
    return $cmd.Source
}

$httpd = Need "httpd" "Install with: winget install ApacheLounge.httpd (then restart the shell)."
$php = Need "php" "Install with: winget install PHP.PHP.8.2 (then restart the shell)."

# ServerRoot is the directory above bin/, which is where modules/ and conf/mime.types live.
$serverRoot = Split-Path (Split-Path $httpd -Parent) -Parent
$phpDir = Split-Path $php -Parent

if (-not (Test-Path (Join-Path $serverRoot "modules"))) {
    throw "$httpd does not sit in an Apache install (no $serverRoot\modules). Point PATH at the real Apache24\bin, not a shim."
}

$module = Join-Path $phpDir "php8apache2_4.dll"
if (-not (Test-Path $module)) {
    # ASCII only below: Windows PowerShell 5.1 reads .ps1 as ANSI, and a UTF-8 dash
    # inside a string decodes to a curly quote that terminates it mid-line.
    throw "$module is missing - that PHP is the non-thread-safe build, which has no Apache module. Install the thread-safe (TS) build of PHP 8.2."
}

# Everything this run writes lives here, gitignored. Form state sits outside the document
# root on purpose: production keeps it outside the rsync target so deploys cannot wipe it.
$local = Join-Path $repo ".apache-local"
$logs = Join-Path $local "logs"
$state = Join-Path $local "form-state"
New-Item -ItemType Directory -Force $logs, $state | Out-Null

# Apache wants forward slashes; backslashes inside quoted paths are escapes.
function Fwd($p) { $p -replace '\\', '/' }

$conf = Join-Path $PSScriptRoot "apache-local.conf"
$httpdArgs = @(
    "-d", (Fwd $serverRoot)
    "-f", (Fwd $conf)
    "-C", "Define PHP_DIR $(Fwd $phpDir)"
    "-C", "Define SITE_ROOT $(Fwd (Join-Path $repo 'dist'))"
    "-C", "Define STATE_DIR $(Fwd $state)"
    "-C", "Define LOG_DIR $(Fwd $logs)"
    "-C", "Define PORT $Port"
)

"Serving $repo\dist on http://localhost:$Port  (Ctrl+C to stop)"
"Logs: $logs"
& $httpd @httpdArgs
