#Requires -Version 5.1
# watch-and-serve.ps1 -- Inicia el chatbot RAG y vigila la carpeta de documentos
# Uso: pwsh -ExecutionPolicy Bypass -File scripts-windows\watch-and-serve.ps1
# O doble-click: run-chatbot.bat

# IMPORTANTE: param() debe ir antes de cualquier codigo ejecutable
param(
    [string]$DocumentsPath = ".\data\documents",
    [string]$ApiPort = "8000",
    [int]$DebounceMs = 5000
)

# ── Encoding: forzar UTF-8 en la consola ─────────────────────────────────────
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
chcp 65001 | Out-Null

$ErrorActionPreference = "Continue"
$script:DebounceMs = $DebounceMs
$script:lastEvent = @{}
$script:fastapiProc = $null
$script:repoRoot = $null
$script:browserOpened = $false
$script:pythonExe = "python"   # se detecta dinamicamente abajo

function Write-Log {
    param([string]$Msg, [string]$Color = "White")
    $ts = Get-Date -Format "HH:mm:ss"
    Write-Host "[$ts] $Msg" -ForegroundColor $Color
}

function Refresh-EnvPath {
    $machine = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    $user    = [System.Environment]::GetEnvironmentVariable("Path", "User")
    $env:Path = "$machine;$user"
}

# Encuentra el ejecutable real de Python (descarta stub de AppData/Store, prefiere system-wide)
function Find-Python {
    # Primero buscar en ubicaciones system-wide conocidas
    $sysCandidates = Get-ChildItem "C:\Program Files\Python*" -ErrorAction SilentlyContinue |
        Sort-Object Name -Descending |
        ForEach-Object { Join-Path $_.FullName "python.exe" } |
        Where-Object { Test-Path $_ }
    foreach ($candidate in $sysCandidates) {
        try {
            $ver = & $candidate --version 2>&1
            if ($ver -match "Python 3\.\d+") {
                Write-Log "Python system-wide encontrado: $candidate ($ver)" "Green"
                return $candidate
            }
        } catch {}
    }
    # Fallback: buscar en PATH (descartando AppData/WindowsApps)
    foreach ($cmd in @("python", "py", "python3")) {
        $found = Get-Command $cmd -ErrorAction SilentlyContinue
        if (-not $found) { continue }
        try {
            $ver = & $cmd --version 2>&1
            if ($ver -notmatch "Python 3\.\d+") { continue }
            $exePath = & $cmd -c "import sys; print(sys.executable)" 2>$null
            if ($exePath -like "*AppData*" -or $exePath -like "*WindowsApps*") {
                Write-Log "Saltando Python de AppData (usuario): $exePath" "Yellow"
                continue
            }
            return $cmd
        } catch {}
    }
    return $null
}

function Find-Ollama {
    $candidates = @(
        "ollama"
        "C:\ollama\ollama.exe"
        "$env:LOCALAPPDATA\Programs\Ollama\ollama.exe"
        "$env:ProgramFiles\Ollama\ollama.exe"
        "C:\Program Files\Ollama\ollama.exe"
    )
    foreach ($c in $candidates) {
        if (Get-Command $c -ErrorAction SilentlyContinue) { return $c }
        if (Test-Path $c -ErrorAction SilentlyContinue)   { return $c }
    }
    return $null
}

function Stop-FastAPI {
    if ($null -ne $script:fastapiProc -and -not $script:fastapiProc.HasExited) {
        Write-Log "Parando FastAPI (PID $($script:fastapiProc.Id))..." "Yellow"
        Stop-Process -Id $script:fastapiProc.Id -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
    }
    # Kill any leftover uvicorn on this port
    $procs = Get-NetTCPConnection -LocalPort $ApiPort -ErrorAction SilentlyContinue |
             Where-Object { $_.State -eq "Listen" } |
             Select-Object -ExpandProperty OwningProcess
    foreach ($pid in $procs) {
        Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue
    }
    $script:fastapiProc = $null
    Write-Log "FastAPI parado." "Yellow"
}

function Start-FastAPI {
    Write-Log "Iniciando FastAPI en puerto $ApiPort..." "Cyan"
    $script:fastapiProc = Start-Process `
        -FilePath $script:pythonExe `
        -ArgumentList "-m uvicorn src.main:app --host 0.0.0.0 --port $ApiPort" `
        -WorkingDirectory $script:repoRoot `
        -PassThru `
        -WindowStyle Normal

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
        # Abre el navegador automaticamente la primera vez
        if (-not $script:browserOpened) {
            $script:browserOpened = $true
            Start-Process "http://localhost:$ApiPort/static/chat.html"
        }
    } else {
        Write-Log "AVISO: FastAPI no respondio. Revisa la ventana de Python." "Yellow"
    }
    return $ready
}

function Invoke-Reindex {
    param([string]$FilePath = "", [string]$Action = "")
    $helper = Join-Path $script:repoRoot "scripts\reindex_helper.py"
    if ($FilePath -ne "") {
        $fname = [IO.Path]::GetFileName($FilePath)
        Write-Log "Procesando archivo: $fname ($Action)" "Cyan"
        & $script:pythonExe $helper $FilePath $Action
    } else {
        Write-Log "Verificando documentos en: $DocumentsPath" "Cyan"
        & $script:pythonExe $helper
    }
}

# ── Inicio ────────────────────────────────────────────────────────────────────
$script:repoRoot = Split-Path $PSScriptRoot -Parent
Set-Location $script:repoRoot

Write-Host ""
Write-Host "RAG Chatbot - Iniciando" -ForegroundColor Magenta
Write-Host "Directorio: $($script:repoRoot)"
Write-Host ""

Refresh-EnvPath

# ── Detectar Python ───────────────────────────────────────────────────────────
$script:pythonExe = Find-Python
if (-not $script:pythonExe) {
    Write-Log "Python no encontrado. Ejecuta run-install.bat primero." "Red"
    Write-Log "Descarga Python desde: https://www.python.org/downloads/" "Yellow"
    Read-Host "Presiona Enter para salir"
    exit 1
}
Write-Log "Python: $script:pythonExe ($(& $script:pythonExe --version 2>&1))" "Green"

# ── Dependencias Python ───────────────────────────────────────────────────────
$reqFile = Join-Path $script:repoRoot "requirements.txt"
if (Test-Path $reqFile) {
    Write-Log "Verificando paquetes Python..." "Cyan"
    & $script:pythonExe -m pip install -r $reqFile --quiet --disable-pip-version-check 2>$null
    Write-Log "Paquetes Python listos." "Green"
}

# ── Ollama ────────────────────────────────────────────────────────────────────
Write-Log "Buscando Ollama..." "Cyan"
$ollamaExe = Find-Ollama

if ($null -ne $ollamaExe) {
    try {
        $null = Invoke-RestMethod -Uri "http://localhost:11434/api/tags" -TimeoutSec 3
        Write-Log "Ollama ya estaba corriendo." "Green"
    } catch {
        Write-Log "Iniciando Ollama..." "Cyan"
        Start-Process -FilePath $ollamaExe -ArgumentList "serve" -WindowStyle Hidden
        Start-Sleep -Seconds 4
    }
    try {
        $tags = Invoke-RestMethod -Uri "http://localhost:11434/api/tags" -TimeoutSec 10
        $n = $tags.models.Count
        Write-Log "Ollama activo - $n modelos cargados" "Green"
    } catch {
        Write-Log "AVISO: Ollama no responde. Ejecuta: ollama serve" "Yellow"
    }
} else {
    Write-Log "AVISO: Ollama no encontrado. Ejecuta run-install.bat primero." "Yellow"
}

# ── Indexacion inicial ────────────────────────────────────────────────────────
if (-not (Test-Path $DocumentsPath)) {
    New-Item -ItemType Directory -Path $DocumentsPath -Force | Out-Null
}
Invoke-Reindex

# ── Arrancar FastAPI ──────────────────────────────────────────────────────────
$null = Start-FastAPI

# ── FileSystemWatcher ─────────────────────────────────────────────────────────
$absPath = (Resolve-Path $DocumentsPath).Path
Write-Log "Vigilando carpeta: $absPath" "Cyan"
Write-Log "Al detectar cambios: para FastAPI, reindexar, reinicia FastAPI" "Gray"

$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $absPath
$watcher.IncludeSubdirectories = $true
$watcher.EnableRaisingEvents = $true

# Handler: stop → reindex → restart
$handler = {
    param($source, $e)
    $file = $e.FullPath
    $name = [IO.Path]::GetFileName($file)
    if ($name.StartsWith("~`$") -or $name.StartsWith(".")) { return }

    $action = $e.ChangeType.ToString().ToLower()
    $now = [DateTime]::Now
    if ($script:lastEvent.ContainsKey($file)) {
        if (($now - $script:lastEvent[$file]).TotalMilliseconds -lt $script:DebounceMs) { return }
    }
    $script:lastEvent[$file] = $now

    Write-Log "Cambio detectado: $name ($action)" "Yellow"
    Stop-FastAPI
    Invoke-Reindex -FilePath $file -Action $action
    $null = Start-FastAPI
}

$renamedHandler = {
    param($source, $e)
    $oldName = [IO.Path]::GetFileName($e.OldFullPath)
    $newName = [IO.Path]::GetFileName($e.FullPath)
    if ($oldName.StartsWith("~`$") -or $newName.StartsWith("~`$")) { return }

    $now = [DateTime]::Now
    $key = $e.FullPath
    if ($script:lastEvent.ContainsKey($key)) {
        if (($now - $script:lastEvent[$key]).TotalMilliseconds -lt $script:DebounceMs) { return }
    }
    $script:lastEvent[$key] = $now

    Write-Log "Archivo renombrado: $oldName -> $newName" "Yellow"
    Stop-FastAPI
    Invoke-Reindex -FilePath $e.OldFullPath -Action "deleted"
    Invoke-Reindex -FilePath $e.FullPath -Action "created"
    $null = Start-FastAPI
}

$ev1 = Register-ObjectEvent $watcher "Created" -Action $handler
$ev2 = Register-ObjectEvent $watcher "Changed" -Action $handler
$ev3 = Register-ObjectEvent $watcher "Deleted" -Action $handler
$ev4 = Register-ObjectEvent $watcher "Renamed" -Action $renamedHandler

Write-Host ""
Write-Log "*** Sistema RAG activo ***" "Green"
Write-Log "Documentos: $absPath" "Green"
Write-Log "Chat:       http://localhost:$ApiPort/static/chat.html" "Cyan"
Write-Log "API:        http://localhost:$ApiPort/docs" "Cyan"
Write-Log "Ctrl+C para detener todo." "Gray"
Write-Host ""

try {
    while ($true) { Start-Sleep -Seconds 5 }
} finally {
    Write-Log "Deteniendo servicios..." "Yellow"
    $watcher.EnableRaisingEvents = $false
    $watcher.Dispose()
    foreach ($ev in @($ev1, $ev2, $ev3, $ev4)) {
        Unregister-Event -SourceIdentifier $ev.Name -ErrorAction SilentlyContinue
    }
    Stop-FastAPI
    Write-Log "Servicios detenidos." "Yellow"
}
