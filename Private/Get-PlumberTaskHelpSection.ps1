function Get-PlumberTaskHelpSection {
    <#
        .SYNOPSIS
        Gets a named Plumber task help section.
    #>
    param (
        [Parameter(Mandatory)]
        [hashtable]
        $Sections,

        [Parameter(Mandatory)]
        [string]
        $Name
    )

    if ($Sections.ContainsKey($Name)) {
        return $Sections[$Name]
    }

    $null
}
