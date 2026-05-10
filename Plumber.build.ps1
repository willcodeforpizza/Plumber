$module = Get-Module Plumber
if (-not $module) {
    $module = Import-Module (Join-Path $PSScriptRoot 'Plumber.psd1') -PassThru
}

. (Get-PlumberTaskLoader) -Config @{
    ModuleManifest = 'Plumber.psd1'
    ExcludePaths = @{
        Backticks        = @('Tests/Assets/TaskHelp/*')
        PSScriptAnalyzer = @('Tests/Assets/TaskHelp/InvalidPowerShell.ps1')
    }
    JsonSchemas = @(
        @{
            Path   = 'Resource/RequiredModules.json'
            Schema = 'Resource/Schema/RequiredModulesSchema.json'
        }
    )
}
