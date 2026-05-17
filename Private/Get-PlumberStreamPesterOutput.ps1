function Get-PlumberStreamPesterOutput {
    <#
        .SYNOPSIS
        Reads the current Plumber Pester-streaming preference.

        .DESCRIPTION
        Returns $true or $false when Invoke-Plumber has set a streaming
        preference for the current build, or $null when no preference is
        in effect (the Pester tasks should fall back to their configured
        StreamOutput defaults).

        Plumber uses a process-global variable as a side-channel because
        Invoke-Plumber runs in the module's session state while
        New-PlumberConfig and the Pester tasks run in the build file's
        scope. Use this helper instead of reading the variable directly
        so the contract stays in one place.

        .EXAMPLE
        $stream = Get-PlumberStreamPesterOutput
        if ($null -ne $stream) {
            $config.Tasks.PesterUnit.StreamOutput = $stream
        }
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseOutputTypeCorrectly',
        '',
        Justification = 'Returns $true, $false, or $null; OutputType cannot model that union cleanly.'
    )]
    [CmdletBinding()]
    [OutputType([object])]
    param ()

    $getVariableSplat = @{
        Name        = 'PlumberStreamPesterOutput'
        Scope       = 'Global'
        ErrorAction = 'SilentlyContinue'
    }
    $variable = Get-Variable @getVariableSplat
    if ($null -eq $variable) {
        return $null
    }
    [bool] $variable.Value
}
