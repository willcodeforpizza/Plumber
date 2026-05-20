function Get-PlumberConfigSuggestion {
    <#
        .SYNOPSIS
        Finds the closest known config name for a misspelled key.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory)]
        [string]
        $Name,

        [Parameter(Mandatory)]
        [string[]]
        $AllowedName
    )

    $bestName = $null
    $bestDistance = [int]::MaxValue
    foreach ($candidate in $AllowedName) {
        $distanceSplat = @{
            Left  = $Name.ToLowerInvariant()
            Right = $candidate.ToLowerInvariant()
        }
        $distance = Get-PlumberConfigEditDistance @distanceSplat
        if ($distance -lt $bestDistance) {
            $bestName = $candidate
            $bestDistance = $distance
        }
    }

    if ($bestDistance -le [Math]::Max(2, [Math]::Ceiling($Name.Length / 3))) {
        return $bestName
    }
}
