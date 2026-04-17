param()
$repoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
& "$repoRoot\common\scripts\windows\install.ps1" `
    -ProfileName "SISTEMA-BAJO" `
    -ManifestPath "$repoRoot\common\manifests\sistema-bajo.json" `
    -ProfileEnvPath "$repoRoot\common\env\sistema-bajo.env" `
    -OsTemplatePath "$repoRoot\SISTEMA-BAJO\windows\templates\.env"
