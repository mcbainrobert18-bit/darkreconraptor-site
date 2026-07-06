# DarkReconRaptor - link www.darkreconraptor.com via Njalla DNS + VPS deploy
# Usage:
#   .\GO-LIVE.ps1 -ServerIp "203.0.113.10"
#   .\GO-LIVE.ps1 -DnsOnly -ServerIp "203.0.113.10"

param(
    [string]$ServerIp,
    [string]$SshUser = "root",
    [string]$RemotePath = "/var/www/darkreconraptor",
    [switch]$DnsOnly,
    [switch]$SkipBootstrap,
    [string]$CertbotEmail = "xxdark1eight7xx@gmail.com"
)

$ErrorActionPreference = "Stop"
$DeployDir = $PSScriptRoot
$SiteRoot = Split-Path $DeployDir -Parent
$ConfigPath = Join-Path $DeployDir "site-config.json"

function Test-IPv4([string]$Ip) {
    return $Ip -match '^\d{1,3}(\.\d{1,3}){3}$'
}

function Get-CurrentDns {
    $prev = $ErrorActionPreference
    $ErrorActionPreference = "SilentlyContinue"
    $apexOut = cmd /c "nslookup darkreconraptor.com 2>&1"
    $wwwOut = cmd /c "nslookup www.darkreconraptor.com 2>&1"
    $ErrorActionPreference = $prev
    $apex = ($apexOut | Select-String "Address:" | Select-Object -Last 1) -replace ".*:\s*", ""
    $www = ($wwwOut | Select-String "Aliases:|Address:")
    [pscustomobject]@{ Apex = $apex.Trim(); WwwRaw = ($www -join " | ") }
}

Write-Host ""
Write-Host "  DARKRECONRAPTOR GO LIVE" -ForegroundColor Magenta
Write-Host "  Njalla DNS -> VPS -> https://www.darkreconraptor.com" -ForegroundColor DarkGray
Write-Host ""

$dns = Get-CurrentDns
Write-Host "Current DNS:" -ForegroundColor Yellow
Write-Host "  apex: $($dns.Apex)"
Write-Host "  www:  $($dns.WwwRaw)"
if ($dns.WwwRaw -match 'myninja') {
    Write-Host "  [!] www still points to NinjaTech - delete that CNAME in Njalla" -ForegroundColor Red
}
if ($dns.Apex -match '^3\.173\.161\.') {
    Write-Host "  [!] apex still on CloudFront - replace with your VPS A record" -ForegroundColor Red
}

if (-not $ServerIp -and (Test-Path $ConfigPath)) {
    $saved = Get-Content $ConfigPath -Raw | ConvertFrom-Json
    if ($saved.server_ip) { $ServerIp = $saved.server_ip }
}

if (-not $ServerIp) {
    $ServerIp = Read-Host "Enter your VPS public IPv4"
}

if (-not (Test-IPv4 $ServerIp)) {
    throw "Invalid IPv4: $ServerIp"
}

@{
    server_ip = $ServerIp
    ssh_user = $SshUser
    remote_path = $RemotePath
    updated = (Get-Date).ToString("o")
} | ConvertTo-Json | Set-Content $ConfigPath -Encoding UTF8

Write-Host ""
Write-Host "Njalla DNS - https://njal.la/ -> Domains -> darkreconraptor.com -> DNS" -ForegroundColor Cyan
Write-Host "  DELETE: www CNAME -> sites.super.myninja.ai"
Write-Host "  DELETE: @ A records -> 3.173.161.x (CloudFront)"
Write-Host "  ADD A records (all -> $ServerIp): @ www hud beast operator"
Write-Host ""
Write-Host "Full guide: $DeployDir\njalla-dns-panel.txt" -ForegroundColor DarkGray

if ($DnsOnly) {
    Start-Process "https://njal.la/"
    exit 0
}

$confirm = Read-Host "DNS updated to $ServerIp ? (y = deploy now, n = Njalla only)"
if ($confirm -notmatch '^[Yy]') {
    Start-Process "https://njal.la/"
    Write-Host "Run again after DNS propagates: .\GO-LIVE.ps1 -ServerIp `"$ServerIp`"" -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "Deploying site files..." -ForegroundColor Cyan
ssh -o StrictHostKeyChecking=accept-new "${SshUser}@${ServerIp}" "mkdir -p $RemotePath"
scp -r "$SiteRoot\*" "${SshUser}@${ServerIp}:${RemotePath}/"

if (-not $SkipBootstrap) {
    Write-Host "Bootstrapping nginx + SSL on VPS..." -ForegroundColor Cyan
    $bootstrap = Join-Path $DeployDir "bootstrap_vps.sh"
    scp $bootstrap "${SshUser}@${ServerIp}:/tmp/drr-bootstrap.sh"
    ssh "${SshUser}@${ServerIp}" "chmod +x /tmp/drr-bootstrap.sh && CERTBOT_EMAIL='$CertbotEmail' REMOTE_PATH='$RemotePath' bash /tmp/drr-bootstrap.sh"
}

Write-Host ""
Write-Host "VERIFY:" -ForegroundColor Green
Write-Host "  https://www.darkreconraptor.com/"
Write-Host "  https://www.darkreconraptor.com/shop/"
Write-Host "  https://www.darkreconraptor.com/guide/"
Write-Host ""
Write-Host "Subdomains (static fallback until apps on :5000 / :8888):"
Write-Host "  https://hud.darkreconraptor.com/"
Write-Host "  https://beast.darkreconraptor.com/"
Write-Host ""

Start-Process "https://www.darkreconraptor.com/"