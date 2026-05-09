<#
    .SYNOPSIS
    Runs module convention validation
#>
Add-BuildTask -Name ModuleConventions -Jobs ?Manifest, ?PublicFunctions, ?Structure, ?Naming, ?ToDo
