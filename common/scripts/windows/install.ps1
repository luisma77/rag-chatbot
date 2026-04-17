#Requires -Version 5.1
param(
    [Parameter(Mandatory = $true)][string]$ProfileName,
    [Parameter(Mandatory = $true)][string]$ManifestPath,
    [Parameter(Mandatory = $true)][string]$ProfileEnvPath,
    [Parameter(Mandatory = $true)][string]$OsTemplatePath
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
chcp 65001 | Out-Null
$ErrorActionPreference = "Stop"

function Write-Step($msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }
function Write-OK($msg)   { Write-Host "  [OK] $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "  [!!] $msg" -ForegroundColor Yellow }
function Write-Err($msg)  { Write-Host "  [ERROR] $msg" -ForegroundColor Red }
function Write-Info($msg) { Write-Host "  ... $msg" -ForegroundColor Gray }
function Pause-End($msg = "Presiona Enter para cerrar") { Write-Host ""; Read-Host $msg | Out-Null }
function Test-Cmd($cmd) { [bool](Get-Command $cmd -ErrorAction SilentlyContinue) }

function Refresh-Path {
    $machine = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $user = [Environment]::GetEnvironmentVariable("Path", "User")
    $env:Path = "$machine;$user"
}

function Add-ToMachinePath {
    param([string]$NewPath)
    if (-not $NewPath -or -not (Test-Path $NewPath)) { return }
    $current = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $parts = @()
    if ($current) { $parts = $current -split ";" | Where-Object { $_ } }
    if ($parts | Where-Object { $_.TrimEnd("\") -eq $NewPath.TrimEnd("\") }) { return }
    [Environment]::SetEnvironmentVariable("Path", (($parts + $NewPath) -join ";"), "Machine")
    $env:Path += ";$NewPath"
}

function Prompt-YesNo {
    param(
        [string]$Question,
        [bool]$DefaultYes = $true
    )
    $suffix = if ($DefaultYes) { "[S/n]" } else { "[s/N]" }
    $answer = Read-Host "$Question $suffix"
    if ([string]::IsNullOrWhiteSpace($answer)) { return $DefaultYes }
    return $answer.Trim().ToLower().StartsWith("s") -or $answer.Trim().ToLower().StartsWith("y")
}

function Get-ToolVersion {
    param([string]$Command, [string]$Arguments = "--version")
    try {
        $output = & $Command $Arguments 2>&1 | Select-Object -First 1
        return "$output".Trim()
    } catch {
        return ""
    }
}

function Winget-Ensure {
    param(
        [Parameter(Mandatory = $true)][string]$Id,
        [Parameter(Mandatory = $true)][string]$Label,
        [string]$VerifyCommand = "",
        [string]$PostInstallPath = ""
    )
    if (-not (Test-Cmd "winget")) {
        Write-Warn "winget no esta disponible. No se puede gestionar automaticamente: $Label"
        return
    }

    $installed = winget list --id $Id --accept-source-agreements 2>$null
    if ($installed) {
        Write-OK "$Label ya instalado."
        $upgradeInfo = winget upgrade --id $Id --accept-source-agreements 2>$null
        if ($upgradeInfo -and ($upgradeInfo | Out-String) -notmatch "No installed package found|No applicable update found") {
            Write-Warn "Hay una actualizacion disponible para $Label."
            if (Prompt-YesNo "Deseas actualizar $Label?" $true) {
                winget upgrade --id $Id --accept-package-agreements --accept-source-agreements --silent
                Write-OK "$Label actualizado."
            } else {
                Write-Info "Se conserva la version actual de $Label."
            }
        }
    } else {
        Write-Warn "$Label no encontrado. Instalando la version mas reciente compatible..."
        winget install --id $Id --accept-package-agreements --accept-source-agreements --silent
        Write-OK "$Label instalado."
    }

    Refresh-Path
    if ($PostInstallPath) { Add-ToMachinePath $PostInstallPath }
    if ($VerifyCommand -and (Test-Cmd $VerifyCommand)) {
        Write-Info "$Label version: $(Get-ToolVersion $VerifyCommand)"
    }
}

function Install-OrUpdate-Poppler {
    $popplerDir = "C:\poppler"
    if (Test-Path $popplerDir) {
        Write-OK "Poppler ya existe en $popplerDir"
        if (Prompt-YesNo "Hay una instalacion previa de Poppler. Deseas actualizarla?" $false) {
            Write-Info "Descargando ultimo release de Poppler..."
        } else {
            Add-ToMachinePath "C:\poppler\Library\bin"
            return
        }
    } else {
        Write-Warn "Poppler no encontrado. Instalando..."
    }

    try {
        $apiUrl = "https://api.github.com/repos/oschwartz10612/poppler-windows/releases/latest"
        $release = Invoke-RestMethod -Uri $apiUrl -Headers @{ "User-Agent" = "rag-chatbot-installer" }
        $asset = $release.assets | Where-Object { $_.name -match "\.zip$" } | Select-Object -First 1
        if (-not $asset) { throw "No se encontro un asset zip de Poppler." }
        $zip = Join-Path $env:TEMP "poppler-latest.zip"
        Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zip -UseBasicParsing
        $tmp = Join-Path $env:TEMP "poppler-extract"
        if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force }
        Expand-Archive $zip $tmp -Force
        $extracted = Get-ChildItem $tmp -Directory | Select-Object -First 1
        if (Test-Path $popplerDir) { Remove-Item $popplerDir -Recurse -Force }
        Move-Item $extracted.FullName $popplerDir
        Remove-Item $zip -Force -ErrorAction SilentlyContinue
        Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
        Add-ToMachinePath "C:\poppler\Library\bin"
        Write-OK "Poppler listo en C:\poppler"
    } catch {
        Write-Warn "No se pudo instalar/actualizar Poppler automaticamente: $_"
    }
}

function Merge-EnvTemplate {
    param(
        [string]$RepoRoot,
        [string]$BaseEnvPath,
        [string]$ProfileEnvPath,
        [string]$OsTemplatePath
    )

    $target = Join-Path $RepoRoot ".env"
    $lines = [System.Collections.Generic.List[string]]::new()
    foreach ($path in @($BaseEnvPath, $ProfileEnvPath, $OsTemplatePath)) {
        if (Test-Path $path) {
            Get-Content $path | ForEach-Object { $lines.Add($_) }
        }
    }
    Set-Content -Path $target -Value $lines -Encoding UTF8
    Write-OK ".env actualizado para $ProfileName"
}

function Ensure-InstallState {
    param([string]$RepoRoot, [object]$Manifest)
    $stateDir = Join-Path $RepoRoot "install-state"
    New-Item -ItemType Directory -Force -Path $stateDir | Out-Null
    $stateFile = Join-Path $stateDir "$($Manifest.profile_id)-windows.json"
    $state = @{
        profile = $Manifest.profile_id
        os = "windows"
        model = $Manifest.ollama_model
        updated_at = (Get-Date).ToString("s")
        quality_extras = [bool]$Manifest.quality_extras
    } | ConvertTo-Json
    Set-Content -Path $stateFile -Value $state -Encoding UTF8
}

try {
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).
        IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-Warn "Este instalador requiere privilegios de administrador."
        Pause-End
        exit 1
    }

    $repoRoot = Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent
    Set-Location $repoRoot
    $manifest = Get-Content $ManifestPath | ConvertFrom-Json
    $baseEnv = Join-Path $repoRoot "common\env\base.env"
    Write-Host ""
    Write-Host "======================================================" -ForegroundColor Magenta
    Write-Host "  RAG Chatbot -- Instalacion $ProfileName (Windows)" -ForegroundColor Magenta
    Write-Host "======================================================" -ForegroundColor Magenta
    Write-Host "  Perfil:   $($manifest.hardware_target)"
    Write-Host "  Modelo:   $($manifest.ollama_model)"
    Write-Host ""

    Write-Step "1/6 PowerShell 7"
    Winget-Ensure -Id "Microsoft.PowerShell" -Label "PowerShell 7" -VerifyCommand "pwsh"

    Write-Step "2/6 Python"
    Winget-Ensure -Id "Python.Python.3.12" -Label "Python 3.12" -VerifyCommand "python"
    $pyExe = if (Test-Cmd "python") { "python" } elseif (Test-Cmd "py") { "py" } else { $null }
    if (-not $pyExe) { throw "Python no esta disponible tras la instalacion." }

    $pyExePath = & $pyExe -c "import sys; print(sys.executable)" 2>$null
    $pyScripts = & $pyExe -c "import sysconfig; print(sysconfig.get_path('scripts'))" 2>$null
    if ($pyExePath) { Add-ToMachinePath (Split-Path $pyExePath) }
    if ($pyScripts) { Add-ToMachinePath $pyScripts }

    Write-Step "3/6 Dependencias Python"
    & $pyExe -m pip install --upgrade pip --quiet --disable-pip-version-check
    foreach ($reqFile in $manifest.python_requirement_files) {
        Write-Info "Instalando paquetes desde $reqFile"
        & $pyExe -m pip install -r $reqFile --no-warn-script-location
    }

    Write-Step "4/6 Tesseract y Poppler"
    Winget-Ensure -Id "UB-Mannheim.TesseractOCR" -Label "Tesseract OCR" -VerifyCommand "tesseract" -PostInstallPath "C:\Program Files\Tesseract-OCR"
    Install-OrUpdate-Poppler

    Write-Step "5/6 Ollama y modelo"
    Winget-Ensure -Id "Ollama.Ollama" -Label "Ollama" -VerifyCommand "ollama"
    try {
        $null = Invoke-RestMethod -Uri "http://localhost:11434/api/tags" -TimeoutSec 3
        Write-OK "Ollama ya estaba corriendo."
    } catch {
        Write-Info "Iniciando Ollama..."
        Start-Process -FilePath "ollama" -ArgumentList "serve" -WindowStyle Hidden
        Start-Sleep -Seconds 5
    }
    Write-Info "Verificando modelo $($manifest.ollama_model)..."
    $tags = Invoke-RestMethod -Uri "http://localhost:11434/api/tags" -TimeoutSec 10
    $names = @($tags.models | ForEach-Object { $_.name })
    if ($names -contains $manifest.ollama_model) {
        Write-OK "Modelo $($manifest.ollama_model) ya disponible."
        if (Prompt-YesNo "Deseas refrescar el modelo descargandolo de nuevo?" $false) {
            & ollama pull $manifest.ollama_model
        }
    } else {
        Write-Warn "Modelo $($manifest.ollama_model) no encontrado. Descargando..."
        & ollama pull $manifest.ollama_model
        Write-OK "Modelo listo."
    }

    Write-Step "6/6 Configuracion del entorno"
    Merge-EnvTemplate -RepoRoot $repoRoot -BaseEnvPath $baseEnv -ProfileEnvPath $ProfileEnvPath -OsTemplatePath $OsTemplatePath
    New-Item -ItemType Directory -Force -Path (Join-Path $repoRoot "data\documents") | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $repoRoot "chroma_db") | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $repoRoot "logs") | Out-Null
    Ensure-InstallState -RepoRoot $repoRoot -Manifest $manifest

    Write-Host ""
    Write-Host "==============================" -ForegroundColor Green
    Write-Host "  INSTALACION COMPLETADA" -ForegroundColor Green
    Write-Host "==============================" -ForegroundColor Green
    Write-Host "  Siguiente paso: ejecutar el launcher run-chatbot correspondiente."
} catch {
    Write-Err $_
    exit 1
} finally {
    Pause-End
}
