function Invoke-PlumberManifest {
    <#
        .SYNOPSIS
        Runs the Manifest task body.
    #>
    [CmdletBinding()]
    param ()

    Test-ModuleManifest -Path $script:moduleManifest.FullName | Out-Null
}
