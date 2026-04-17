@echo off
chcp 65001 >nul
where pwsh >nul 2>&1
if %errorLevel% equ 0 (
    pwsh -NoExit -ExecutionPolicy Bypass -Command "Set-Location '%~dp0'; .\uninstall.ps1"
) else (
    powershell -NoExit -ExecutionPolicy Bypass -Command "Set-Location '%~dp0'; .\uninstall.ps1"
)
