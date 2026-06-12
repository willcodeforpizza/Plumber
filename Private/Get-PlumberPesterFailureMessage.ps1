function Get-PlumberPesterFailureMessage {
    <#
        .SYNOPSIS
        Builds the failure message for a failed Pester run result.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory)]
        [object]
        $Result
    )

    $failedCount = [int]$Result.FailedCount
    if ($failedCount -gt 0) {
        return "Pester failed with $failedCount failed test(s)"
    }

    'Pester run failed without test failures; check discovery or container errors'
}
