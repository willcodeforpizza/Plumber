function Get-PlumberTaskSkipMessage {
    <#
        .SYNOPSIS
        Gets the skip message for a task disabled by EnforceWhen.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory)]
        [string]
        $Name,

        [Parameter(Mandatory)]
        [ValidateSet('Always', 'OnRelease', 'Never')]
        [string]
        $EnforceWhen
    )

    switch ($EnforceWhen) {
        'OnRelease' {
            "Skipping $Name`: EnforceWhen=OnRelease and PLUMBER_RELEASE_INTENT is not true."
        }
        'Never' {
            "Skipping $Name`: EnforceWhen=Never."
        }
        default {
            "Skipping $Name`: EnforceWhen=$EnforceWhen."
        }
    }
}
