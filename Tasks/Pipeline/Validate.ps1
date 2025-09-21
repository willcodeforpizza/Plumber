<#
    .SYNOPSIS
    Main parent task to run the validation pipeline
#>
task Validate SetVariables, 
    ?ModuleVersion,
    ?Changelog,
    ?PSScriptAnalyzer, 
    ?Pester, 
    ?JSON,
    ?Meta