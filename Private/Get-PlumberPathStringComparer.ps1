function Get-PlumberPathStringComparer {
    <#
        .SYNOPSIS
        Gets the string comparer for filesystem path comparisons.
    #>
    [CmdletBinding()]
    [OutputType([System.StringComparer])]
    param ()

    if ($IsLinux) {
        return [System.StringComparer]::Ordinal
    }

    [System.StringComparer]::OrdinalIgnoreCase
}