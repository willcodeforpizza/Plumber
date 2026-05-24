function Add-PlumberTask {
    <#
        .SYNOPSIS
        Imports a Plumber task into the active Invoke-Build scope.

        .DESCRIPTION
        Resolves task metadata, applies the task's EnforceWhen policy, dot-sources
        enabled task files, and records the task as an optional dependency of its
        parent group. Disabled tasks are registered as explicit skip tasks so direct
        task invocation explains why no validation ran.
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
        Name        = $Name
        Path        = $Path
        TaskRoot    = $TaskRoot
        Parent      = $Parent
        EnforceWhen = Get-PlumberTaskEnforceWhen -Name $Name
    }
    $task = Import-PlumberTask @taskSplat

    if ($task.ShouldRun) {
        . $task.FullName
    } else {
        $skipMessage = Get-PlumberTaskSkipMessage -Name $task.Name -EnforceWhen $task.EnforceWhen
        Add-BuildTask -Name $task.Name -Jobs ({
            Write-Host $skipMessage
        }.GetNewClosure())
    }

    if ($task.Parent) {
        $script:PlumberTaskJobs[$task.Parent] += "?$($task.Name)"
    }
}
