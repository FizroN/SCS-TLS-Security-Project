# Quick repeatable smoke test for Person 1 (no external Python dependencies).
$ErrorActionPreference = 'Stop'
Set-Location (Split-Path -Parent $PSScriptRoot)

function Assert-NativeExit {
    param([string]$Label)
    if ($LASTEXITCODE -ne 0) { throw "$Label failed with exit code $LASTEXITCODE" }
}

& docker compose exec -T baseline nginx -t
Assert-NativeExit 'Baseline nginx configuration'
& docker compose exec -T hardened nginx -t
Assert-NativeExit 'Hardened nginx configuration'

$base = (& curl.exe -ksSI --max-time 10 'https://localhost:8443/') -join "`n"
Assert-NativeExit 'Baseline HTTP response'
$hard = (& curl.exe -ksSI --max-time 10 'https://localhost:9443/') -join "`n"
Assert-NativeExit 'Hardened HTTP response'

if ($base -notmatch 'HTTP/\S+ 200') { throw 'Baseline did not return HTTP 200' }
if ($hard -notmatch 'HTTP/\S+ 200') { throw 'Hardened did not return HTTP 200' }
if ($base -match '(?im)^Strict-Transport-Security\s*:') { throw 'Baseline unexpectedly offers HSTS' }
if ($hard -notmatch '(?im)^Strict-Transport-Security:\s*max-age=300') { throw 'Hardened missing expected HSTS header' }


Write-Host "`nPASS: nginx configs valid, both sites HTTP 200, HSTS absent/present as expected."
Write-Host 'NOTE: Check that the hardened endpoint rejects TLS 1.2 in the dedicated Experiment 2.'
