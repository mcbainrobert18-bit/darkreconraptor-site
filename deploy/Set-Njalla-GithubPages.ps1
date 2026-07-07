# Update Njalla DNS: www -> GitHub Pages
# Requires NJALLA_TOKEN from https://njal.la/settings/ (API tokens)
# Usage: $env:NJALLA_TOKEN = "your-token"; .\Set-Njalla-GithubPages.ps1

param(
    [string]$Domain = "darkreconraptor.com",
    [string]$GithubTarget = "mcbainrobert18-bit.github.io",
    [string]$Token = $env:NJALLA_TOKEN
)

$ErrorActionPreference = "Stop"

if (-not $Token) {
    Write-Host "Set your Njalla API token first:" -ForegroundColor Yellow
    Write-Host '  $env:NJALLA_TOKEN = "paste-token-from-njal.la-settings"'
    Write-Host "  .\Set-Njalla-GithubPages.ps1"
    Write-Host ""
    Write-Host "Or edit DNS manually at https://njal.la/ -> Domains -> $Domain -> DNS"
    Write-Host "  DELETE www CNAME -> sites.super.myninja.ai"
    Write-Host "  ADD    www CNAME -> $GithubTarget"
    exit 1
}

function Invoke-Njalla {
    param([string]$Method, [hashtable]$Params)
    $body = @{
        jsonrpc = "2.0"
        method  = $Method
        params  = $Params
        id      = "drr-$(Get-Date -Format 'yyyyMMddHHmmss')"
    } | ConvertTo-Json -Depth 5 -Compress

    $headers = @{
        Authorization = "Njalla $Token"
        Accept        = "application/json"
        "Content-Type" = "application/json"
    }

    $resp = Invoke-RestMethod -Uri "https://njal.la/api/1/" -Method Post -Headers $headers -Body $body
    if ($resp.error) {
        throw "Njalla API error: $($resp.error.message)"
    }
    return $resp.result
}

Write-Host "Fetching DNS records for $Domain..." -ForegroundColor Cyan
$result = Invoke-Njalla -Method "list-records" -Params @{ domain = $Domain }
$records = $result.records

$wwwRecords = $records | Where-Object { $_.name -eq "www" }
$ninja = $wwwRecords | Where-Object { $_.content -match "myninja" }

foreach ($rec in $ninja) {
    Write-Host "Removing www -> $($rec.content) (id $($rec.id))" -ForegroundColor Yellow
    Invoke-Njalla -Method "remove-record" -Params @{ domain = $Domain; id = $rec.id } | Out-Null
}

$existingGh = $records | Where-Object { $_.name -eq "www" -and $_.type -eq "CNAME" -and $_.content -eq $GithubTarget }
if ($existingGh) {
    Write-Host "www CNAME already points to $GithubTarget" -ForegroundColor Green
} else {
    Write-Host "Adding www CNAME -> $GithubTarget" -ForegroundColor Cyan
    Invoke-Njalla -Method "add-record" -Params @{
        domain  = $Domain
        name    = "www"
        type    = "CNAME"
        content = $GithubTarget
        ttl     = 3600
    } | Out-Null
}

Write-Host ""
Write-Host "Done. Verify:" -ForegroundColor Green
Write-Host "  nslookup www.$Domain 8.8.8.8"
Write-Host "  https://www.$Domain/"
Write-Host ""
Write-Host "After DNS propagates (~10-60 min), enable Enforce HTTPS in GitHub Pages settings."