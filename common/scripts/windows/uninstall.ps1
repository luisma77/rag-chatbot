#Requires -Version 5.1
param(
    [Parameter(Mandatory = $true)][string]$ProfileName,
    [Parameter(Mandatory = $true)][string]$ManifestPath
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
chcp 65001 | Out-Null
$ErrorActionPreference = "Continue"

function Write-Log([string]$msg, [string]$color = "White") { Write-Host "  $msg" -ForegroundColor $color }
function Write-Warn([string]$msg) { Write-Host "  $msg" -ForegroundColor Yellow }
function Write-Info([string]$msg) { Write-Host "  $msg" -ForegroundColor Gray }

function Prompt-YesNo {
    param([string]$Question, [bool]$DefaultYes = $true)
    $suffix = if ($DefaultYes) { "[S/n]" } else { "[s/N]" }
    $answer = Read-Host "$Question $suffix"
    if ([string]::IsNullOrWhiteSpace($answer)) { return $DefaultYes }
    return $answer.Trim().ToLower().StartsWith("s") -or $answer.Trim().ToLower().StartsWith("y")
}

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
        "-ManifestPath", "`"$ManifestPath`""
    ) -join " "

    try {
        if (Get-Command pwsh -ErrorAction SilentlyContinue) {
            Start-Process -FilePath "pwsh" -Verb RunAs -ArgumentList $argList | Out-Null
        } else {
            Start-Process -FilePath "powershell" -Verb RunAs -ArgumentList $argList | Out-Null
        }
    } catch {
        Write-Host "  No se pudo relanzar como administrador: $_" -ForegroundColor Red
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

function Remove-FromMachinePath {
    param([string]$TargetPath)
    if (-not $TargetPath) { return }
    $current = Get-MachinePathValue
    if (-not $current) { return }
    $parts = $current -split ";" | Where-Object { $_ -and $_.TrimEnd("\") -ne $TargetPath.TrimEnd("\") }
    Set-MachinePathValue -Value ($parts -join ";")
}

function Winget-UninstallIfPresent {
    param([string]$Id, [string]$Label)
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) { return }
    $installed = winget list --id $Id --accept-source-agreements 2>$null
    if ($installed) {
        Write-Log "Desinstalando $Label..." "Yellow"
        winget uninstall --id $Id --accept-source-agreements --silent 2>$null | Out-Null
        Write-Log "[OK] $Label desinstalado si existia." "Green"
    }
}

function Get-InstalledPythonEntries {
    $roots = @(
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
    $entries = foreach ($root in $roots) {
        Get-ItemProperty -Path $root -ErrorAction SilentlyContinue | Where-Object {
            $_.DisplayName -match '^Python ' -or $_.DisplayName -match '^Python Launcher'
        } | Select-Object DisplayName, UninstallString, QuietUninstallString
    }
    return @($entries | Sort-Object DisplayName -Unique)
}

function Invoke-UninstallCommand {
    param([string]$CommandLine)
    if (-not $CommandLine) { return }
    $cmd = $CommandLine.Trim()
    if ($cmd -match 'MsiExec\.exe\s+/I\{([A-F0-9\-]+)\}') {
        $guid = $matches[1]
        Start-Process -FilePath "msiexec.exe" -ArgumentList "/x{$guid} /qn /norestart" -Wait -WindowStyle Hidden
        return
    }
    if ($cmd -match 'MsiExec\.exe\s+/X\{([A-F0-9\-]+)\}') {
        $guid = $matches[1]
        Start-Process -FilePath "msiexec.exe" -ArgumentList "/x{$guid} /qn /norestart" -Wait -WindowStyle Hidden
        return
    }
    if ($cmd.StartsWith('"')) {
        $exeEnd = $cmd.IndexOf('"', 1)
        if ($exeEnd -gt 1) {
            $exe = $cmd.Substring(1, $exeEnd - 1)
            $args = $cmd.Substring($exeEnd + 1).Trim()
            if ($args -notmatch '/quiet|/qn|/silent|/verysilent') {
                $args = "$args /quiet"
            }
            Start-Process -FilePath $exe -ArgumentList $args -Wait -WindowStyle Hidden
            return
        }
    }
    Start-Process -FilePath "cmd.exe" -ArgumentList "/c $cmd" -Wait -WindowStyle Hidden
}

function Uninstall-AllPython {
    $pythonEntries = Get-InstalledPythonEntries
    if (-not $pythonEntries -or $pythonEntries.Count -eq 0) {
        Write-Info "No se han encontrado instalaciones de Python en el sistema."
        return
    }

    foreach ($entry in $pythonEntries) {
        $commandToRun = if ($entry.QuietUninstallString) { $entry.QuietUninstallString } else { $entry.UninstallString }
        if (-not $commandToRun) { continue }
        Write-Log "Desinstalando $($entry.DisplayName)..." "Yellow"
        try {
            Invoke-UninstallCommand -CommandLine $commandToRun
            Write-Log "[OK] $($entry.DisplayName) desinstalado si existia." "Green"
        } catch {
            Write-Warn "No se pudo desinstalar automaticamente $($entry.DisplayName): $_"
        }
    }
}

try {
    Ensure-Administrator

    $repoRoot = Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent
    $manifest = Get-Content $ManifestPath | ConvertFrom-Json
    Set-Location $repoRoot
    $stateFile = Join-Path $repoRoot "install-state\$($manifest.profile_id)-windows.json"
    $state = $null
    if (Test-Path $stateFile) {
        try { $state = Get-Content $stateFile | ConvertFrom-Json } catch {}
    }

    Write-Host ""
    Write-Host "RAG Chatbot - Desinstalacion $ProfileName (Windows)" -ForegroundColor Magenta
    Write-Host ""

    $pythonEntries = Get-InstalledPythonEntries
    $hasPythonInstalled = ($pythonEntries.Count -gt 0) -or (Get-Command python -ErrorAction SilentlyContinue) -or (Get-Command py -ErrorAction SilentlyContinue)
    $hasOllamaInstalled = [bool](Get-Command ollama -ErrorAction SilentlyContinue)
    if (-not $hasOllamaInstalled -and (Get-Command winget -ErrorAction SilentlyContinue)) {
        $hasOllamaInstalled = [bool](winget list --id "Ollama.Ollama" --accept-source-agreements 2>$null)
    }

    $removePython = $false
    $removeOllama = $false
    if ($hasPythonInstalled) {
        $removePython = Prompt-YesNo "Deseas desinstalar todos los Python detectados en el sistema? Esto puede reiniciar o desestabilizar temporalmente el escritorio de Windows y puede requerir cerrar sesion." $true
    } else {
        Write-Info "No se detecta Python instalado. No se preguntara por Python."
    }
    if ($hasOllamaInstalled) {
        $removeOllama = Prompt-YesNo "Deseas desinstalar Ollama y sus modelos de este proyecto?" $true
    } else {
        Write-Info "No se detecta Ollama instalado. No se preguntara por Ollama."
    }

    $pyExe = if (Get-Command python -ErrorAction SilentlyContinue) { "python" } elseif (Get-Command py -ErrorAction SilentlyContinue) { "py" } else { $null }
    $reqFiles = @()
    if ($state -and $state.pip_requirement_files) {
        $reqFiles = @($state.pip_requirement_files)
    } else {
        $reqFiles = @($manifest.python_requirement_files)
    }
    foreach ($reqFile in $reqFiles) {
        if ($pyExe -and (Test-Path $reqFile)) {
            Write-Log "Desinstalando paquetes Python de $reqFile..." "Yellow"
            & $pyExe -m pip uninstall -y -r $reqFile 2>$null | Out-Null
        }
    }

    if ($removeOllama -and (Get-Command ollama -ErrorAction SilentlyContinue)) {
        & ollama rm $manifest.ollama_model 2>$null | Out-Null
        Write-Log "[OK] Modelo $($manifest.ollama_model) eliminado si existia." "Green"
        if ($manifest.embedding_provider -eq "ollama" -and $manifest.embedding_model -and $manifest.embedding_model -ne $manifest.ollama_model) {
            & ollama rm $manifest.embedding_model 2>$null | Out-Null
            Write-Log "[OK] Modelo de embeddings $($manifest.embedding_model) eliminado si existia." "Green"
        }
    }

    $managedDirs = @("C:\poppler")
    if ($state -and $state.managed_directories) { $managedDirs = @($state.managed_directories) }
    foreach ($dir in $managedDirs) {
        if (Test-Path $dir) {
            Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
            Write-Log "[OK] Directorio gestionado eliminado: $dir" "Green"
        }
    }

    $pathEntries = @()
    if ($state -and $state.paths_added) { $pathEntries = @($state.paths_added) }
    foreach ($pathEntry in $pathEntries) {
        Remove-FromMachinePath $pathEntry
    }
    Remove-FromMachinePath "C:\Program Files\Tesseract-OCR"
    Remove-FromMachinePath "C:\poppler\Library\bin"
    Refresh-Path

    Winget-UninstallIfPresent -Id "UB-Mannheim.TesseractOCR" -Label "Tesseract OCR"
    if ($removeOllama) { Winget-UninstallIfPresent -Id "Ollama.Ollama" -Label "Ollama" }
    if ($removePython) { Uninstall-AllPython }

    Remove-Item ".\chroma_db" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item ".\logs" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item ".\.env" -Force -ErrorAction SilentlyContinue
    Remove-Item $stateFile -Force -ErrorAction SilentlyContinue
    Write-Log "[OK] Cache, logs, .env y estado de instalacion eliminados." "Green"
    Write-Log "No se borra data/documents para no tocar documentos del usuario." "Yellow"
} catch {
    Write-Log "Error durante la desinstalacion: $_" "Red"
    exit 1
}
