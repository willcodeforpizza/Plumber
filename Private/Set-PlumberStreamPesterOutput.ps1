function Set-PlumberStreamPesterOutput {
    <#
        .SYNOPSIS
        Sets the Plumber Pester-streaming preference, returning a restore
        token.

        .DESCRIPTION
        Stores the preference in a process-global variable that
        New-PlumberConfig reads from the build file's scope. Returns a
        token capturing the previous state so callers can restore it
        with Restore-PlumberStreamPesterOutput in a finally block. Stack-
        safe across nested Invoke-Plumber calls.

        .PARAMETER Value
        The preference to set.

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
        Justification = 'Side-channel for build-file scope; restored by Restore-PlumberStreamPesterOutput.'
    )]
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Mandatory)]
        [bool]
        $Value
    )

    $getVariableSplat = @{
        Name        = 'PlumberStreamPesterOutput'
        Scope       = 'Global'
        ErrorAction = 'SilentlyContinue'
    }
    $existing = Get-Variable @getVariableSplat
    $token = [pscustomobject]@{
        HadValue      = $null -ne $existing
        PreviousValue = if ($existing) { $existing.Value } else { $null }
    }
    Set-Variable -Name PlumberStreamPesterOutput -Scope Global -Value $Value
    $token
}
