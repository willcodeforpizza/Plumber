function Get-PlumberTaskEnforceWhen {
    <#
        .SYNOPSIS
        Gets the EnforceWhen policy for a Plumber task.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory)]
        [string]
        $Name
    )

    if (-not $script:PlumberConfig.Tasks.ContainsKey($Name)) {
        return 'Always'
    }

    $taskConfig = $script:PlumberConfig.Tasks[$Name]
    if ($taskConfig -is [hashtable] -and $taskConfig.ContainsKey('EnforceWhen')) {
        return $taskConfig.EnforceWhen
    }

    'Always'
}
