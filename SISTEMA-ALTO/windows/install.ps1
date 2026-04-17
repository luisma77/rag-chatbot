param()
$repoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
& "$repoRoot\common\scripts\windows\install.ps1" `
    -ProfileName "SISTEMA-ALTO" `
    -ManifestPath "$repoRoot\common\manifests\sistema-alto.json" `
    -ProfileEnvPath "$repoRoot\common\env\sistema-alto.env" `
    -OsTemplatePath "$repoRoot\SISTEMA-ALTO\windows\templates\.env"
