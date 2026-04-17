#Requires -Version 5.1
param()
$repoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
& "$repoRoot\common\scripts\windows\watch-and-serve.ps1" `
    -ProfileName "SISTEMA-MEDIO" `
    -ProfileEnvPath "$repoRoot\common\env\profiles\sistema-medio.env" `
    -ReindexHelperPath "$repoRoot\SISTEMA-MEDIO\reindex_helper.py"
