# Run from the repository root in Windows PowerShell or PowerShell 7.
$ErrorActionPreference = 'Stop'
Set-Location (Split-Path -Parent $PSScriptRoot)

function Run-Docker {
    & docker @args
    if ($LASTEXITCODE -ne 0) { throw "docker command failed with exit code $LASTEXITCODE" }
}

Run-Docker compose config --quiet
Run-Docker compose build certgen
Run-Docker compose run --rm certgen
Run-Docker compose up -d baseline hardened
Run-Docker compose ps
Write-Host "`nBaseline: https://localhost:8443/"
Write-Host "Hardened: https://localhost:9443/"
Write-Host 'Use scripts/smoke-test.ps1 to verify both endpoints.'
