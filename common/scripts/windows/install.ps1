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
$script:AddedMachinePaths = [System.Collections.Generic.List[string]]::new()
$script:WingetInstalledIds = [System.Collections.Generic.List[string]]::new()
$script:WingetUpgradedIds = [System.Collections.Generic.List[string]]::new()

function Write-Step($msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }
function Write-OK($msg)   { Write-Host "  [OK] $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "  [!!] $msg" -ForegroundColor Yellow }
function Write-Err($msg)  { Write-Host "  [ERROR] $msg" -ForegroundColor Red }
function Write-Info($msg) { Write-Host "  ... $msg" -ForegroundColor Gray }
function Pause-End($msg = "Presiona Enter para cerrar") { Write-Host ""; Read-Host $msg | Out-Null }
function Test-Cmd($cmd) { [bool](Get-Command $cmd -ErrorAction SilentlyContinue) }

function Ensure-Administrator {
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).
        IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if ($isAdmin) { return }

    Write-Warn "Se requieren permisos de administrador. Relanzando..."
    $scriptPath = if ($PSCommandPath) { $PSCommandPath } else { $MyInvocation.MyCommand.Path }
    $argList = @(
        "-NoExit",
        "-ExecutionPolicy", "Bypass",
        "-File", "`"$scriptPath`"",
        "-ProfileName", "`"$ProfileName`"",
        "-ManifestPath", "`"$ManifestPath`"",
        "-ProfileEnvPath", "`"$ProfileEnvPath`"",
        "-OsTemplatePath", "`"$OsTemplatePath`""
    ) -join " "

    try {
        if (Test-Cmd "pwsh") {
            Start-Process -FilePath "pwsh" -Verb RunAs -ArgumentList $argList | Out-Null
        } else {
            Start-Process -FilePath "powershell" -Verb RunAs -ArgumentList $argList | Out-Null
        }
    } catch {
        Write-Err "No se pudo relanzar como administrador: $_"
    }
    exit
}

function Refresh-Path {
    $machine = Get-MachinePathValue
    $user = [Environment]::GetEnvironmentVariable("Path", "User")
    $env:Path = "$machine;$user"
}

function Get-MachinePathValue {
    $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment"
    try {
        return (Get-ItemProperty -Path $registryPath -Name Path -ErrorAction Stop).Path
    } catch {
        return [Environment]::GetEnvironmentVariable("Path", "Machine")
    }
}

function Set-MachinePathValue {
    param([string]$Value)
    $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment"
    try {
        Set-ItemProperty -Path $registryPath -Name Path -Value $Value -ErrorAction Stop
    } catch {
        try {
            [Environment]::SetEnvironmentVariable("Path", $Value, "Machine")
        } catch {
            $escaped = $Value.Replace("^", "^^").Replace("&", "^&")
            & reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path /t REG_EXPAND_SZ /d $escaped /f | Out-Null
        }
    }
}

function Add-ToMachinePath {
    param([string]$NewPath)
    if (-not $NewPath -or -not (Test-Path $NewPath)) { return }
    $current = Get-MachinePathValue
    $parts = @()
    if ($current) { $parts = $current -split ";" | Where-Object { $_ } }
    if ($parts | Where-Object { $_.TrimEnd("\") -eq $NewPath.TrimEnd("\") }) { return }
    Set-MachinePathValue -Value (($parts + $NewPath) -join ";")
    $env:Path += ";$NewPath"
    $script:AddedMachinePaths.Add($NewPath)
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
        [string]$PostInstallPath = "",
        [bool]$AskBeforeInstall = $false,
        [bool]$AskBeforeUpdate = $false
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
            if (-not $AskBeforeUpdate -or (Prompt-YesNo "Hay una actualizacion disponible para $Label. Deseas actualizarlo?" $true)) {
                winget upgrade --id $Id --accept-package-agreements --accept-source-agreements --silent
                Write-OK "$Label actualizado."
                $script:WingetUpgradedIds.Add($Id)
            } else {
                Write-Info "Se conserva la version actual de $Label."
            }
        }
    } else {
        if (-not $AskBeforeInstall -or (Prompt-YesNo "$Label no esta instalado. Deseas instalarlo?" $true)) {
            Write-Warn "$Label no encontrado. Instalando la version mas reciente compatible..."
            winget install --id $Id --accept-package-agreements --accept-source-agreements --silent
            Write-OK "$Label instalado."
            $script:WingetInstalledIds.Add($Id)
        } else {
            throw "$Label es obligatorio para continuar."
        }
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
        Write-Info "Actualizando Poppler al ultimo release disponible..."
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

function Ensure-OllamaModel {
    param([string]$ModelName)
    Write-Info "Verificando modelo $ModelName..."
    $tags = Invoke-RestMethod -Uri "http://localhost:11434/api/tags" -TimeoutSec 10
    $names = @($tags.models | ForEach-Object { $_.name })
    if ($names -contains $ModelName) {
        Write-OK "Modelo $ModelName ya disponible."
    } else {
        Write-Warn "Modelo $ModelName no encontrado. Descargando..."
        & ollama pull $ModelName
        Write-OK "Modelo $ModelName listo."
    }
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
        embedding_provider = $Manifest.embedding_provider
        embedding_model = $Manifest.embedding_model
        pip_requirement_files = @($Manifest.python_requirement_files)
        paths_added = @($script:AddedMachinePaths)
        winget_installed_ids = @($script:WingetInstalledIds)
        winget_upgraded_ids = @($script:WingetUpgradedIds)
        managed_directories = @("C:\poppler")
        updated_at = (Get-Date).ToString("s")
        quality_extras = [bool]$Manifest.quality_extras
    } | ConvertTo-Json
    Set-Content -Path $stateFile -Value $state -Encoding UTF8
}

try {
    Ensure-Administrator

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

    Write-Step "1/5 Python"
    Winget-Ensure -Id "Python.Python.3.12" -Label "Python 3.12" -VerifyCommand "python" -AskBeforeInstall $true -AskBeforeUpdate $true
    $pyExe = if (Test-Cmd "python") { "python" } elseif (Test-Cmd "py") { "py" } else { $null }
    if (-not $pyExe) { throw "Python no esta disponible tras la instalacion." }

    $pyExePath = & $pyExe -c "import sys; print(sys.executable)" 2>$null
    $pyScripts = & $pyExe -c "import sysconfig; print(sysconfig.get_path('scripts'))" 2>$null
    if ($pyExePath) { Add-ToMachinePath (Split-Path $pyExePath) }
    if ($pyScripts) { Add-ToMachinePath $pyScripts }

    Write-Step "2/5 Dependencias Python"
    & $pyExe -m pip install --upgrade pip --quiet --disable-pip-version-check
    foreach ($reqFile in $manifest.python_requirement_files) {
        Write-Info "Instalando paquetes desde $reqFile"
        & $pyExe -m pip install -r $reqFile --no-warn-script-location
    }

    Write-Step "3/5 Tesseract y Poppler"
    Winget-Ensure -Id "UB-Mannheim.TesseractOCR" -Label "Tesseract OCR" -VerifyCommand "tesseract" -PostInstallPath "C:\Program Files\Tesseract-OCR"
    Install-OrUpdate-Poppler

    Write-Step "4/5 Ollama y modelo"
    Winget-Ensure -Id "Ollama.Ollama" -Label "Ollama" -VerifyCommand "ollama" -AskBeforeInstall $true -AskBeforeUpdate $true
    try {
        $null = Invoke-RestMethod -Uri "http://localhost:11434/api/tags" -TimeoutSec 3
        Write-OK "Ollama ya estaba corriendo."
    } catch {
        Write-Info "Iniciando Ollama..."
        Start-Process -FilePath "ollama" -ArgumentList "serve" -WindowStyle Hidden
        Start-Sleep -Seconds 5
    }
    Ensure-OllamaModel -ModelName $manifest.ollama_model
    if ($manifest.embedding_provider -eq "ollama" -and $manifest.embedding_model -and $manifest.embedding_model -ne $manifest.ollama_model) {
        Ensure-OllamaModel -ModelName $manifest.embedding_model
    }

    Write-Step "5/5 Configuracion del entorno"
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
