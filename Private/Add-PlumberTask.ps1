function Add-PlumberTask {
    <#
        .SYNOPSIS
        Imports a Plumber task into the active Invoke-Build scope.

        .DESCRIPTION
        Resolves task metadata, dot-sources the task file, and records the task
        as an optional dependency of its parent group.
    #>
    [CmdletBinding()]
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
        $Parent
    )

    $taskSplat = @{
        Name         = $Name
        Path         = $Path
        TaskRoot     = $TaskRoot
        Parent       = $Parent
        ExcludeTasks = $script:PlumberConfig.Tasks.Exclude
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
