# reindex-all.ps1 — Wipe ChromaDB and reindex all documents from scratch
# Use when: adding/removing many documents, after changing chunk settings,
#           or when the index is suspected to be corrupt.
#
# WARNING: This deletes ALL existing embeddings and regenerates them.
#          The service stays UP during reindex (no downtime).
#
# Usage: .\scripts\reindex-all.ps1
# Usage (no confirmation): .\scripts\reindex-all.ps1 -Force

param(
    [string]$ApiPort = "8000",
    [switch]$Force
)

if (-not $Force) {
    $confirm = Read-Host "AVISO: Esto borrara todos los embeddings y reindexara desde cero. Continuar? (s/N)"
    if ($confirm -notin @("s", "S")) {
        Write-Host "Cancelado." -ForegroundColor Yellow
        exit 0
    }
}

Write-Host "Iniciando reindexado completo..." -ForegroundColor Cyan
$start = Get-Date

try {
    $result = Invoke-RestMethod `
        -Uri "http://localhost:$ApiPort/reindex" `
        -Method POST `
        -TimeoutSec 3600

    $elapsed = [math]::Round(((Get-Date) - $start).TotalSeconds, 1)
    Write-Host "`nReindexado completado en ${elapsed}s:" -ForegroundColor Green
    Write-Host "  Archivos procesados: $($result.total)"
    Write-Host "  Indexados OK:        $($result.ok)"
    Write-Host "  Con errores:         $($result.total - $result.ok)"

    if ($result.results) {
        $errors = $result.results | Where-Object { $_.status -eq "error" }
        if ($errors) {
            Write-Host "`nArchivos con error:" -ForegroundColor Red
            $errors | ForEach-Object { Write-Host "  - $($_.source): $($_.error)" }
        }
    }
} catch {
    Write-Host "Error durante el reindexado: $_" -ForegroundColor Red
    exit 1
}
