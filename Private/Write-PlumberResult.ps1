function Write-PlumberResult {
    <#
        .SYNOPSIS
        Writes a Plumber result summary in the requested output mode.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [pscustomobject]
        $Result,

        [Parameter(Mandatory)]
        [ValidateSet('CI', 'Json', 'Raw', 'Summary', 'Table')]
        [string]
        $OutputMode,

        [switch]
        $NoFormat
    )

    if ($OutputMode -eq 'Json') {
        Write-Output ($Result | ConvertTo-Json -Depth 5)
        return
    }

    $escape = [char]27
    $format = {
        param (
            [string]
            $Text,

            [string]
            $Code
        )

        if ($NoFormat) {
            return $Text
        }

        "$escape[$($Code)m$Text$escape[0m"
    }
    $success = {param ([string] $Text) & $format -Text $Text -Code '32'}
    $failed = {param ([string] $Text) & $format -Text $Text -Code '31'}
    $neutral = {param ([string] $Text) & $format -Text $Text -Code '90'}
    $strong = {param ([string] $Text) & $format -Text $Text -Code '1'}
    $strongNeutral = {param ([string] $Text) & $format -Text $Text -Code '1;90'}

    if ($OutputMode -eq 'Table' -or $OutputMode -eq 'Raw') {
        if ($NoFormat) {
            Write-Output "$(
                $Result.Tasks |
                    Select-Object Name, Status |
                        Format-Table |
                            Out-String
            )"
        } else {
            $nameWidth = @(
                'Name'
                foreach ($task in $Result.Tasks) {
                    $task.Name
                }
            ) |
                Measure-Object -Maximum -Property Length |
                    Select-Object -ExpandProperty Maximum

            Write-Output (& $strong -Text 'Plumber task results')
            $rowFormat = "{0,-$nameWidth}  {1}"
            Write-Output ($rowFormat -f 'Name', 'Status')
            Write-Output ($rowFormat -f ('-' * $nameWidth), '------')
            foreach ($task in $Result.Tasks) {
                $status = if ($task.Status -eq 'Passed') {
                    & $success -Text $task.Status
                } else {
                    & $failed -Text $task.Status
                }
                Write-Output ($rowFormat -f $task.Name, $status)
            }
        }

        foreach ($failure in $Result.Failures) {
            if (-not $NoFormat) {
                Write-Output ''
            }
            Write-Output (& $neutral -Text "$($failure.Name):")
            Write-Output (& $failed -Text $failure.Error)
        }
        return
    }

    if ($Result.Success) {
        $message = 'Plumber validation passed.'
        $passed = "Passed: $($Result.Passed)."
        $failedText = 'Failed: 0.'
        if ($NoFormat) {
            Write-Output "$message $passed $failedText"
        } else {
            Write-Output "$(& $success -Text $message) $(& $success -Text $passed) $failedText"
        }
        return
    }

    Write-Output ''
    Write-Output (& $strongNeutral -Text 'Plumber validation failed.')
    foreach ($failure in $Result.Failures) {
        Write-Output (& $neutral -Text "$($failure.Name):")
        Write-Output (& $failed -Text $failure.Error)
    }
    Write-Output ''
    $passedCount = "Passed: $($Result.Passed)."
    $failedCount = "Failed: $($Result.Failed)."
    if ($NoFormat) {
        Write-Output "$passedCount $failedCount"
    } else {
        Write-Output "$(& $success -Text $passedCount) $(& $failed -Text $failedCount)"
    }
}
