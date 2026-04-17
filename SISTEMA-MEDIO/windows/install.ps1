param()
$repoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
& "$repoRoot\common\scripts\windows\install.ps1" `
    -ProfileName "SISTEMA-MEDIO" `
    -ManifestPath "$repoRoot\common\manifests\sistema-medio.json" `
    -ProfileEnvPath "$repoRoot\common\env\sistema-medio.env" `
    -OsTemplatePath "$repoRoot\SISTEMA-MEDIO\windows\templates\.env"
