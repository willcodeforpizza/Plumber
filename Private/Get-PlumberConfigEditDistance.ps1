function Get-PlumberConfigEditDistance {
    <#
        .SYNOPSIS
        Calculates the edit distance between two config names.
    #>
    [CmdletBinding()]
    [OutputType([int])]
    param (
        [Parameter(Mandatory)]
        [string]
        $Left,

        [Parameter(Mandatory)]
        [string]
        $Right
    )

    $distance = New-Object 'int[,]' ($Left.Length + 1), ($Right.Length + 1)
    for ($leftIndex = 0; $leftIndex -le $Left.Length; $leftIndex++) {
        $distance[$leftIndex, 0] = $leftIndex
    }
    for ($rightIndex = 0; $rightIndex -le $Right.Length; $rightIndex++) {
        $distance[0, $rightIndex] = $rightIndex
    }

    for ($leftIndex = 1; $leftIndex -le $Left.Length; $leftIndex++) {
        for ($rightIndex = 1; $rightIndex -le $Right.Length; $rightIndex++) {
            $cost = if ($Left[($leftIndex - 1)] -eq $Right[($rightIndex - 1)]) {
                0
            } else {
                1
            }
            $delete = $distance[($leftIndex - 1), $rightIndex] + 1
            $insert = $distance[$leftIndex, ($rightIndex - 1)] + 1
            $replace = $distance[($leftIndex - 1), ($rightIndex - 1)] + $cost
            $distance[$leftIndex, $rightIndex] = [Math]::Min(
                [Math]::Min($delete, $insert),
                $replace
            )
        }
    }

    $distance[$Left.Length, $Right.Length]
}
