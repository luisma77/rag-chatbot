#Requires -Version 5.1
param()
$repoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
& "$repoRoot\common\scripts\windows\install.ps1" `
    -ProfileName "SISTEMA-ALTO" `
    -ManifestPath "$repoRoot\common\manifests\sistema-alto.json" `
    -ProfileEnvPath "$repoRoot\common\env\profiles\sistema-alto.env" `
    -OsTemplatePath "$repoRoot\common\env\os\windows.env"
