param()
$repoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
& "$repoRoot\common\scripts\windows\check-requirements.ps1" `
    -ProfileName "SISTEMA-BAJO" `
    -ManifestPath "$repoRoot\common\manifests\sistema-bajo.json"
