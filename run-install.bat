@echo off
chcp 65001 >nul
:: Launcher para instalar el chatbot RAG
:: Doble-click para ejecutar -- solicita permisos de administrador automaticamente

:: Pedir admin si no los tenemos
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Solicitando permisos de administrador...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: Usar PowerShell 7 si esta disponible, si no PS 5.1
where pwsh >nul 2>&1
if %errorLevel% equ 0 (
    pwsh -NoExit -ExecutionPolicy Bypass -Command "chcp 65001 | Out-Null; Set-Location '%~dp0'; .\scripts-windows\install.ps1"
) else (
    echo AVISO: PowerShell 7 no encontrado. Usando PowerShell 5.1...
    echo El instalador lo instalara automaticamente.
    powershell -NoExit -ExecutionPolicy Bypass -Command "chcp 65001 | Out-Null; Set-Location '%~dp0'; .\scripts-windows\install.ps1"
)
