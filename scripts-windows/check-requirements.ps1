#Requires -Version 5.1
<#
.SYNOPSIS
    Comprueba e instala TODAS las dependencias del RAG Chatbot de forma automatizada.

.DESCRIPTION
    Verifica herramienta por herramienta:
      1. PowerShell 7 (pwsh)       - necesario para los scripts
      2. Python 3.10+              - runtime principal
      3. pip packages              - de requirements.txt
      4. Ollama                    - servidor LLM local
      5. Modelo LLM (qwen2.5:3b)  - modelo de lenguaje
      6. Poppler                   - conversion PDF a imagen
      7. Tesseract OCR             - extraccion texto de imagenes

    Por cada herramienta:
      - Detecta si ya esta instalada (y su version)
      - Si falta, la instala automaticamente
      - Actualiza las variables PATH si es necesario
      - Genera un informe detallado en docs/requirements-report.md

    Uso:
      pwsh -ExecutionPolicy Bypass -File scripts\check-requirements.ps1
      o doble-click en run-install.bat (ya lo llama internamente)

.NOTES
    Compatible con PowerShell 5.1 y PowerShell 7 (pwsh).
    Requiere conexion a Internet para descargas.
    NO requiere privilegios de administrador para Ollama/pip.
    Poppler y Tesseract se instalan en C:\ sin necesidad de admin.
#>

param(
    [switch]$CheckOnly,  # Solo comprueba, no instala
    [switch]$Verbose     # Muestra mas detalle
)

# ── Encoding: forzar UTF-8 en la consola ─────────────────────────────────────
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
chcp 65001 | Out-Null

$ErrorActionPreference = "Continue"
$script:repoRoot = Split-Path $PSScriptRoot -Parent
$script:report   = [System.Collections.Generic.List[string]]::new()
$script:ok       = 0
$script:warn     = 0
$script:fixed    = 0

# ── Helpers ────────────────────────────────────────────────────────────────────
function Write-Log {
    param([string]$Msg, [string]$Color = "White")
    Write-Host "  $Msg" -ForegroundColor $Color
}
function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host "  [$Title]" -ForegroundColor Cyan
    Write-Host "  $('─' * 50)" -ForegroundColor DarkCyan
    $script:report.Add("")
    $script:report.Add("## $Title")
    $script:report.Add("")
}
function Write-OK   { param($m) Write-Log "✓ $m" "Green";  $script:report.Add("- ✅ $m"); $script:ok++   }
function Write-Warn { param($m) Write-Log "⚠ $m" "Yellow"; $script:report.Add("- ⚠ $m"); $script:warn++ }
function Write-Fixed{ param($m) Write-Log "→ $m" "Cyan";   $script:report.Add("- 🔧 $m"); $script:fixed++ }
function Write-Fail { param($m) Write-Log "✗ $m" "Red";    $script:report.Add("- ❌ $m")                 }

function Refresh-EnvPath {
    $m = [System.Environment]::GetEnvironmentVariable("Path","Machine")
    if (-not $m) { $m = "" }
    $u = [System.Environment]::GetEnvironmentVariable("Path","User")
    if (-not $u) { $u = "" }
    $env:Path = "$m;$u"
}

function Add-ToUserPath {
    param([string]$Dir)
    $u = [System.Environment]::GetEnvironmentVariable("Path","User")
    if (-not $u) { $u = "" }
    $parts = $u -split ";" | Where-Object { $_ }
    if ($parts -notcontains $Dir) {
        [System.Environment]::SetEnvironmentVariable("Path", ($parts + $Dir -join ";"), "User")
        $env:Path = $env:Path + ";$Dir"
        Write-Fixed "PATH actualizado: $Dir"
        return $true
    }
    return $false
}

# ── Encabezado informe ─────────────────────────────────────────────────────────
$script:report.Add("# RAG Chatbot - Informe de Requisitos")
$script:report.Add("")
$script:report.Add("> Generado automaticamente por `check-requirements.ps1`  ")
$script:report.Add("> Fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm')")
$script:report.Add("")
$script:report.Add("---")

# ══════════════════════════════════════════════════════════════════════════════
Write-Host ""
Write-Host "  RAG Chatbot - Verificacion de Requisitos" -ForegroundColor Magenta
Write-Host "  $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
Write-Host ""

# ── 1. PowerShell 7 ────────────────────────────────────────────────────────────
Write-Section "1. PowerShell 7 (pwsh)"
$script:report.Add("| Campo | Valor |")
$script:report.Add("|-------|-------|")

$pwshPath = Get-Command pwsh -ErrorAction SilentlyContinue
if ($pwshPath) {
    $ver = (& pwsh --version) -replace "PowerShell ",""
    Write-OK  "Instalado: PowerShell $ver"
    Write-Log "   Ruta: $($pwshPath.Source)" "Gray"
    $script:report.Add("| Version | PowerShell $ver |")
    $script:report.Add("| Ruta | ``$($pwshPath.Source)`` |")
    $script:report.Add("| Instalar | ``winget install Microsoft.PowerShell`` |")
} else {
    Write-Warn "PowerShell 7 no encontrado (usando PS $($PSVersionTable.PSVersion))"
    $script:report.Add("| Estado | ⚠ No instalado |")
    $script:report.Add("| Instalar | ``winget install Microsoft.PowerShell`` |")
    if (-not $CheckOnly) {
        Write-Log "  Instalando PowerShell 7..." "Cyan"
        winget install --id Microsoft.PowerShell --accept-source-agreements --accept-package-agreements -e 2>$null
        if (Get-Command pwsh -ErrorAction SilentlyContinue) { Write-Fixed "PowerShell 7 instalado" }
        else { Write-Warn "Instala manualmente: winget install Microsoft.PowerShell" }
    }
}

# ── 2. Python ──────────────────────────────────────────────────────────────────
Write-Section "2. Python 3.10+"
$pyCmd = Get-Command python -ErrorAction SilentlyContinue
if ($pyCmd) {
    $pyVer = & python --version 2>&1
    Write-OK  "$pyVer"
    Write-Log "   Ruta: $($pyCmd.Source)" "Gray"
    $script:report.Add("| Version | $pyVer |")
    $script:report.Add("| Ruta | ``$($pyCmd.Source)`` |")
    $script:report.Add("| Instalar | ``winget install Python.Python.3.12`` |")
} else {
    Write-Fail "Python no encontrado en PATH"
    $script:report.Add("| Estado | ❌ No encontrado |")
    $script:report.Add("| Instalar | ``winget install Python.Python.3.12`` |")
    Write-Warn "Instala Python desde: https://www.python.org/downloads/"
}

# ── 3. pip packages ────────────────────────────────────────────────────────────
Write-Section "3. Paquetes Python (pip)"

$reqFile = Join-Path $script:repoRoot "requirements.txt"
$script:report.Add("Archivo: ``requirements.txt``")
$script:report.Add("")
$script:report.Add("| Paquete | Estado | Version |")
$script:report.Add("|---------|--------|---------|")

if (Test-Path $reqFile) {
    $reqs = Get-Content $reqFile | Where-Object { $_ -match "^\w" }

    # Obtener paquetes instalados de una vez
    $installed = @{}
    $pipList = & python -m pip list --format=json 2>$null | ConvertFrom-Json
    foreach ($pkg in $pipList) { $installed[$pkg.name.ToLower()] = $pkg.version }

    $missing = [System.Collections.Generic.List[string]]::new()
    foreach ($line in $reqs) {
        # Strip version specifiers AND pip extras like uvicorn[standard] → uvicorn
        $pkgName = ($line -split "[>=<!=\[]")[0].Trim().ToLower()
        if ($installed.ContainsKey($pkgName)) {
            Write-OK  "$pkgName $($installed[$pkgName])"
            $script:report.Add("| $pkgName | ✅ | $($installed[$pkgName]) |")
        } else {
            Write-Warn "$pkgName - NO instalado"
            $script:report.Add("| $pkgName | ⚠ Falta | - |")
            $missing.Add($line)
        }
    }

    if ($missing.Count -gt 0 -and -not $CheckOnly) {
        Write-Log ""
        Write-Log "  Instalando paquetes faltantes..." "Cyan"
        & python -m pip install $missing --quiet
        Write-Fixed "$($missing.Count) paquetes instalados"
    }
} else {
    Write-Warn "requirements.txt no encontrado en: $reqFile"
}

# ── 4. Ollama ──────────────────────────────────────────────────────────────────
Write-Section "4. Ollama (servidor LLM)"
$script:report.Add("| Campo | Valor |")
$script:report.Add("|-------|-------|")
$script:report.Add("| Descripcion | Servidor de modelos LLM locales |")
$script:report.Add("| Ruta esperada | ``C:\ollama\ollama.exe`` |")
$script:report.Add("| Instalar | ``Invoke-WebRequest -Uri https://ollama.ai/download/ollama-windows-amd64.zip -OutFile ollama.zip`` |")

$ollamaCandidates = @("C:\ollama\ollama.exe","$env:LOCALAPPDATA\Programs\Ollama\ollama.exe","C:\Program Files\Ollama\ollama.exe")
$ollamaExe = $ollamaCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $ollamaExe) {
    $ollamaCmd = Get-Command ollama -ErrorAction SilentlyContinue
    if ($ollamaCmd) { $ollamaExe = $ollamaCmd.Source }
}

if ($ollamaExe) {
    $ollamaVer = (& $ollamaExe --version 2>&1) -replace "ollama version ",""
    Write-OK  "Instalado: Ollama $ollamaVer"
    Write-Log "   Ruta: $ollamaExe" "Gray"
    $script:report.Add("| Version | Ollama $ollamaVer |")
    $script:report.Add("| Ruta | ``$ollamaExe`` |")
    $null = Add-ToUserPath (Split-Path $ollamaExe)

    # Comprobar si esta corriendo
    try {
        $null = Invoke-RestMethod "http://localhost:11434/api/tags" -TimeoutSec 3
        Write-OK  "Servicio activo en localhost:11434"
        $script:report.Add("| Servicio | ✅ Corriendo |")
    } catch {
        Write-Warn "Servicio no activo (se iniciara al ejecutar run-chatbot.bat)"
        $script:report.Add("| Servicio | ⚠ No corriendo |")
    }
} else {
    Write-Warn "Ollama no encontrado"
    if (-not $CheckOnly) {
        Write-Log "  Descargando Ollama portable..." "Cyan"
        $zip = "$env:TEMP\ollama-windows-amd64.zip"
        Invoke-WebRequest "https://ollama.ai/download/ollama-windows-amd64.zip" -OutFile $zip
        Expand-Archive $zip "C:\ollama" -Force
        Remove-Item $zip
        $null = Add-ToUserPath "C:\ollama"
        Write-Fixed "Ollama instalado en C:\ollama"
    }
}

# ── 5. Modelo LLM ──────────────────────────────────────────────────────────────
Write-Section "5. Modelo LLM (qwen2.5:3b)"
$script:report.Add("| Campo | Valor |")
$script:report.Add("|-------|-------|")
$script:report.Add("| Modelo | qwen2.5:3b |")
$script:report.Add("| Descripcion | Modelo de lenguaje ligero (~2GB, multilingue) |")
$script:report.Add("| Instalar | ``ollama pull qwen2.5:3b`` |")
$script:report.Add("| Alternativa | ``ollama pull llama3.2:3b`` o ``ollama pull phi3:mini`` |")

try {
    $tags  = Invoke-RestMethod "http://localhost:11434/api/tags" -TimeoutSec 5
    $names = $tags.models.name
    if ($names -match "qwen2.5") {
        Write-OK  "qwen2.5:3b disponible"
        $script:report.Add("| Estado | ✅ Disponible |")
    } else {
        Write-Warn "Modelo no descargado. Descargando..."
        $script:report.Add("| Estado | ⚠ Falta - descargando |")
        if (-not $CheckOnly -and $ollamaExe) {
            & $ollamaExe pull qwen2.5:3b
            Write-Fixed "Modelo qwen2.5:3b descargado"
        }
    }
} catch {
    Write-Warn "Ollama no esta corriendo - no se puede verificar el modelo"
    $script:report.Add("| Estado | ⚠ No verificable (Ollama no corre) |")
}

# ── 6. Poppler ─────────────────────────────────────────────────────────────────
Write-Section "6. Poppler (PDF → imagen)"
$popplerBin  = "C:\poppler\Library\bin"
$popplerExe  = "$popplerBin\pdftoppm.exe"
$script:report.Add("| Campo | Valor |")
$script:report.Add("|-------|-------|")
$script:report.Add("| Descripcion | Convierte paginas PDF a imagenes para OCR |")
$script:report.Add("| Ruta esperada | ``C:\poppler\Library\bin`` |")
$script:report.Add("| Instalar | Descarga de https://github.com/oschwartz10612/poppler-windows/releases |")
$script:report.Add("| Version usada | 24.x |")

if (Test-Path $popplerExe) {
    Write-OK  "Poppler instalado en $popplerBin"
    $script:report.Add("| Estado | ✅ Instalado |")
    $null = Add-ToUserPath $popplerBin
} else {
    Write-Warn "Poppler no encontrado en $popplerBin"
    $script:report.Add("| Estado | ⚠ No encontrado |")
    if (-not $CheckOnly) {
        Write-Log "  Descargando Poppler..." "Cyan"
        $popplerUrl = "https://github.com/oschwartz10612/poppler-windows/releases/download/v24.08.0-0/Release-24.08.0-0.zip"
        $popplerZip = "$env:TEMP\poppler.zip"
        try {
            Invoke-WebRequest $popplerUrl -OutFile $popplerZip
            Expand-Archive $popplerZip "C:\poppler_tmp" -Force
            $extracted = Get-ChildItem "C:\poppler_tmp" -Directory | Select-Object -First 1
            if ($extracted) {
                if (Test-Path "C:\poppler") { Remove-Item "C:\poppler" -Recurse -Force }
                Move-Item $extracted.FullName "C:\poppler"
            }
            Remove-Item "C:\poppler_tmp" -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item $popplerZip
            $null = Add-ToUserPath $popplerBin
            Write-Fixed "Poppler instalado en C:\poppler"
        } catch {
            Write-Warn "Error descargando Poppler: $_"
            Write-Log "   Descarga manual: https://github.com/oschwartz10612/poppler-windows/releases" "DarkYellow"
        }
    }
}

# ── 7. Tesseract OCR ───────────────────────────────────────────────────────────
Write-Section "7. Tesseract OCR"
$tessDir = "C:\Program Files\Tesseract-OCR"
$tessExe = "$tessDir\tesseract.exe"
$script:report.Add("| Campo | Valor |")
$script:report.Add("|-------|-------|")
$script:report.Add("| Descripcion | Motor OCR para PDFs escaneados e imagenes |")
$script:report.Add("| Ruta esperada | ``C:\Program Files\Tesseract-OCR`` |")
$script:report.Add("| Idiomas | eng + spa (incluidos en instalador) |")
$script:report.Add("| Instalar | ``winget install UB-Mannheim.TesseractOCR`` |")

if (Test-Path $tessExe) {
    $tessVer = (& $tessExe --version 2>&1 | Select-Object -First 1) -replace "tesseract ",""
    Write-OK  "Tesseract $tessVer en $tessDir"
    $script:report.Add("| Version | $tessVer |")
    $script:report.Add("| Estado | ✅ Instalado |")
    $null = Add-ToUserPath $tessDir
} else {
    Write-Warn "Tesseract no encontrado en $tessDir"
    $script:report.Add("| Estado | ⚠ No encontrado |")
    if (-not $CheckOnly) {
        Write-Log "  Instalando Tesseract via winget..." "Cyan"
        winget install --id UB-Mannheim.TesseractOCR --accept-source-agreements --accept-package-agreements -e 2>$null
        Refresh-EnvPath
        if (Test-Path $tessExe) { Write-Fixed "Tesseract instalado" }
        else { Write-Warn "Instala manualmente: winget install UB-Mannheim.TesseractOCR" }
    }
}

# ── Resumen ────────────────────────────────────────────────────────────────────
Write-Section "Resumen"
$total = $script:ok + $script:warn + $script:fixed
Write-Log "✓ OK      : $($script:ok)" "Green"
if ($script:fixed -gt 0) { Write-Log "→ Arreglados: $($script:fixed)" "Cyan" }
if ($script:warn  -gt 0) { Write-Log "⚠ Avisos  : $($script:warn)" "Yellow" }
Write-Log "  Total   : $total items comprobados"

$script:report.Add("| Estado | Cantidad |")
$script:report.Add("|--------|----------|")
$script:report.Add("| ✅ OK | $($script:ok) |")
$script:report.Add("| 🔧 Arreglados | $($script:fixed) |")
$script:report.Add("| ⚠ Avisos | $($script:warn) |")

# ── Escribir informe ───────────────────────────────────────────────────────────
$docsDir    = Join-Path $script:repoRoot "docs"
$reportFile = Join-Path $docsDir "requirements-report.md"
if (-not (Test-Path $docsDir)) { New-Item -ItemType Directory $docsDir -Force | Out-Null }

$script:report | Set-Content $reportFile -Encoding UTF8
Write-Host ""
Write-Log "Informe guardado en: docs/requirements-report.md" "Cyan"
Write-Host ""

if ($script:warn -gt 0 -and -not $CheckOnly) {
    Write-Log "Algunos elementos requieren instalacion manual." "Yellow"
    Write-Log "Revisa docs/requirements-report.md para detalles." "Yellow"
}

Read-Host "`n  Presiona Enter para cerrar"
