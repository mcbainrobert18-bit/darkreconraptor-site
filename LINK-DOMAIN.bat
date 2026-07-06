@echo off
cd /d "%~dp0deploy"
powershell -ExecutionPolicy Bypass -File "%~dp0deploy\GO-LIVE.ps1" %*