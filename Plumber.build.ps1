$module = Get-Module Plumber
if (-not $module) {
    $module = Import-Module (Join-Path $PSScriptRoot 'Plumber.psd1') -PassThru
}

Get-ChildItem (Join-Path $module.ModuleBase 'Tasks') -Recurse -File -Filter '*.ps1' |
    ForEach-Object {. $_.FullName}
