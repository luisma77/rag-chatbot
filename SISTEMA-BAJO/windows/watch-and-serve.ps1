param()
$repoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
& "$repoRoot\common\scripts\windows\watch-and-serve.ps1" `
    -ProfileName "SISTEMA-BAJO" `
    -ProfileEnvPath "$repoRoot\common\env\sistema-bajo.env"
