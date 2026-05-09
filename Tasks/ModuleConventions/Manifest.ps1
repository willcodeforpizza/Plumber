<#
    .SYNOPSIS
    Validates the module manifest
#>
Add-BuildTask -Name Manifest -Jobs SetVariables, {
    Test-ModuleManifest -Path $script:moduleManifest.FullName | Out-Null
}
