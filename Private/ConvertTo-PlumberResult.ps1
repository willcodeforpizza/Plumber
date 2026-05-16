function ConvertTo-PlumberResult {
    <#
        .SYNOPSIS
        Converts an Invoke-Build result into a Plumber result summary.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Mandatory)]
        [pscustomobject]
        $BuildResult
    )

    $groupChildren = @{}
    foreach ($taskGroup in Get-PlumberTaskGroup) {
        $groupChildren[$taskGroup.Parent] = @($taskGroup.Children)
    }
    foreach ($task in $BuildResult.Tasks) {
        $jobChildren = @(
            foreach ($job in @($task.Jobs)) {
                if ($job -is [string] -and $job.StartsWith('?')) {
                    $job.TrimStart('?')
                }
            }
        )
        if ($jobChildren.Count -gt 0) {
            $groupChildren[$task.Name] = @($jobChildren)
        }
    }

    $convertErrorText = {
        param (
            [AllowNull()]
            $ErrorValue
        )

        if ($null -eq $ErrorValue) {
            return $null
        }

        if ($ErrorValue -is [System.Management.Automation.ErrorRecord]) {
            if ($ErrorValue.ErrorDetails -and $ErrorValue.ErrorDetails.Message) {
                return $ErrorValue.ErrorDetails.Message
            }

            if ($ErrorValue.Exception -and $ErrorValue.Exception.Message) {
                return $ErrorValue.Exception.Message
            }
        }

        $ErrorValue.ToString()
    }

    $getDescendant = {
        param (
            [string]
            $TaskName
        )

        foreach ($childName in @($groupChildren[$TaskName])) {
            $childName
            if ($groupChildren.ContainsKey($childName)) {
                & $getDescendant -TaskName $childName
            }
        }
    }

    $allTasks = @(
        foreach ($task in $BuildResult.Tasks) {
            $errorText = if ($task.Error) {
                & $convertErrorText -ErrorValue $task.Error
            } else {
                $null
            }

            [pscustomobject]@{
                Name   = $task.Name
                Status = if ($task.Error) {'Failed'} else {'Passed'}
                Error  = $errorText
            }
        }

        if (-not $BuildResult.Tasks -and $BuildResult.Error) {
            [pscustomobject]@{
                Name   = if ($BuildResult.Task) {$BuildResult.Task} else {'Build'}
                Status = 'Failed'
                Error  = & $convertErrorText -ErrorValue $BuildResult.Error
            }
        }
    )

    $taskByName = @{}
    foreach ($task in $allTasks) {
        $taskByName[$task.Name] = $task
    }

    $tasks = @(
        foreach ($task in $allTasks) {
            if (-not $groupChildren.ContainsKey($task.Name)) {
                $task
                continue
            }

            $childNames = & $getDescendant -TaskName $task.Name
            $childTasks = @($childNames | Where-Object {$taskByName.ContainsKey($PSItem)})
            $childFailures = @(
                $childTasks |
                    ForEach-Object {$taskByName[$PSItem]} |
                        Where-Object {$_.Status -eq 'Failed'}
            )

            $isExplainedGroupFailure = $task.Status -eq 'Failed' -and $childFailures.Count -gt 0
            $isExpandedPassedGroup = $task.Status -eq 'Passed' -and $childTasks.Count -gt 0
            if ($isExplainedGroupFailure -or $isExpandedPassedGroup) {
                continue
            }

            $task
        }
    )

    $failures = @($tasks | Where-Object {$_.Status -eq 'Failed'})

    [pscustomobject]@{
        Success  = $failures.Count -eq 0
        Passed   = @($tasks | Where-Object {$_.Status -eq 'Passed'}).Count
        Failed   = $failures.Count
        Tasks    = $tasks
        Failures = $failures
    }
}
