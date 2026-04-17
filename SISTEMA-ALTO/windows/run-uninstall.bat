@echo off
chcp 65001 >nul
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Solicitando permisos de administrador...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)
where pwsh >nul 2>&1
if %errorLevel% equ 0 (
    pwsh -NoExit -ExecutionPolicy Bypass -Command "Set-Location '%~dp0'; .\uninstall.ps1"
) else (
    powershell -NoExit -ExecutionPolicy Bypass -Command "Set-Location '%~dp0'; .\uninstall.ps1"
)
