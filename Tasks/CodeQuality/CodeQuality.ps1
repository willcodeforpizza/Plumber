<#
    .SYNOPSIS
    Runs code quality validation
#>
Add-BuildTask -Name CodeQuality -Jobs ?PSScriptAnalyzer, ?Pester
