#Requires -Version 5.1
param(
    [Parameter(Mandatory = $true)][string]$ProfileName,
    [Parameter(Mandatory = $true)][string]$ProfileEnvPath,
    [string]$ReindexHelperPath = "",
    [string]$DocumentsPath = ".\data\documents",
    [string]$ApiPort = "8000",
    [int]$DebounceMs = 5000
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
chcp 65001 | Out-Null
$ErrorActionPreference = "Stop"

$script:lastEvent = @{}
$script:fastapiProc = $null
$script:browserOpened = $false

function Write-Log([string]$Msg, [string]$Color = "White") {
    $ts = Get-Date -Format "HH:mm:ss"
    Write-Host "[$ts] $Msg" -ForegroundColor $Color
}

function Pause-End { Write-Host ""; Read-Host "Presiona Enter para cerrar" | Out-Null }

function Stop-FastAPI {
    if ($null -ne $script:fastapiProc -and -not $script:fastapiProc.HasExited) {
        Write-Log "Parando FastAPI (PID $($script:fastapiProc.Id))..." "Yellow"
        Stop-Process -Id $script:fastapiProc.Id -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
    }
    $script:fastapiProc = $null
}

function Start-FastAPI([string]$RepoRoot) {
    Write-Log "Iniciando FastAPI en puerto $ApiPort..." "Cyan"
    $script:fastapiProc = Start-Process -FilePath "python" -ArgumentList "-m uvicorn src.main:app --host 0.0.0.0 --port $ApiPort" -WorkingDirectory $RepoRoot -PassThru -WindowStyle Normal
    $ready = $false
    for ($i = 1; $i -le 30; $i++) {
        Start-Sleep -Seconds 2
        try {
            $null = Invoke-RestMethod -Uri "http://localhost:$ApiPort/health" -TimeoutSec 3
            $ready = $true
            break
        } catch {
            Write-Log "Esperando FastAPI... $i/30" "Gray"
        }
    }
    if ($ready) {
        Write-Log "FastAPI activo en http://localhost:$ApiPort" "Green"
        Write-Log "Chat local: http://localhost:$ApiPort/static/chat.html" "Cyan"
        if (-not $script:browserOpened) {
            $script:browserOpened = $true
            Start-Process "http://localhost:$ApiPort/static/chat.html"
        }
    } else {
        Write-Log "AVISO: FastAPI no respondio. Revisa la ventana de Python." "Yellow"
    }
}

function Invoke-Reindex([string]$RepoRoot, [string]$FilePath = "", [string]$Action = "") {
    $helper = if ($ReindexHelperPath) { $ReindexHelperPath } else { Join-Path $RepoRoot "common\scripts\reindex_helper.py" }
    if ($FilePath) {
        & python $helper $FilePath $Action
    } else {
        & python $helper
    }
}

try {
    $repoRoot = Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent
    Set-Location $repoRoot

    Write-Host ""
    Write-Host "RAG Chatbot - Iniciando $ProfileName (Windows)" -ForegroundColor Magenta
    Write-Host "Directorio: $repoRoot"
    Write-Host ""

    if (-not (Test-Path ".env")) {
        Write-Log "No existe .env. Ejecuta primero el instalador del perfil." "Red"
        exit 1
    }

    try {
        $null = Invoke-RestMethod -Uri "http://localhost:11434/api/tags" -TimeoutSec 3
        Write-Log "Ollama ya estaba corriendo." "Green"
    } catch {
        Write-Log "Iniciando Ollama..." "Cyan"
        Start-Process -FilePath "ollama" -ArgumentList "serve" -WindowStyle Hidden
        Start-Sleep -Seconds 5
    }

    if (-not (Test-Path $DocumentsPath)) { New-Item -ItemType Directory -Force -Path $DocumentsPath | Out-Null }
    Invoke-Reindex -RepoRoot $repoRoot
    Start-FastAPI -RepoRoot $repoRoot

    $absPath = (Resolve-Path $DocumentsPath).Path
    Write-Log "Vigilando carpeta: $absPath" "Cyan"
    Write-Log "Ctrl+C para detener. Se mantendra la ventana abierta al salir." "Gray"

    $watcher = New-Object System.IO.FileSystemWatcher
    $watcher.Path = $absPath
    $watcher.IncludeSubdirectories = $true
    $watcher.EnableRaisingEvents = $true

    $handler = {
        param($source, $e)
        $file = $e.FullPath
        $name = [IO.Path]::GetFileName($file)
        if ($name.StartsWith("~`$") -or $name.StartsWith(".")) { return }
        $action = $e.ChangeType.ToString().ToLower()
        $now = [DateTime]::Now
        if ($script:lastEvent.ContainsKey($file) -and (($now - $script:lastEvent[$file]).TotalMilliseconds -lt $DebounceMs)) { return }
        $script:lastEvent[$file] = $now
        Write-Log "Cambio detectado: $name ($action)" "Yellow"
        Stop-FastAPI
        Invoke-Reindex -RepoRoot $repoRoot -FilePath $file -Action $action
        Start-FastAPI -RepoRoot $repoRoot
    }

    Register-ObjectEvent $watcher Created -Action $handler | Out-Null
    Register-ObjectEvent $watcher Changed -Action $handler | Out-Null
    Register-ObjectEvent $watcher Deleted -Action $handler | Out-Null
    Register-ObjectEvent $watcher Renamed -Action {
        param($source, $e)
        Stop-FastAPI
        Invoke-Reindex -RepoRoot $repoRoot -FilePath $e.OldFullPath -Action "deleted"
        Invoke-Reindex -RepoRoot $repoRoot -FilePath $e.FullPath -Action "created"
        Start-FastAPI -RepoRoot $repoRoot
    } | Out-Null

    while ($true) { Wait-Event | Out-Null }
} catch {
    Write-Log "Error: $_" "Red"
    exit 1
} finally {
    Stop-FastAPI
    Pause-End
}
