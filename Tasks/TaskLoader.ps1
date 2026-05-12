<#
    .SYNOPSIS
    Loads Plumber Invoke-Build tasks.

    .DESCRIPTION
    Registers Plumber's validation task graph in the active Invoke-Build scope.
    This script is dot-sourced from a build file so each task script can call
    Add-BuildTask in the correct scope.

    The Config hashtable is merged with Plumber defaults and exposed to tasks as
    $script:PlumberConfig.

    .PARAMETER Config
    Repository-specific Plumber configuration. Supported keys are
    ModuleManifest, CoverageMinimum, ExcludePaths, FileScope, DiffBase,
    IncludeTestsInPssa, LocalTasks, PublicFunctionPrefix,
    PublicFunctionPrefixExclusions and ExcludeTasks.

    .EXAMPLE
    . (Get-PlumberTaskLoader) -Config @{
        ModuleManifest = 'MyModule.psd1'
    }

    Loads the default Plumber task graph for a module manifest.

    .EXAMPLE
    . (Get-PlumberTaskLoader) -Config @{
        ModuleManifest     = 'MyModule.psd1'
        CoverageMinimum    = 80
        ExcludePaths       = @{
            Backticks = @('Tests/Assets/*')
        }
        IncludeTestsInPssa = $false
        ExcludeTasks       = @('YAML', 'ChangelogUpdated')
    }

    Loads Plumber tasks with custom coverage, PSScriptAnalyzer and task exclusion
    settings.
#>
param (
    [hashtable]
    $Config = @{}
)

$moduleRoot = Split-Path $PSScriptRoot -Parent

# Task files are dot-sourced into Invoke-Build's script scope, so the private
# helpers must be dot-sourced too; importing the module does not expose private
# module functions to that build-file scope.
foreach ($privateScript in Get-ChildItem (Join-Path $moduleRoot 'Private') -Filter '*.ps1') {
    . $privateScript.FullName
}

$script:PlumberConfig = New-PlumberConfig -Config $Config
$script:PlumberConfig.ModuleRoot = $moduleRoot
$script:PlumberTaskJobs = Initialize-PlumberTaskGraph

$taskRoot = Join-Path $moduleRoot 'Tasks'
. (Join-Path $taskRoot 'SetVariables.ps1')

foreach ($taskGroup in Get-PlumberTaskGroup) {
    Add-PlumberTaskGroup -TaskGroup $taskGroup -TaskRoot $taskRoot
}

Add-PlumberLocalTask
Add-PlumberTask -Name Validate -Path 'Pipeline/Validate.ps1' -TaskRoot $taskRoot
