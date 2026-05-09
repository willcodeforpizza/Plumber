<#
    .SYNOPSIS
    Runs release hygiene validation
#>
Add-BuildTask -Name ReleaseHygiene -Jobs ?ModuleVersion, ?Changelog
