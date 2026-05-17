. (Get-PlumberTaskLoader) -Config @{
    ModuleManifest = 'Plumber.psd1'
    Tasks          = @{
        PSScriptAnalyzer = @{
            Exclude = @('Tests/Assets/TaskHelp/InvalidPowerShell.ps1')
        }
        PathSeparator    = @{
            Exclude = @(
                'Tests/Assets/TaskHelp/InvalidPowerShell.ps1'
                'Tests/Unit/Private/Get-PlumberPathSeparator.Tests.ps1'
            )
        }
        Local            = @(
            'LocalTasks/ValidateTaskHelp.ps1'
        )
    }
}

. (Get-PlumberReleaseTaskLoader) -Config @{
    ModuleManifest = 'Plumber.psd1'
}

. (Join-Path $PSScriptRoot 'LocalTasks/GenerateDocs.ps1')
