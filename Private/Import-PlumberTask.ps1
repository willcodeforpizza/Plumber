function Import-PlumberTask {
    <#
        .SYNOPSIS
        Creates metadata for a Plumber task import.

        .DESCRIPTION
        Returns task import metadata when a task is enabled. If the task name is
        present in ExcludeTasks, no object is returned. TaskLoader.ps1 uses this
        metadata to dot-source task files in the active Invoke-Build scope.

        .PARAMETER Name
        The Invoke-Build task name.

        .PARAMETER Path
        The task script path relative to the Plumber task root.

        .PARAMETER TaskRoot
        The root path that contains Plumber task scripts.

        .PARAMETER Parent
        The parent task that should reference this task.

        .PARAMETER ExcludeTasks
        Task names that should not be imported.

        .EXAMPLE
        Import-PlumberTask -Name JSON -Path Content/JSON.ps1 -TaskRoot $taskRoot -Parent Content

        Returns metadata for importing the JSON task under the Content parent.

        .EXAMPLE
        Import-PlumberTask -Name YAML -Path Content/YAML.ps1 -TaskRoot $taskRoot -ExcludeTasks YAML

        Returns nothing because YAML is excluded.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Mandatory)]
        [string]
        $Name,

        [Parameter(Mandatory)]
        [string]
        $Path,

        [Parameter(Mandatory)]
        [string]
        $TaskRoot,

        [string]
        $Parent,

        [string[]]
        $ExcludeTasks = @()
    )

    if (-not (Test-PlumberTaskEnabled -Name $Name -ExcludeTasks $ExcludeTasks)) {
        return
    }

    [pscustomobject]@{
        Name     = $Name
        FullName = Join-Path $TaskRoot $Path
        Parent   = $Parent
    }
}
