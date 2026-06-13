. (Get-PlumberTaskLoader) -Config @{
    ModuleManifest       = 'Plumber.psd1'
    IncludeModuleFolders = @('TaskFunctions')
    ExcludeDirectories   = @('out')
    Tasks                = @{
        PSScriptAnalyzer = @{
            Exclude = @('Tests/Assets/TaskHelp/InvalidPowerShell.ps1')
        }
        PathSeparator    = @{
            Exclude = @(
                'Tests/Assets/TaskHelp/InvalidPowerShell.ps1'
                'Tests/Unit/Private/Get-PlumberPathSeparator.Tests.ps1'
                'Tests/Unit/Private/ConvertTo-PlumberPathRegex.Tests.ps1'
            )
        }
        Backticks        = @{
            Exclude = @(
                'Tests/Assets/TaskHelp/InvalidPowerShell.ps1'
                'Tests/Unit/Private/Get-PlumberLineContinuation.Tests.ps1'
            )
        }
        ToDo             = @{
            Exclude = @(
                'Tests/Assets/TaskHelp/InvalidPowerShell.ps1'
                'Tests/Unit/Private/Get-PlumberToDoComment.Tests.ps1'
            )
        }
        ModuleVersion    = @{
            RunWhen = 'OnRelease'
        }
        ChangelogUpdated = @{
            RunWhen = 'OnRelease'
        }
        Local            = @(
            'LocalTasks/ValidateTaskHelp.ps1'
        )
    }
}

. (Get-PlumberReleaseTaskLoader) -Config @{
    ModuleManifest           = 'Plumber.psd1'
    ModuleBuildIncludeItems  = @(
        'TaskFunctions'
        'Plumber.internal.dependencies.psd1'
    )
}

. (Join-Path $PSScriptRoot 'LocalTasks/GenerateDocs.ps1')
