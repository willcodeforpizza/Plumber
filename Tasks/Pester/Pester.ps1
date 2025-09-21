<#
    .SYNOPSIS
    Parent test to run unit tests, confirm code coverage and run integration tests 
#>
task Pester ?PesterUnit, 
    ?CodeCoverage,
    ?PesterIntegration