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

    if (
        $script:PlumberConfig -and
        $script:PlumberConfig.Tasks -and
        $script:PlumberConfig.Tasks.ContainsKey($Name) -and
        $script:PlumberConfig.Tasks[$Name] -is [hashtable] -and
        $script:PlumberConfig.Tasks[$Name].ContainsKey('EnforceWhen') -and
        $script:PlumberConfig.Tasks[$Name].EnforceWhen
    ) {
        return $script:PlumberConfig.Tasks[$Name].EnforceWhen
    }

    'Always'
}
