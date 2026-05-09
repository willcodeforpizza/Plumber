<#
    .SYNOPSIS
    Main parent task to run the validation pipeline
#>
Add-BuildTask -Name Validate -Jobs SetVariables,
    ?CodeQuality,
    ?ReleaseHygiene,
    ?Content,
    ?ModuleConventions
