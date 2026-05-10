<#
    .SYNOPSIS
    Runs code quality validation.

    .DESCRIPTION
    Runs validation tasks that check script analysis, style rules, tests, and
    coverage.

    .INCLUDES
    PSScriptAnalyzer
    Backticks
    LineLength
    PesterUnit
    PesterIntegration
    CodeCoverage

    .RUN
    ```powershell
    Invoke-Plumber -Task CodeQuality
    ```
#>
Add-BuildTask -Name CodeQuality -Jobs $script:PlumberTaskJobs.CodeQuality
