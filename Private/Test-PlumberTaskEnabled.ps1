function Test-PlumberTaskEnabled {
    <#
        .SYNOPSIS
        Tests whether a Plumber task should run for the current enforcement context.

        .DESCRIPTION
        Evaluates a task's EnforceWhen policy. Always runs in every context,
        OnRelease runs only when PLUMBER_RELEASE_INTENT is true, and Never skips
        in every context.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory)]
        [string]
        $Name,

        [ValidateSet('Always', 'OnRelease', 'Never')]
        [string]
        $EnforceWhen = 'Always'
    )

    switch ($EnforceWhen) {
        'Always' {
            $true
        }
        'OnRelease' {
            $env:PLUMBER_RELEASE_INTENT -in @('true', 'True', 'TRUE', '1', 'yes')
        }
        'Never' {
            $false
        }
        default {
            throw "Unsupported EnforceWhen value for task '$Name': $EnforceWhen"
        }
    }
}
