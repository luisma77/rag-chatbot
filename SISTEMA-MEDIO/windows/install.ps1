#Requires -Version 5.1
param()
$repoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
& "$repoRoot\common\scripts\windows\install.ps1" `
    -ProfileName "SISTEMA-MEDIO" `
    -ManifestPath "$repoRoot\common\manifests\sistema-medio.json" `
    -ProfileEnvPath "$repoRoot\common\env\profiles\sistema-medio.env" `
    -OsTemplatePath "$repoRoot\common\env\os\windows.env"
