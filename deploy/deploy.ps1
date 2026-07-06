# DarkReconRaptor — deploy static site to VPS
# Usage:
#   .\deploy.ps1 -ServerIp "1.2.3.4"
#   .\GO-LIVE.ps1 -ServerIp "1.2.3.4"   # preferred — includes Njalla DNS + bootstrap

param(
    [Parameter(Mandatory = $true)]
    [string]$ServerIp,

    [string]$SshUser = "root",
    [string]$RemotePath = "/var/www/darkreconraptor",
    [switch]$Bootstrap
)

$SiteRoot = Split-Path $PSScriptRoot -Parent

Write-Host "Deploying $SiteRoot -> ${SshUser}@${ServerIp}:${RemotePath}" -ForegroundColor Cyan

ssh -o StrictHostKeyChecking=accept-new "${SshUser}@${ServerIp}" "mkdir -p $RemotePath"
scp -r "$SiteRoot\*" "${SshUser}@${ServerIp}:${RemotePath}/"

if ($Bootstrap) {
    $bootstrap = Join-Path $PSScriptRoot "bootstrap_vps.sh"
    scp $bootstrap "${SshUser}@${ServerIp}:/tmp/drr-bootstrap.sh"
    ssh "${SshUser}@${ServerIp}" "chmod +x /tmp/drr-bootstrap.sh && REMOTE_PATH='$RemotePath' bash /tmp/drr-bootstrap.sh"
}

Write-Host "`nNjalla DNS: A records @, www, hud, beast, operator -> $ServerIp" -ForegroundColor Green
Write-Host "Full guide: deploy/NJALLA_DNS_SETUP.md or .\GO-LIVE.ps1 -DnsOnly -ServerIp `"$ServerIp`""