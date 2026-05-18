<#
    .SYNOPSIS
    Runs unit tests and validates they pass.

    .DESCRIPTION
    Runs Pester tests from `Tests/Unit` in a separate PowerShell process,
    captures code coverage for module source folders, and fails when any unit
    test fails.

    .GROUP
    CodeQuality

    .CONFIGURATION
    None.

    .RUN
    ```powershell
    Invoke-Plumber -Task PesterUnit
    ```

    .PASS
    ```powershell
    It 'returns the expected value' {
        Get-Thing | Should -Be 'value'
    }
    ```

    .FAIL
    ```powershell
    It 'returns the expected value' {
        Get-Thing | Should -Be 'other'
    }
    ```
#>
Add-BuildTask -Name PesterUnit -Jobs SetVariables, { Invoke-PlumberPesterUnit }
