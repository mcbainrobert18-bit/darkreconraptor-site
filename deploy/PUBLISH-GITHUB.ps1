# Push darkreconraptor_site to GitHub Pages repo
# Usage: .\PUBLISH-GITHUB.ps1

$ErrorActionPreference = "Stop"
$SiteRoot = Split-Path $PSScriptRoot -Parent
$Repo = "https://github.com/mcbainrobert18-bit/darkreconraptor-site.git"

Set-Location $SiteRoot

if (-not (Test-Path ".git")) {
    git init
    git branch -M main
    git remote add origin $Repo
}

git add -A
$status = git status --porcelain
if (-not $status) {
    Write-Host "Nothing to commit." -ForegroundColor Yellow
    exit 0
}

git commit -m "Update site $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
git push -u origin main

Write-Host ""
Write-Host "Published to GitHub Pages." -ForegroundColor Green
Write-Host "  Repo:  https://github.com/mcbainrobert18-bit/darkreconraptor-site"
Write-Host "  Live:  https://www.darkreconraptor.com/ (after Njalla CNAME + DNS propagate)"
Write-Host "  DNS:   deploy\njalla-dns-github.txt"