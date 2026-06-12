function Add-PlumberTask {
    <#
        .SYNOPSIS
        Imports a Plumber task into the active Invoke-Build scope.

        .DESCRIPTION
        Resolves task metadata, applies the task's RunWhen policy, dot-sources
        enabled task files, and records the task as an optional dependency of its
        parent group. Disabled tasks are registered as explicit skip tasks so direct
        task invocation explains why no validation ran. SkipReason forces a skip
        task for a task whose own policy would run, e.g. when a dependency it
        consumes is disabled.
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
        $Parent,

        [string]
        $SkipReason
    )

    $taskSplat = @{
        Name        = $Name
        Path        = $Path
        TaskRoot    = $TaskRoot
        Parent      = $Parent
        RunWhen = Get-PlumberTaskRunWhen -Name $Name
    }
    $task = Import-PlumberTask @taskSplat

    $skipMessage = if (-not $task.ShouldRun) {
        Get-PlumberTaskSkipMessage -Name $task.Name -RunWhen $task.RunWhen
    } elseif ($SkipReason) {
        $SkipReason
    }

    if ($skipMessage) {
        Add-BuildTask -Name $task.Name -Jobs ({
            Write-Host $skipMessage
        }.GetNewClosure())
    } else {
        . $task.FullName
    }

    if ($task.Parent) {
        $script:PlumberTaskJobs[$task.Parent] += "?$($task.Name)"
    }
}
