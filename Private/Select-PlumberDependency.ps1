function Select-PlumberDependency {
    <#
        .SYNOPSIS
        Filters Plumber dependency entries by task scope.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory)]
        [object[]]
        $Dependency,

        [string[]]
        $Scope
    )

    if (-not $Scope) {
        foreach ($item in $Dependency) {
            $item
        }
        return
    }

    $requestedScopes = @('Core') + $Scope
    foreach ($item in $Dependency) {
        $itemScopes = @($item.Scope)
        if (-not $itemScopes) {
            $itemScopes = @('Core')
        }

        if ($itemScopes | Where-Object { $_ -in $requestedScopes }) {
            $item
        }
    }
}
