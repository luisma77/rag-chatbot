#Requires -Version 5.1
param(
    [Parameter(Mandatory = $true)][string]$ProfileName,
    [Parameter(Mandatory = $true)][string]$ManifestPath
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
chcp 65001 | Out-Null
$ErrorActionPreference = "Continue"

function Write-Line([string]$msg, [string]$color = "White") { Write-Host "  $msg" -ForegroundColor $color }
function Pause-End { Write-Host ""; Read-Host "Presiona Enter para cerrar" | Out-Null }
function Test-Cmd([string]$Name) { [bool](Get-Command $Name -ErrorAction SilentlyContinue) }

try {
    $manifest = Get-Content $ManifestPath | ConvertFrom-Json
    Write-Host ""
    Write-Host "RAG Chatbot - Verificacion $ProfileName (Windows)" -ForegroundColor Magenta
    Write-Host ""

    Write-Line "Perfil objetivo: $($manifest.hardware_target)" "Cyan"
    Write-Line "Modelo esperado: $($manifest.ollama_model)" "Cyan"
    Write-Host ""

    foreach ($item in @(
        @{ Name = "Python"; Command = "python"; Alt = "py" },
        @{ Name = "Ollama"; Command = "ollama" },
        @{ Name = "Tesseract"; Command = "tesseract" },
        @{ Name = "Poppler"; Command = "pdftoppm"; Path = "C:\poppler\Library\bin\pdftoppm.exe" }
    )) {
        if ((Test-Cmd $item.Command) -or ($item.Alt -and (Test-Cmd $item.Alt)) -or ($item.Path -and (Test-Path $item.Path))) {
            Write-Line "[OK] $($item.Name) disponible" "Green"
        } else {
            Write-Line "[!!] $($item.Name) no encontrado" "Yellow"
        }
    }

    try {
        $tags = Invoke-RestMethod -Uri "http://localhost:11434/api/tags" -TimeoutSec 5
        $names = @($tags.models | ForEach-Object { $_.name })
        if ($names -contains $manifest.ollama_model) {
            Write-Line "[OK] Modelo $($manifest.ollama_model) disponible" "Green"
        } else {
            Write-Line "[!!] Modelo $($manifest.ollama_model) no descargado" "Yellow"
        }
    } catch {
        Write-Line "[!!] Ollama no esta respondiendo en localhost:11434" "Yellow"
    }

    if ($manifest.embedding_provider -eq "ollama" -and $manifest.embedding_model) {
        try {
            $tags = Invoke-RestMethod -Uri "http://localhost:11434/api/tags" -TimeoutSec 5
            $names = @($tags.models | ForEach-Object { $_.name })
            if ($names -contains $manifest.embedding_model) {
                Write-Line "[OK] Embedding model $($manifest.embedding_model) disponible" "Green"
            } else {
                Write-Line "[!!] Embedding model $($manifest.embedding_model) no descargado" "Yellow"
            }
        } catch {
            Write-Line "[!!] No se pudo verificar el modelo de embeddings de Ollama" "Yellow"
        }
    }

    if (Test-Path ".env") {
        Write-Line "[OK] .env presente" "Green"
    } else {
        Write-Line "[!!] .env no encontrado" "Yellow"
    }
} finally {
    Pause-End
}
