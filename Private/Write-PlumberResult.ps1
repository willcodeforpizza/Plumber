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
        $OutputMode
    )

    if ($OutputMode -eq 'Json') {
        Write-Output ($Result | ConvertTo-Json -Depth 5)
        return
    }

    if ($OutputMode -eq 'Table' -or $OutputMode -eq 'Raw') {
        Write-Output "$(
            $Result.Tasks |
                Select-Object Name, Status, Error |
                    Format-Table |
                        Out-String
        )"
        return
    }

    if ($Result.Success) {
        Write-Output "Plumber validation passed. Passed: $($Result.Passed). Failed: 0."
        return
    }

    Write-Output 'Plumber validation failed.'
    Write-Output "$(
        $Result.Failures |
            Select-Object Name, Error |
                Format-Table |
                    Out-String
    )"
    Write-Output "Passed: $($Result.Passed). Failed: $($Result.Failed)."
}
