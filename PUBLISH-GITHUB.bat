@echo off
cd /d "%~dp0deploy"
powershell -ExecutionPolicy Bypass -File "%~dp0deploy\PUBLISH-GITHUB.ps1"
pause