$module = Get-Module Plumber |
    Where-Object { $_.ModuleBase -eq $PSScriptRoot } |
        Select-Object -First 1
if (-not $module) {
    $module = Import-Module (Join-Path $PSScriptRoot 'Plumber.psd1') -Force -PassThru
}

. (Get-PlumberTaskLoader) -Config @{
    ModuleManifest = 'Plumber.psd1'
    Tasks          = @{
        PSScriptAnalyzer = @{
            Exclude = @('Tests/Assets/TaskHelp/InvalidPowerShell.ps1')
        }
        Local            = @(
            'LocalTasks/ValidateTaskHelp.ps1'
        )
    }
}

$releaseTasks = @('Release', 'BuildModule', 'PublishModule', 'PublishGitHubRelease')
$requestedTasks = @($BuildTask)
$shouldLoadReleaseTasks = @($requestedTasks | Where-Object { $PSItem -in $releaseTasks })
if ($shouldLoadReleaseTasks) {
    Import-Module Plumber.Release -RequiredVersion 0.1.0 -Force
    Import-Module (Join-Path $PSScriptRoot 'Plumber.psd1') -Force

    . (Get-PlumberReleaseTaskLoader) -Config @{
        ModuleManifest = 'Plumber.psd1'
    }
}

. (Join-Path $PSScriptRoot 'LocalTasks/GenerateDocs.ps1')
