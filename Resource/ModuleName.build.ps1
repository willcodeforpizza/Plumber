$module = Get-Module Plumber
if (-not $module) {
    $module = Import-Module Plumber -PassThru
}

. (Get-PlumberTaskLoader) -Config @{
    # Required, case sensitive name of the psd1 file of the module
    ModuleManifest = 'ModuleName.psd1'
}
