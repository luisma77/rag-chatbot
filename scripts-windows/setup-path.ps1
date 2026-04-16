#Requires -Version 5.1
<#
.SYNOPSIS
    Gestiona las variables PATH del sistema para las herramientas del RAG Chatbot.

.DESCRIPTION
    Comprueba 1 a 1 si cada ruta necesaria ya esta en el PATH del usuario/sistema.
    Si no esta, la añade de forma permanente al PATH del usuario (sin necesidad de admin).

    Herramientas gestionadas:
      - Ollama        : C:\ollama
      - Poppler       : C:\poppler\Library\bin
      - Tesseract OCR : C:\Program Files\Tesseract-OCR
      - Python Scripts: auto-detectado via py -c

    Uso:
      pwsh -ExecutionPolicy Bypass -File scripts\setup-path.ps1
      o doble-click en run-install.bat

.NOTES
    Requiere PowerShell 5.1+. Compatible con PowerShell 7 (pwsh).
    No requiere privilegios de administrador (escribe en PATH de Usuario).
#>

param(
    [switch]$DryRun   # Muestra que haria sin hacer cambios
)

# ── Encoding: forzar UTF-8 en la consola ─────────────────────────────────────
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
chcp 65001 | Out-Null

$ErrorActionPreference = "Continue"

# ── Verificar admin — requerir para escribir en Machine PATH ─────────────────
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin -and -not $DryRun) {
    Write-Host ""
    Write-Host "  Se requieren privilegios de administrador para modificar el PATH del sistema." -ForegroundColor Yellow
    Write-Host "  Relanzando como administrador... (acepta el dialogo UAC)" -ForegroundColor Cyan
    $scriptFile = if ($PSCommandPath) { $PSCommandPath } else { $MyInvocation.MyCommand.Path }
    $argStr = "-NoExit -ExecutionPolicy Bypass -File `"$scriptFile`""
    $launched = $false
    try {
        Start-Process pwsh -Verb RunAs -ArgumentList $argStr -ErrorAction Stop
        $launched = $true
    } catch {
        try {
            Start-Process powershell -Verb RunAs -ArgumentList $argStr -ErrorAction Stop
            $launched = $true
        } catch {
            Write-Host "  ERROR: No se pudo relanzar como administrador." -ForegroundColor Red
            Write-Host "  Ejecuta este script manualmente como administrador." -ForegroundColor Yellow
        }
    }
    if ($launched) {
        Write-Host "  Ventana elevada abierta. Esta ventana se cerrara." -ForegroundColor Gray
    }
    Start-Sleep -Seconds 2
    exit
}

function Write-Step {
    param([string]$Text, [string]$Color = "White")
    Write-Host "  $Text" -ForegroundColor $Color
}

function Write-Header {
    param([string]$Text)
    Write-Host ""
    Write-Host "  $Text" -ForegroundColor Cyan
    Write-Host "  $('─' * ($Text.Length))" -ForegroundColor DarkCyan
}

# ── Rutas a garantizar ─────────────────────────────────────────────────────────
$pathEntries = @(
    @{
        Name        = "Ollama"
        Path        = "C:\ollama"
        Description = "Runtime de Ollama (modelos LLM locales)"
        Check       = { Test-Path "C:\ollama\ollama.exe" }
    },
    @{
        Name        = "Poppler"
        Path        = "C:\poppler\Library\bin"
        Description = "Poppler utils — conversion PDF a imagen para OCR"
        Check       = { Test-Path "C:\poppler\Library\bin\pdftoppm.exe" }
    },
    @{
        Name        = "Tesseract OCR"
        Path        = "C:\Program Files\Tesseract-OCR"
        Description = "Motor OCR para extraccion de texto de imagenes/PDFs escaneados"
        Check       = { Test-Path "C:\Program Files\Tesseract-OCR\tesseract.exe" }
    }
)

# Detectar Scripts de Python dinamicamente (funciona con python, py o python3)
foreach ($pyCmd in @("python","py","python3")) {
    if (-not (Get-Command $pyCmd -ErrorAction SilentlyContinue)) { continue }
    try {
        $ver = & $pyCmd --version 2>&1
        if ($ver -notmatch "Python 3") { continue }
        $pyScripts = & $pyCmd -c "import sysconfig; print(sysconfig.get_path('scripts'))" 2>$null
        if ($pyScripts -and (Test-Path $pyScripts)) {
            $pathEntries += @{
                Name        = "Python Scripts"
                Path        = $pyScripts
                Description = "Scripts pip instalados (uvicorn, etc.) -- $pyCmd"
                Check       = { Test-Path $pyScripts }
            }
        }
        break
    } catch {}
}

# ── Funcion principal — escribe en PATH del sistema (Machine) ──────────────────
function Add-ToMachinePath {
    param([string]$NewPath)
    $current = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    if (-not $current) { $current = "" }
    $parts   = $current -split ";" | Where-Object { $_ -ne "" }
    if ($parts -notcontains $NewPath) {
        $updated = ($parts + $NewPath) -join ";"
        if (-not $DryRun) {
            [System.Environment]::SetEnvironmentVariable("Path", $updated, "Machine")
        }
        return $true   # fue añadido
    }
    return $false      # ya existia
}

function Test-InPath {
    param([string]$Dir)
    $machine = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    if (-not $machine) { $machine = "" }
    $user    = [System.Environment]::GetEnvironmentVariable("Path", "User")
    if (-not $user) { $user = "" }
    $all     = ($machine + ";" + $user) -split ";"
    return ($all -contains $Dir) -or ($all -contains "$Dir\") -or ($all -contains ($Dir.TrimEnd("\")))
}

# ── Cabecera ───────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "  RAG Chatbot — Gestor de PATH" -ForegroundColor Magenta
if ($DryRun) {
    Write-Host "  [MODO SIMULACION — no se realizaran cambios]" -ForegroundColor Yellow
}
Write-Host ""

$added   = 0
$skipped = 0
$missing = 0

foreach ($entry in $pathEntries) {
    Write-Header $entry.Name
    Write-Step "Ruta       : $($entry.Path)"
    Write-Step "Descripcion: $($entry.Description)"

    # ¿El binario/directorio existe?
    $exists = & $entry.Check
    if (-not $exists) {
        Write-Step "Estado : ⚠  Herramienta no encontrada en disco — instálala primero" "Yellow"
        Write-Step "         ejecuta run-install.bat si no la tienes" "DarkYellow"
        $missing++
        continue
    }

    # ¿Ya está en PATH?
    if (Test-InPath $entry.Path) {
        Write-Step "PATH   : ✓  Ya está en PATH" "Green"
        $skipped++
    } else {
        if ($DryRun) {
            Write-Step "PATH   : ->  [DryRun] Se añadiria al PATH del sistema: $($entry.Path)" "Cyan"
        } else {
            $null = Add-ToMachinePath $entry.Path
            Write-Step "PATH   : [OK]  Añadido al PATH del sistema (todos los usuarios)" "Green"
        }
        $added++
    }
}

# ── Resumen ────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "  ════════════════════════════════" -ForegroundColor DarkCyan
Write-Host "  Resumen PATH:" -ForegroundColor Cyan
Write-Host "    Ya estaban : $skipped" -ForegroundColor Green
if ($added -gt 0) {
    Write-Host "    Añadidos   : $added" -ForegroundColor Green
}
if ($missing -gt 0) {
    Write-Host "    No hallados: $missing (instala la herramienta primero)" -ForegroundColor Yellow
}
Write-Host "  ════════════════════════════════" -ForegroundColor DarkCyan

if ($added -gt 0 -and -not $DryRun) {
    Write-Host ""
    Write-Host "  IMPORTANTE: Cierra y vuelve a abrir la terminal para que" -ForegroundColor Yellow
    Write-Host "  los cambios en PATH surtan efecto en nuevas sesiones." -ForegroundColor Yellow
    Write-Host "  En la sesion actual ya estan disponibles." -ForegroundColor Gray

    # Aplica en la sesion actual
    $machine = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    if (-not $machine) { $machine = "" }
    $user    = [System.Environment]::GetEnvironmentVariable("Path", "User")
    if (-not $user) { $user = "" }
    $env:Path = "$machine;$user"
}

Write-Host ""
Read-Host "Presiona Enter para cerrar"
