#Requires -Version 5.1
param()
$repoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
& "$repoRoot\common\scripts\windows\watch-and-serve.ps1" `
    -ProfileName "SISTEMA-BAJO" `
    -ProfileEnvPath "$repoRoot\common\env\profiles\sistema-bajo.env" `
    -ReindexHelperPath "$repoRoot\SISTEMA-BAJO\reindex_helper.py"
