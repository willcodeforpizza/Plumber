function Get-PlumberConfigUnknownKeyMessage {
    <#
        .SYNOPSIS
        Builds a friendly error message for an unknown config key.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory)]
        [string]
        $Path,

        [Parameter(Mandatory)]
        [string]
        $Kind,

        [Parameter(Mandatory)]
        [string[]]
        $AllowedName
    )

    $name = ($Path -split '\.')[-1]
    $message = "$Path is not a known $Kind"
    $suggestion = Get-PlumberConfigSuggestion -Name $name -AllowedName $AllowedName
    if ($suggestion) {
        $message = "$message. Did you mean ${suggestion}?"
    }

    $message
}
