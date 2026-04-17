param()
$repoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
& "$repoRoot\common\scripts\windows\uninstall.ps1" `
    -ProfileName "SISTEMA-MEDIO" `
    -ManifestPath "$repoRoot\common\manifests\sistema-medio.json"
