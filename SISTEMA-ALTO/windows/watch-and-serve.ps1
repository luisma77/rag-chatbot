param()
$repoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
& "$repoRoot\common\scripts\windows\watch-and-serve.ps1" `
    -ProfileName "SISTEMA-ALTO" `
    -ProfileEnvPath "$repoRoot\common\env\profiles\sistema-alto.env"
