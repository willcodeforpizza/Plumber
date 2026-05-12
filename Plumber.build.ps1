$module = Get-Module Plumber |
    Where-Object { $_.ModuleBase -eq $PSScriptRoot } |
        Select-Object -First 1
if (-not $module) {
    $module = Import-Module (Join-Path $PSScriptRoot 'Plumber.psd1') -Force -PassThru
}

. (Get-PlumberTaskLoader) -Config @{
    ModuleManifest = 'Plumber.psd1'
    ExcludePaths = @{
        Backticks        = @('out/**')
        JSON             = @('out/**')
        JSONSchema       = @('out/**')
        LineLength       = @('out/**')
        PSScriptAnalyzer = @('Tests/Assets/TaskHelp/InvalidPowerShell.ps1', 'out/**')
        ToDo             = @('out/**')
        YAML             = @('out/**')
    }
    LocalTasks = @(
        'LocalTasks/ValidateTaskHelp.ps1'
    )
}

. (Join-Path $PSScriptRoot 'build/Publish.ps1') -ModuleBuildExtraItems @('Tasks', 'docs')
. (Join-Path $PSScriptRoot 'LocalTasks/GenerateDocs.ps1')
