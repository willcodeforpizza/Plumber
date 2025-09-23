<#
    .SYNOPSIS
    Main parent task to run the validation pipeline
#>
task -Name Validate -Jobs SetVariables,
    ?ModuleVersion,
    ?Changelog,
    ?JSON,
    ?Meta,
    ?PSScriptAnalyzer,
    ?Pester