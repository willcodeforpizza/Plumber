function Restore-PlumberStreamPesterOutput {
    <#
        .SYNOPSIS
        Restores the Plumber Pester-streaming preference using a token
        from Set-PlumberStreamPesterOutput.

        .DESCRIPTION
        Restores the previous value captured before Set-PlumberStreamPesterOutput
        was called, or removes the variable entirely if it didn't exist
        before. Always call this in a finally block paired with
        Set-PlumberStreamPesterOutput so nested Invoke-Plumber calls don't
        leak streaming state to the caller.

        .PARAMETER Token
        The token returned by Set-PlumberStreamPesterOutput.

        .EXAMPLE
        $token = Set-PlumberStreamPesterOutput -Value $true
        try {
            # ... run build ...
        } finally {
            Restore-PlumberStreamPesterOutput -Token $token
        }
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions',
        '',
        Justification = 'Pairs with Set-PlumberStreamPesterOutput as a stack restore.'
    )]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [pscustomobject]
        $Token
    )

    if ($Token.HadValue) {
        Set-Variable -Name PlumberStreamPesterOutput -Scope Global -Value $Token.PreviousValue
    } else {
        $removeSplat = @{
            Name        = 'PlumberStreamPesterOutput'
            Scope       = 'Global'
            ErrorAction = 'SilentlyContinue'
        }
        Remove-Variable @removeSplat
    }
}
