# Upload DarkReconRaptor build to a Vast.ai instance
# Usage: .\deploy_vast.ps1 -SshHost "142.214.185.187" -SshPort 20544

param(
    [Parameter(Mandatory = $true)]
    [string]$SshHost,

    [Parameter(Mandatory = $true)]
    [int]$SshPort,

    [string]$SshUser = "root",
    [string]$NinjaSource = "C:\Users\xxdar\OneDrive\Desktop\dark187_v5.2_release",
    [string]$SiteSource = "C:\Users\xxdae\darkreconraptor_site"
)

$DeployDir = $PSScriptRoot
$Target = "${SshUser}@${SshHost}"

Write-Host "Vast.ai deploy -> ${Target}:${SshPort}" -ForegroundColor Cyan

ssh -p $SshPort -o StrictHostKeyChecking=accept-new $Target "mkdir -p /workspace/logs"

if (Test-Path $NinjaSource) {
    Write-Host "Uploading ninja build (this may take a few minutes)..." -ForegroundColor Yellow
    scp -P $SshPort -r "$NinjaSource" "${Target}:/workspace/dark187_v5.2_release"
} else {
    Write-Host "WARN: Ninja source not found: $NinjaSource" -ForegroundColor Red
}

scp -P $SshPort "$DeployDir\vast_onstart.sh" "${Target}:/workspace/onstart.sh"

if (Test-Path $SiteSource) {
    scp -P $SshPort -r "$SiteSource" "${Target}:/workspace/darkreconraptor_site"
}

ssh -p $SshPort $Target "chmod +x /workspace/onstart.sh && bash /workspace/onstart.sh"

Write-Host ""
Write-Host "Done. Check Vast IP Port Info for external port mapped to 5099." -ForegroundColor Green
Write-Host "SSH tunnel:" -ForegroundColor Yellow
Write-Host "  ssh -p $SshPort $Target -L 5099:localhost:5099 -L 11434:localhost:11434"
Write-Host "Then open: http://127.0.0.1:5099/"