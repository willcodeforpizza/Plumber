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
    ModuleManifest, CoverageMinimum, ExcludePaths, IncludeTestsInPssa,
    LocalTasks and ExcludeTasks.

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

$defaults = @{
    ModuleManifest          = $null
    CoverageMinimum         = 75
    IncludeTestsInPssa      = $true
    JsonSchemas             = @()
    MaxLineLength           = 115
    PrivateHelpSynopsisOnly = $true
    ExcludeTasks            = @()
    ExcludePaths            = @{}
    LocalTasks              = @()
}

$script:PlumberConfig = $defaults.Clone()
foreach ($key in $Config.Keys) {
    $script:PlumberConfig[$key] = $Config[$key]
}

if (-not $script:PlumberConfig.ExcludeTasks) {
    $script:PlumberConfig.ExcludeTasks = @()
}
if (-not $script:PlumberConfig.ExcludePaths) {
    $script:PlumberConfig.ExcludePaths = @{}
}
if (-not $script:PlumberConfig.LocalTasks) {
    $script:PlumberConfig.LocalTasks = @()
}
if (Get-Variable -Name BuildRoot -ErrorAction SilentlyContinue) {
    $script:PlumberConfig.BuildRoot = $BuildRoot
}

$module = Get-Module Plumber
if (-not $module) {
    throw 'Plumber module must be imported before loading tasks.'
}


function Add-PlumberTask {
    <#
        .SYNOPSIS
        Imports a Plumber task into the active Invoke-Build scope.

        .DESCRIPTION
        Resolves task metadata, dot-sources the task file, and records the task
        as an optional dependency of its parent group.

        This function is intentionally defined inline in the task loader. The
        loader is dot-sourced by a consuming build file, so inline definition
        keeps Add-PlumberTask in the same script scope as Invoke-Build's task
        registration functions and the loader's task graph state.

        .PARAMETER Name
        The task name to import.

        .PARAMETER Path
        The task file path relative to the Plumber task root.

        .PARAMETER Parent
        The parent task group that should include this task.
    #>
    param (
        [Parameter(Mandatory)]
        [string]
        $Name,

        [Parameter(Mandatory)]
        [string]
        $Path,

        [string]
        $Parent
    )

    $taskSplat = @{
        Name      = $Name
        Path      = $Path
        TaskRoot  = $taskRoot
        Parent    = $Parent
        ExcludeTasks = $script:PlumberConfig.ExcludeTasks
    }
    $task = Import-PlumberTask @taskSplat
    if (-not $task) {
        return
    }

    . $task.FullName

    if ($task.Parent) {
        $script:PlumberTaskJobs[$task.Parent] += "?$($task.Name)"
    }
}


$moduleRoot = $module.ModuleBase
$script:PlumberConfig.ModuleRoot = $moduleRoot
$taskRoot = Join-Path $moduleRoot 'Tasks'
. (Join-Path $moduleRoot 'Private/Test-PlumberTaskEnabled.ps1')
. (Join-Path $moduleRoot 'Private/Test-PlumberTaskPathExcluded.ps1')
. (Join-Path $moduleRoot 'Private/Get-PlumberTaskFile.ps1')
. (Join-Path $moduleRoot 'Private/Import-PlumberTask.ps1')

$script:PlumberTaskJobs = @{
    CodeQuality       = @()
    ReleaseHygiene    = @()
    Content           = @()
    ModuleConventions = @()
    Local             = @()
    Validate          = @('SetVariables')
}

$taskGroups = @(
    @{
        Parent   = 'CodeQuality'
        Children = @(
            'PSScriptAnalyzer',
            'Backticks',
            'LineLength',
            'PesterUnit',
            'PesterIntegration',
            'CodeCoverage'
        )
    }
    @{
        Parent   = 'ReleaseHygiene'
        Children = @('ModuleVersion', 'ChangelogUpdated')
    }
    @{
        Parent   = 'Content'
        Children = @('JSON', 'JSONSchema', 'YAML')
    }
    @{
        Parent   = 'ModuleConventions'
        Children = @('Manifest', 'PublicFunctions', 'Naming', 'ToDo', 'Help')
    }
)

. (Join-Path $taskRoot 'SetVariables.ps1')
. (Join-Path $taskRoot 'BuildModule.ps1')
. (Join-Path $taskRoot 'GenerateDocs.ps1')
. (Join-Path $taskRoot 'PublishModule.ps1')
. (Join-Path $taskRoot 'PublishRelease.ps1')

foreach ($taskGroup in $taskGroups) {
    if (
        -not (Test-PlumberTaskEnabled -Name $taskGroup.Parent -ExcludeTasks $script:PlumberConfig.ExcludeTasks)
    ) {
        continue
    }

    foreach ($childTask in $taskGroup.Children) {
        if (
            $childTask -eq 'CodeCoverage' -and
            $script:PlumberTaskJobs.CodeQuality -notcontains '?PesterUnit'
        ) {
            continue
        }

        $childSplat = @{
            Name   = $childTask
            Path   = "$($taskGroup.Parent)/$childTask.ps1"
            Parent = $taskGroup.Parent
        }
        Add-PlumberTask @childSplat
    }

    if (-not $script:PlumberTaskJobs[$taskGroup.Parent]) {
        continue
    }

    $parentSplat = @{
        Name   = $taskGroup.Parent
        Path   = "$($taskGroup.Parent)/$($taskGroup.Parent).ps1"
        Parent = 'Validate'
    }
    Add-PlumberTask @parentSplat
}

if (
    $script:PlumberConfig.LocalTasks -and
    (Test-PlumberTaskEnabled -Name Local -ExcludeTasks $script:PlumberConfig.ExcludeTasks)
) {
    foreach ($localTaskPath in @($script:PlumberConfig.LocalTasks)) {
        if (-not $localTaskPath) {
            continue
        }

        $localTaskName = [System.IO.Path]::GetFileNameWithoutExtension($localTaskPath)
        if (-not (Test-PlumberTaskEnabled -Name $localTaskName -ExcludeTasks $script:PlumberConfig.ExcludeTasks)) {
            continue
        }

        $resolvedLocalTaskPath = if ([System.IO.Path]::IsPathRooted($localTaskPath)) {
            [System.IO.Path]::GetFullPath($localTaskPath)
        } elseif (Get-Variable -Name BuildRoot -ErrorAction SilentlyContinue) {
            [System.IO.Path]::GetFullPath((Join-Path $BuildRoot $localTaskPath))
        } else {
            [System.IO.Path]::GetFullPath($localTaskPath)
        }

        if (-not (Test-Path $resolvedLocalTaskPath -PathType Leaf)) {
            throw "Local task file not found: $localTaskPath"
        }

        . $resolvedLocalTaskPath
        $script:PlumberTaskJobs.Local += "?$localTaskName"
    }

    if ($script:PlumberTaskJobs.Local) {
        Add-BuildTask -Name Local -Jobs $script:PlumberTaskJobs.Local
        $script:PlumberTaskJobs.Validate += '?Local'
    }
}

Add-PlumberTask -Name Validate -Path 'Pipeline/Validate.ps1'
