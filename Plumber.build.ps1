$module = Get-Module Plumber |
    Where-Object { $_.ModuleBase -eq $PSScriptRoot } |
        Select-Object -First 1
if (-not $module) {
    $module = Import-Module (Join-Path $PSScriptRoot 'Plumber.psd1') -Force -PassThru
}

Import-Module Plumber.Release -RequiredVersion 0.1.0 -Force

. (Get-PlumberTaskLoader) -Config @{
    ModuleManifest = 'Plumber.psd1'
    ExcludePaths = @{
        PSScriptAnalyzer = @('Tests/Assets/TaskHelp/InvalidPowerShell.ps1')
    }
    LocalTasks = @(
        'LocalTasks/ValidateTaskHelp.ps1'
    )
}

. (Get-PlumberReleaseTaskLoader) -Config @{
    ModuleManifest = 'Plumber.psd1'
}

. (Join-Path $PSScriptRoot 'LocalTasks/GenerateDocs.ps1')
