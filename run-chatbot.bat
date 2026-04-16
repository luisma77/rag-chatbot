@echo off
chcp 65001 >nul
:: Launcher para iniciar el chatbot RAG
:: Doble-click para ejecutar
::
:: NOTA: La comprobacion de Python se hace dentro del script PowerShell,
::       que recarga el PATH del sistema antes de buscar. Esto evita falsos
::       negativos cuando Python se acaba de instalar en esta sesion.

:: Recargar PATH del sistema desde el registro antes de comprobar nada
for /f "tokens=2*" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul') do set "PATH=%%B;%PATH%"

:: Usar PowerShell 7 si esta disponible, si no PS 5.1
where pwsh >nul 2>&1
if %errorLevel% equ 0 (
    pwsh -NoExit -ExecutionPolicy Bypass -Command "chcp 65001 | Out-Null; Set-Location '%~dp0'; .\scripts-windows\watch-and-serve.ps1"
) else (
    echo AVISO: PowerShell 7 no encontrado. Usando PowerShell 5.1...
    echo Ejecuta run-install.bat para instalar PowerShell 7.
    powershell -NoExit -ExecutionPolicy Bypass -Command "chcp 65001 | Out-Null; Set-Location '%~dp0'; .\scripts-windows\watch-and-serve.ps1"
)
