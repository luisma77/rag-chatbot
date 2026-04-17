#Requires -Version 5.1
<#
.SYNOPSIS
    Gestiona las variables PATH del sistema para las herramientas del RAG Chatbot.

.DESCRIPTION
    Comprueba 1 a 1 si cada ruta necesaria ya esta en el PATH del usuario/sistema.
    Si no esta, la añade de forma permanente al PATH del sistema.
#>

param(
    [switch]$DryRun
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
chcp 65001 | Out-Null
$ErrorActionPreference = "Continue"

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).
    IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin -and -not $DryRun) {
    Write-Host ""
    Write-Host "  Se requieren privilegios de administrador para modificar el PATH del sistema." -ForegroundColor Yellow
    Write-Host "  Relanzando como administrador..." -ForegroundColor Cyan
    $scriptFile = if ($PSCommandPath) { $PSCommandPath } else { $MyInvocation.MyCommand.Path }
    $argStr = "-NoExit -ExecutionPolicy Bypass -File `"$scriptFile`""
    try {
        Start-Process pwsh -Verb RunAs -ArgumentList $argStr -ErrorAction Stop
    } catch {
        Start-Process powershell -Verb RunAs -ArgumentList $argStr
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

$pathEntries = @(
    @{
        Name        = "Ollama"
        Path        = "C:\ollama"
        Description = "Runtime de Ollama"
        Check       = { Test-Path "C:\ollama\ollama.exe" }
    },
    @{
        Name        = "Poppler"
        Path        = "C:\poppler\Library\bin"
        Description = "Poppler utils"
        Check       = { Test-Path "C:\poppler\Library\bin\pdftoppm.exe" }
    },
    @{
        Name        = "Tesseract OCR"
        Path        = "C:\Program Files\Tesseract-OCR"
        Description = "Motor OCR"
        Check       = { Test-Path "C:\Program Files\Tesseract-OCR\tesseract.exe" }
    }
)

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
                Description = "Scripts pip instalados"
                Check       = { Test-Path $pyScripts }
            }
        }
        break
    } catch {}
}

function Add-ToMachinePath {
    param([string]$NewPath)
    $current = Get-MachinePathValue
    if (-not $current) { $current = "" }
    $parts   = $current -split ";" | Where-Object { $_ -ne "" }
    if ($parts -notcontains $NewPath) {
        $updated = ($parts + $NewPath) -join ";"
        if (-not $DryRun) {
            Set-MachinePathValue -Value $updated
        }
        return $true
    }
    return $false
}

function Get-MachinePathValue {
    $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment"
    try {
        return (Get-ItemProperty -Path $registryPath -Name Path -ErrorAction Stop).Path
    } catch {
        return [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    }
}

function Set-MachinePathValue {
    param([string]$Value)
    $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment"
    try {
        Set-ItemProperty -Path $registryPath -Name Path -Value $Value -ErrorAction Stop
    } catch {
        try {
            [System.Environment]::SetEnvironmentVariable("Path", $Value, "Machine")
        } catch {
            $escaped = $Value.Replace("^", "^^").Replace("&", "^&")
            & reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path /t REG_EXPAND_SZ /d $escaped /f | Out-Null
        }
    }
}

function Test-InPath {
    param([string]$Dir)
    $machine = Get-MachinePathValue
    if (-not $machine) { $machine = "" }
    $user    = [System.Environment]::GetEnvironmentVariable("Path", "User")
    if (-not $user) { $user = "" }
    $all     = ($machine + ";" + $user) -split ";"
    return ($all -contains $Dir) -or ($all -contains "$Dir\") -or ($all -contains ($Dir.TrimEnd("\")))
}

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

    $exists = & $entry.Check
    if (-not $exists) {
        Write-Step "Estado : herramienta no encontrada en disco" "Yellow"
        $missing++
        continue
    }

    if (Test-InPath $entry.Path) {
        Write-Step "PATH   : ya esta presente" "Green"
        $skipped++
    } else {
        if ($DryRun) {
            Write-Step "PATH   : [DryRun] se anadiria $($entry.Path)" "Cyan"
        } else {
            $null = Add-ToMachinePath $entry.Path
            Write-Step "PATH   : anadido al PATH del sistema" "Green"
        }
        $added++
    }
}

Write-Host ""
Write-Host "  Resumen PATH" -ForegroundColor Cyan
Write-Host "    Ya estaban : $skipped" -ForegroundColor Green
if ($added -gt 0) { Write-Host "    Anadidos   : $added" -ForegroundColor Green }
if ($missing -gt 0) { Write-Host "    No hallados: $missing" -ForegroundColor Yellow }

if ($added -gt 0 -and -not $DryRun) {
    $machine = Get-MachinePathValue
    if (-not $machine) { $machine = "" }
    $user    = [System.Environment]::GetEnvironmentVariable("Path", "User")
    if (-not $user) { $user = "" }
    $env:Path = "$machine;$user"
}

Write-Host ""
Read-Host "Presiona Enter para cerrar"
