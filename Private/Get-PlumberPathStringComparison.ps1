function Get-PlumberPathStringComparison {
    <#
        .SYNOPSIS
        Gets the string comparison mode for filesystem path comparisons.
    #>
    [CmdletBinding()]
    [OutputType([System.StringComparison])]
    param ()

    if ($IsLinux) {
        return [System.StringComparison]::Ordinal
    }

    [System.StringComparison]::OrdinalIgnoreCase
}