$module = Get-Module Plumber
if (-not $module) {
    $module = Import-Module (Join-Path $PSScriptRoot 'Plumber.psd1') -PassThru
}

. (Get-PlumberTaskLoader) -Config @{
    ModuleManifest = 'Plumber.psd1'
}
