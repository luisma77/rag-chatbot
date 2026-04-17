#Requires -Version 5.1
param()
$repoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
& "$repoRoot\common\scripts\windows\uninstall.ps1" `
    -ProfileName "SISTEMA-ALTO" `
    -ManifestPath "$repoRoot\common\manifests\sistema-alto.json"
