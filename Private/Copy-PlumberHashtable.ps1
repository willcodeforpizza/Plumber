function Copy-PlumberHashtable {
    <#
        .SYNOPSIS
        Returns a deep copy of a hashtable.

        .DESCRIPTION
        Recursively clones nested hashtables and arrays so the returned
        hashtable can be safely mutated without affecting the source. Scalar
        values (strings, numbers, booleans, $null) are copied by value.
        Array elements that are themselves hashtables or arrays are deep
        cloned too.

        .PARAMETER InputObject
        The hashtable to clone.

        .EXAMPLE
        $original = @{ Tasks = @{ Exclude = @('a', 'b') } }
        $copy = Copy-PlumberHashtable -InputObject $original
        $copy.Tasks.Exclude += 'c'
        # $original.Tasks.Exclude is unchanged.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory)]
        [hashtable]
        $InputObject
    )

    $cloneValue = {
        param ($Value)

        if ($null -eq $Value) {
            return $null
        }
        if ($Value -is [hashtable]) {
            return Copy-PlumberHashtable -InputObject $Value
        }
        if ($Value -is [System.Collections.IList] -and $Value -isnot [string]) {
            return , @(foreach ($item in $Value) { & $cloneValue $item })
        }
        $Value
    }

    $clone = @{}
    foreach ($key in $InputObject.Keys) {
        $clone[$key] = & $cloneValue $InputObject[$key]
    }
    $clone
}
