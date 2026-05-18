<#
    .SYNOPSIS
    Runs integration tests and validates they pass.

    .DESCRIPTION
    Runs Pester tests from `Tests/Integration` in a separate PowerShell process
    when that directory exists, and fails when any integration test fails.

    .GROUP
    CodeQuality

    .CONFIGURATION
    None.

    .RUN
    ```powershell
    Invoke-Plumber -Task PesterIntegration
    ```

    .PASS
    ```powershell
    It 'returns a value' {
        Get-Thing | Should -Not -BeNullOrEmpty
    }
    ```

    .FAIL
    ```powershell
    It 'returns a value' {
        Get-Thing | Should -BeNullOrEmpty
    }
    ```
#>
Add-BuildTask -Name PesterIntegration -Jobs SetVariables, { Invoke-PlumberPesterIntegration }
