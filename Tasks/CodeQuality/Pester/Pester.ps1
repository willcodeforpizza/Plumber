<#
    .SYNOPSIS
    Parent test to run tests and confirm code coverage
#>
Add-BuildTask -Name Pester -Jobs ?PesterUnit, ?PesterIntegration, ?CodeCoverage
