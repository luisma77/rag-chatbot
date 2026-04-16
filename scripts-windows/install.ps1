#Requires -Version 5.1
# install.ps1 -- Instalacion completa del RAG Chatbot en Windows
# Uso: doble-click en run-install.bat  (solicita admin automaticamente)
#      O desde PowerShell 7 como admin: pwsh -ExecutionPolicy Bypass -File scripts-windows\install.ps1

param(
    [switch]$SkipOllama,
    [switch]$SkipTesseract,
    [switch]$SkipPoppler
)

# ── Encoding UTF-8 ────────────────────────────────────────────────────────────
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
chcp 65001 | Out-Null

$ErrorActionPreference = "Continue"

# ── Helpers ───────────────────────────────────────────────────────────────────
function Write-Step($msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }
function Write-OK($msg)   { Write-Host "  [OK] $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "  [!!] $msg" -ForegroundColor Yellow }
function Write-Err($msg)  { Write-Host "  [ERROR] $msg" -ForegroundColor Red }
function Write-Info($msg) { Write-Host "  ... $msg" -ForegroundColor Gray }
function Test-Cmd($cmd)   { return [bool](Get-Command $cmd -ErrorAction SilentlyContinue) }

function Refresh-Path {
    Write-Info "Recargando PATH del sistema..."
    $machine = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    $user    = [System.Environment]::GetEnvironmentVariable("Path", "User")
    if (-not $machine) { $machine = "" }
    if (-not $user)    { $user    = "" }
    $env:Path = "$machine;$user"
    Write-Info "PATH recargado."
}

# Añade una ruta al PATH del SISTEMA (Machine scope — requiere admin)
function Add-ToMachinePath {
    param([string]$NewPath)
    if (-not $NewPath -or -not (Test-Path $NewPath)) {
        Write-Warn "Ruta no existe en disco, no se añade al PATH: $NewPath"
        return $false
    }
    $current = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    if (-not $current) { $current = "" }
    $parts = $current -split ";" | Where-Object { $_ -ne "" }
    # Normalizar para comparar sin barra final
    $norm = $NewPath.TrimEnd("\")
    $already = $parts | Where-Object { $_.TrimEnd("\") -eq $norm }
    if ($already) {
        Write-Info "Ya en PATH del sistema: $NewPath"
        return $false
    }
    $updated = ($parts + $NewPath) -join ";"
    [System.Environment]::SetEnvironmentVariable("Path", $updated, "Machine")
    $env:Path += ";$NewPath"
    Write-OK "Añadido al PATH del sistema: $NewPath"
    return $true
}

# Detecta el ejecutable real de Python (descarta stub de Microsoft Store y AppData)
function Find-SystemPython {
    Write-Info "Buscando Python en PATH..."
    foreach ($cmd in @("python", "py", "python3")) {
        $found = Get-Command $cmd -ErrorAction SilentlyContinue
        if (-not $found) { continue }
        try {
            $ver = & $cmd --version 2>&1
            if ($ver -notmatch "Python 3\.\d+") { continue }
            # Obtener ruta real del ejecutable
            $exePath = & $cmd -c "import sys; print(sys.executable)" 2>$null
            if (-not $exePath) { $exePath = $found.Source }
            Write-Info "Encontrado: $cmd -> $exePath ($ver)"
            # Descartar si esta en AppData o WindowsApps (usuario/Store)
            if ($exePath -like "*AppData*" -or $exePath -like "*WindowsApps*") {
                Write-Warn "Python en ambito USUARIO (AppData) -- se ignorara: $exePath"
                Write-Info "Se instalara Python 3.12 para TODOS los usuarios (system-wide)."
                continue
            }
            return $cmd
        } catch {}
    }
    return $null
}

# ── Verificar admin ───────────────────────────────────────────────────────────
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host ""
    Write-Host "  Este instalador requiere privilegios de administrador." -ForegroundColor Yellow
    Write-Host "  Relanzando como administrador..." -ForegroundColor Cyan
    $argStr = "-NoExit -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    Start-Process pwsh -Verb RunAs -ArgumentList $argStr -ErrorAction SilentlyContinue
    if (-not $?) {
        Start-Process powershell -Verb RunAs -ArgumentList $argStr
    }
    exit
}

# ── Inicio ────────────────────────────────────────────────────────────────────
$repoRoot = Split-Path $PSScriptRoot -Parent
Set-Location $repoRoot

Write-Host ""
Write-Host "======================================================" -ForegroundColor Magenta
Write-Host "  RAG Chatbot -- Instalacion completa (Windows)" -ForegroundColor Magenta
Write-Host "  Ejecutando como Administrador" -ForegroundColor Green
Write-Host "======================================================" -ForegroundColor Magenta
Write-Host "  Directorio: $repoRoot"
Write-Host ""

$hasWinget = $false
if (Test-Cmd "winget") {
    try {
        $null = winget --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            $hasWinget = $true
            Write-Info "winget disponible."
        }
    } catch {}
}
if (-not $hasWinget) { Write-Info "winget no disponible -- se usaran descargas directas." }

# ── 0/6  PowerShell 7 ─────────────────────────────────────────────────────────
Write-Step "0/6  PowerShell 7"
if (Test-Cmd "pwsh") {
    $pwshVer = & pwsh --version 2>&1
    Write-OK "PowerShell 7 ya instalado: $pwshVer"
} else {
    Write-Warn "PowerShell 7 no encontrado. Instalando..."
    $ps7Installed = $false
    if ($hasWinget) {
        Write-Info "Instalando via winget..."
        winget install --id Microsoft.PowerShell --accept-package-agreements --accept-source-agreements --silent
        Refresh-Path
        if (Test-Cmd "pwsh") { $ps7Installed = $true; Write-OK "PowerShell 7 instalado via winget." }
    }
    if (-not $ps7Installed) {
        $ps7Url = "https://github.com/PowerShell/PowerShell/releases/download/v7.4.6/PowerShell-7.4.6-win-x64.msi"
        $ps7Msi = "$env:TEMP\PowerShell7.msi"
        Write-Info "Descargando PowerShell 7.4.6 desde GitHub..."
        try {
            Invoke-WebRequest -Uri $ps7Url -OutFile $ps7Msi -UseBasicParsing
            Write-Info "Instalando PowerShell 7 (silencioso)..."
            Start-Process msiexec -ArgumentList "/i `"$ps7Msi`" /quiet /norestart" -Wait
            Remove-Item $ps7Msi -ErrorAction SilentlyContinue
            Refresh-Path
            if (Test-Cmd "pwsh") { Write-OK "PowerShell 7 instalado." }
            else { Write-Warn "PS7 instalado -- reinicia el terminal para activarlo." }
        } catch {
            Write-Warn "No se pudo instalar PS7 automaticamente: $_"
            Write-Host "  Descarga manual: https://aka.ms/powershell" -ForegroundColor DarkYellow
        }
    }
}

# ── 1/6  Python ───────────────────────────────────────────────────────────────
Write-Step "1/6  Python 3.12 (instalacion para todos los usuarios)"
Refresh-Path
$script:pythonExe = Find-SystemPython

if (-not $script:pythonExe) {
    Write-Warn "Python system-wide no encontrado. Instalando Python 3.12..."
    $pyInstalled = $false

    # Intento 1: winget
    if ($hasWinget -and -not $pyInstalled) {
        Write-Info "Instalando Python 3.12 via winget (todos los usuarios)..."
        winget install --id Python.Python.3.12 --accept-package-agreements --accept-source-agreements --silent
        Refresh-Path
        $script:pythonExe = Find-SystemPython
        if ($script:pythonExe) { $pyInstalled = $true; Write-OK "Python instalado via winget." }
        else { Write-Warn "winget termino pero Python aun no se encuentra. Intentando descarga directa..." }
    }

    # Intento 2: descarga directa desde python.org (funciona en Windows Server sin winget)
    if (-not $pyInstalled) {
        $pyUrl = "https://www.python.org/ftp/python/3.12.9/python-3.12.9-amd64.exe"
        $pyExe  = "$env:TEMP\python-installer.exe"
        Write-Info "Descargando Python 3.12.9 desde python.org..."
        try {
            Invoke-WebRequest -Uri $pyUrl -OutFile $pyExe -UseBasicParsing
            Write-Info "Instalando Python 3.12.9 para todos los usuarios (silencioso)..."
            Write-Info "  Flags: InstallAllUsers=1 PrependPath=1 Include_test=0"
            Start-Process -FilePath $pyExe `
                -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1 Include_test=0" `
                -Wait
            Remove-Item $pyExe -ErrorAction SilentlyContinue
            Refresh-Path
            $script:pythonExe = Find-SystemPython
            if ($script:pythonExe) { $pyInstalled = $true }
            else { Write-Warn "Instalador termino pero Python no se encuentra aun en PATH del sistema." }
        } catch {
            Write-Err "No se pudo descargar Python: $_"
        }
    }

    if (-not $pyInstalled) {
        Write-Err "No se pudo instalar Python automaticamente."
        Write-Host ""
        Write-Host "  Instala manualmente desde: https://www.python.org/downloads/" -ForegroundColor Yellow
        Write-Host "  IMPORTANTE: marca 'Add python.exe to PATH' y 'Install for all users'." -ForegroundColor Yellow
        Write-Host ""
        Read-Host "Presiona Enter para salir"
        exit 1
    }
}

# Obtener ruta completa del ejecutable y asegurar ambas entradas en Machine PATH
$pyExePath = & $script:pythonExe -c "import sys; print(sys.executable)" 2>$null
$pyDir     = if ($pyExePath) { Split-Path $pyExePath } else { $null }
$pyScripts = & $script:pythonExe -c "import sysconfig; print(sysconfig.get_path('scripts'))" 2>$null

Write-OK "Python encontrado: $($script:pythonExe)"
Write-OK "Ejecutable: $pyExePath"
Write-OK "Version: $(& $script:pythonExe --version 2>&1)"

Write-Info "Garantizando python.exe en PATH del sistema..."
if ($pyDir)     { Add-ToMachinePath $pyDir     | Out-Null }
if ($pyScripts) {
    Write-Info "Garantizando Scripts de pip en PATH del sistema..."
    Add-ToMachinePath $pyScripts | Out-Null
}
Refresh-Path

# ── 2/6  pip packages ─────────────────────────────────────────────────────────
Write-Step "2/6  Dependencias Python (pip)"
Write-Info "Actualizando pip..."
& $script:pythonExe -m pip install --upgrade pip --quiet --disable-pip-version-check
Write-Info "Instalando paquetes de requirements.txt (113 paquetes aprox.)..."
& $script:pythonExe -m pip install -r requirements.txt --no-warn-script-location
if ($LASTEXITCODE -ne 0) {
    Write-Err "Fallo pip install. Revisa los errores arriba."
} else {
    Write-OK "Todos los paquetes Python instalados correctamente."
    # Re-asegurar Scripts en PATH (pip puede instalar en dir diferente)
    $pyScripts2 = & $script:pythonExe -c "import sysconfig; print(sysconfig.get_path('scripts'))" 2>$null
    if ($pyScripts2 -and $pyScripts2 -ne $pyScripts) {
        Write-Info "Garantizando directorio Scripts actualizado en PATH del sistema..."
        Add-ToMachinePath $pyScripts2 | Out-Null
    }
}
Refresh-Path

# ── 3/6  Tesseract OCR ────────────────────────────────────────────────────────
if (-not $SkipTesseract) {
    Write-Step "3/6  Tesseract OCR"
    Refresh-Path
    if (Test-Cmd "tesseract") {
        Write-OK "Tesseract ya instalado: $(tesseract --version 2>&1 | Select-Object -First 1)"
        Write-Info "Garantizando Tesseract en PATH del sistema..."
        Add-ToMachinePath "C:\Program Files\Tesseract-OCR" | Out-Null
    } else {
        $tessInstalled = $false

        # Intento 1: winget
        if ($hasWinget) {
            Write-Info "Instalando Tesseract via winget..."
            winget install --id UB-Mannheim.TesseractOCR `
                --accept-package-agreements --accept-source-agreements --silent
            Refresh-Path
            if (Test-Cmd "tesseract") {
                $tessInstalled = $true
                Write-OK "Tesseract instalado via winget."
            } else {
                Write-Warn "winget termino pero tesseract no encontrado. Intentando descarga directa..."
            }
        }

        # Intento 2: descarga directa UB Mannheim
        if (-not $tessInstalled) {
            $tessUrl = "https://digi.bib.uni-mannheim.de/tesseract/tesseract-ocr-w64-setup-5.5.0.20241111.exe"
            $tessSetup = "$env:TEMP\tesseract-setup.exe"
            Write-Info "Descargando Tesseract 5.5 desde UB Mannheim..."
            try {
                Invoke-WebRequest -Uri $tessUrl -OutFile $tessSetup -UseBasicParsing
                Write-Info "Instalando Tesseract 5.5 (silencioso)..."
                Start-Process -FilePath $tessSetup `
                    -ArgumentList "/S /D=C:\Program Files\Tesseract-OCR" -Wait
                Remove-Item $tessSetup -ErrorAction SilentlyContinue
                Refresh-Path
                if (Test-Cmd "tesseract") {
                    $tessInstalled = $true
                    Write-OK "Tesseract instalado via descarga directa."
                }
            } catch {
                Write-Warn "No se pudo descargar Tesseract: $_"
                Write-Host "  Instala manualmente: https://github.com/UB-Mannheim/tesseract/wiki" -ForegroundColor DarkYellow
            }
        }

        if ($tessInstalled) {
            Write-Info "Añadiendo Tesseract al PATH del sistema..."
            Add-ToMachinePath "C:\Program Files\Tesseract-OCR" | Out-Null
        }
    }

    # Paquetes de idioma
    $tessDataDir = "C:\Program Files\Tesseract-OCR\tessdata"
    if (-not (Test-Path $tessDataDir)) {
        $tessDataDir = "${env:ProgramFiles(x86)}\Tesseract-OCR\tessdata"
    }
    if (Test-Path $tessDataDir) {
        Write-Info "Verificando paquetes de idioma en: $tessDataDir"
        foreach ($lang in @("spa", "eng")) {
            $langFile = "$tessDataDir\$lang.traineddata"
            if (-not (Test-Path $langFile)) {
                Write-Info "Descargando paquete de idioma '$lang'..."
                $tempFile = "$env:TEMP\$lang.traineddata"
                try {
                    Invoke-WebRequest -Uri "https://github.com/tesseract-ocr/tessdata/raw/main/$lang.traineddata" `
                        -OutFile $tempFile -UseBasicParsing
                    Write-Info "Instalando $lang.traineddata en $tessDataDir..."
                    Copy-Item $tempFile $langFile -Force
                    Remove-Item $tempFile -ErrorAction SilentlyContinue
                    Write-OK "$lang.traineddata instalado correctamente."
                } catch {
                    Write-Warn "No se pudo instalar $lang.traineddata: $_"
                    Write-Host "  Ruta esperada: $langFile" -ForegroundColor DarkYellow
                }
            } else {
                Write-OK "$lang.traineddata ya existe en tessdata."
            }
        }
    } else {
        Write-Warn "Directorio tessdata no encontrado. Tesseract puede no haberse instalado bien."
    }
}

# ── 4/6  Poppler ──────────────────────────────────────────────────────────────
if (-not $SkipPoppler) {
    Write-Step "4/6  Poppler (conversion PDF a imagen para OCR)"
    $popplerBin = $null
    foreach ($candidate in @("C:\poppler\Library\bin", "C:\poppler\bin")) {
        if (Test-Path "$candidate\pdftoppm.exe") { $popplerBin = $candidate; break }
    }

    if ($popplerBin) {
        Write-OK "Poppler ya instalado en: $popplerBin"
        Write-Info "Garantizando Poppler en PATH del sistema..."
        Add-ToMachinePath $popplerBin | Out-Null
    } else {
        $popplerUrl = "https://github.com/oschwartz10612/poppler-windows/releases/download/v24.02.0-0/Release-24.02.0-0.zip"
        $popplerZip = "$env:TEMP\poppler.zip"
        Write-Info "Descargando Poppler para Windows desde GitHub..."
        try {
            Invoke-WebRequest -Uri $popplerUrl -OutFile $popplerZip -UseBasicParsing
            Write-Info "Extrayendo Poppler en C:\poppler\ ..."
            Expand-Archive -Path $popplerZip -DestinationPath "$env:TEMP\poppler-extract" -Force
            $dir = Get-ChildItem "$env:TEMP\poppler-extract" -Directory | Select-Object -First 1
            if (Test-Path "C:\poppler") { Remove-Item "C:\poppler" -Recurse -Force }
            Move-Item $dir.FullName "C:\poppler" -Force
            Remove-Item $popplerZip, "$env:TEMP\poppler-extract" -Recurse -Force -ErrorAction SilentlyContinue

            $popplerBin = if (Test-Path "C:\poppler\Library\bin\pdftoppm.exe") {
                "C:\poppler\Library\bin"
            } else { "C:\poppler\bin" }

            Write-Info "Añadiendo Poppler al PATH del sistema: $popplerBin"
            Add-ToMachinePath $popplerBin | Out-Null
            Write-OK "Poppler instalado en: $popplerBin"
        } catch {
            Write-Err "No se pudo instalar Poppler: $_"
            Write-Warn "Los PDFs escaneados (sin texto) no se podran indexar."
        }
    }
}

# ── 5/6  Ollama ───────────────────────────────────────────────────────────────
if (-not $SkipOllama) {
    Write-Step "5/6  Ollama + modelo qwen2.5:3b"
    Refresh-Path

    $ollamaExe = $null
    if (Test-Cmd "ollama") {
        $ollamaExe = "ollama"
        Write-OK "Ollama ya instalado: $(ollama --version 2>&1 | Select-Object -First 1)"
    } else {
        Write-Info "Descargando instalador de Ollama..."
        $ollamaInstaller = "$env:TEMP\OllamaSetup.exe"
        try {
            Invoke-WebRequest -Uri "https://ollama.com/download/OllamaSetup.exe" `
                -OutFile $ollamaInstaller -UseBasicParsing
            Write-Info "Instalando Ollama (silencioso)..."
            Start-Process -FilePath $ollamaInstaller -ArgumentList "/S" -Wait
            Start-Sleep -Seconds 5
            Refresh-Path

            $ollamaCandidates = @(
                "ollama",
                "C:\ollama\ollama.exe",
                "$env:LOCALAPPDATA\Programs\Ollama\ollama.exe",
                "$env:ProgramFiles\Ollama\ollama.exe",
                "C:\Program Files\Ollama\ollama.exe"
            )
            foreach ($c in $ollamaCandidates) {
                if (Test-Cmd $c) { $ollamaExe = $c; break }
                if (Test-Path $c -ErrorAction SilentlyContinue) { $ollamaExe = $c; break }
            }

            if ($ollamaExe) {
                Write-OK "Ollama instalado: $ollamaExe"
                $ollamaDir = if ($ollamaExe -eq "ollama") { $null } else { Split-Path $ollamaExe }
                if ($ollamaDir) {
                    Write-Info "Añadiendo Ollama al PATH del sistema: $ollamaDir"
                    Add-ToMachinePath $ollamaDir | Out-Null
                }
            } else {
                Write-Warn "Ollama instalado pero no encontrado en PATH. Reinicia el terminal."
            }
        } catch {
            Write-Err "No se pudo descargar Ollama: $_"
        }
    }

    if ($ollamaExe) {
        Write-Info "Iniciando servidor Ollama en segundo plano..."
        Start-Process -FilePath $ollamaExe -ArgumentList "serve" -WindowStyle Hidden
        Start-Sleep -Seconds 5
        Write-Info "Descargando modelo qwen2.5:3b (~2.1 GB -- puede tardar varios minutos)..."
        & $ollamaExe pull qwen2.5:3b
        if ($LASTEXITCODE -eq 0) { Write-OK "Modelo qwen2.5:3b descargado y listo." }
        else { Write-Warn "Error descargando modelo. Ejecuta manualmente: ollama pull qwen2.5:3b" }
    }
}

# ── 6/6  Entorno ──────────────────────────────────────────────────────────────
Write-Step "6/6  Configurando entorno del proyecto"

if (-not (Test-Path ".env")) {
    Write-Info "Creando .env desde .env.example..."
    Copy-Item ".env.example" ".env"
    Write-OK ".env creado."
} else {
    Write-OK ".env ya existe -- no se sobreescribe."
}

foreach ($dir in @("data\documents", "chroma_db", "logs")) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-OK "Directorio creado: $dir"
    } else {
        Write-Info "Directorio ya existe: $dir"
    }
}

# Actualizar TESSERACT_CMD en .env
$tessExe = "C:\Program Files\Tesseract-OCR\tesseract.exe"
if (Test-Path $tessExe) {
    Write-Info "Actualizando TESSERACT_CMD en .env: $tessExe"
    $envContent = Get-Content ".env" -Raw
    $envContent = $envContent -replace 'TESSERACT_CMD=.*', "TESSERACT_CMD=$tessExe"
    Set-Content ".env" $envContent -Encoding UTF8
    Write-OK "TESSERACT_CMD actualizado en .env"
}

# Actualizar POPPLER_PATH en .env
if ($popplerBin -and (Test-Path $popplerBin)) {
    Write-Info "Actualizando POPPLER_PATH en .env: $popplerBin"
    $envContent = Get-Content ".env" -Raw
    $envContent = $envContent -replace 'POPPLER_PATH=.*', "POPPLER_PATH=$popplerBin"
    Set-Content ".env" $envContent -Encoding UTF8
    Write-OK "POPPLER_PATH actualizado en .env"
}

# Resumen final del PATH del sistema
Write-Host ""
Write-Host "  ── PATH del sistema tras instalacion ──────────────────" -ForegroundColor DarkCyan
$machinePath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
foreach ($p in ($machinePath -split ";")) {
    if ($p -match "Python|Tesseract|poppler|ollama|Ollama|PowerShell" -and $p -ne "") {
        Write-Host "  + $p" -ForegroundColor Green
    }
}
Write-Host "  ────────────────────────────────────────────────────────" -ForegroundColor DarkCyan

Write-Host ""
Write-Host "======================================================" -ForegroundColor Green
Write-Host "  INSTALACION COMPLETADA" -ForegroundColor Green
Write-Host "======================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Siguiente paso -- iniciar el chatbot:" -ForegroundColor White
Write-Host "    Doble-click en:  run-chatbot.bat" -ForegroundColor Cyan
Write-Host "    O ejecuta:       pwsh -File scripts-windows\watch-and-serve.ps1" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Chat (cuando este corriendo):" -ForegroundColor White
Write-Host "    http://localhost:8000/static/chat.html" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Documentacion API:" -ForegroundColor White
Write-Host "    http://localhost:8000/docs" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Coloca documentos en:" -ForegroundColor White
Write-Host "    data\documents\   (PDF, DOCX, XLSX, PPTX, TXT...)" -ForegroundColor Cyan
Write-Host ""

Read-Host "Presiona Enter para cerrar"
