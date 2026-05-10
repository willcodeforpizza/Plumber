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

    $tasks = @(
        foreach ($task in $BuildResult.Tasks) {
            $errorText = if ($task.Error) {
                $task.Error.ToString()
            } else {
                $null
            }

            [pscustomobject]@{
                Name   = $task.Name
                Status = if ($task.Error) {'Failed'} else {'Passed'}
                Error  = $errorText
            }
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
