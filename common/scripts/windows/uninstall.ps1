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
function Prompt-YesNo([string]$Question, [bool]$DefaultYes = $false) {
    $suffix = if ($DefaultYes) { "[S/n]" } else { "[s/N]" }
    $answer = Read-Host "$Question $suffix"
    if ([string]::IsNullOrWhiteSpace($answer)) { return $DefaultYes }
    return $answer.Trim().ToLower().StartsWith("s") -or $answer.Trim().ToLower().StartsWith("y")
}
function Pause-End { Write-Host ""; Read-Host "Presiona Enter para cerrar" | Out-Null }

try {
    $repoRoot = Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent
    $manifest = Get-Content $ManifestPath | ConvertFrom-Json
    Set-Location $repoRoot

    Write-Host ""
    Write-Host "RAG Chatbot - Desinstalacion $ProfileName (Windows)" -ForegroundColor Magenta
    Write-Host ""

    if (Prompt-YesNo "Deseas eliminar el modelo $($manifest.ollama_model) de Ollama?" $true) {
        & ollama rm $manifest.ollama_model 2>$null
        Write-Log "[OK] Modelo eliminado si existia." "Green"
    }

    if (Prompt-YesNo "Deseas borrar chroma_db y logs generados por este perfil?" $false) {
        Remove-Item ".\chroma_db" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item ".\logs" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Log "[OK] Cache y logs eliminados." "Green"
    }

    if (Prompt-YesNo "Deseas borrar el .env actual?" $false) {
        Remove-Item ".\.env" -Force -ErrorAction SilentlyContinue
        Write-Log "[OK] .env eliminado." "Green"
    }

    $stateFile = Join-Path $repoRoot "install-state\$($manifest.profile_id)-windows.json"
    Remove-Item $stateFile -Force -ErrorAction SilentlyContinue
    Write-Log "[OK] Estado de instalacion eliminado." "Green"
    Write-Log "No se borran data/documents ni herramientas globales por seguridad." "Yellow"
} finally {
    Pause-End
}
