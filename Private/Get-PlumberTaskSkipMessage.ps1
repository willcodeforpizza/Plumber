function Get-PlumberTaskSkipMessage {
    <#
        .SYNOPSIS
        Gets the skip message for a task disabled by RunWhen.
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
        $RunWhen
    )

    switch ($RunWhen) {
        'OnRelease' {
            "Skipping $Name`: RunWhen=OnRelease and PLUMBER_RELEASE_INTENT is not true."
        }
        'Never' {
            "Skipping $Name`: RunWhen=Never."
        }
    }
}
