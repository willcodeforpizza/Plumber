<#
    .SYNOPSIS
    Runs integration tests and validates they pass.

    .DESCRIPTION
    Runs Pester tests from `Tests/Integration` when that directory exists and
    fails when any integration test fails.

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
Add-BuildTask -Name PesterIntegration -Jobs SetVariables, {
    if (-not (Test-Path "$BuildRoot\Tests\Integration")) {
        Write-Build Yellow 'No integration tests found'
        return
    }

    $config = New-PesterConfiguration
    $config.Run.Path = "$BuildRoot\Tests\Integration"
    $config.Run.PassThru = $true
    $result = Invoke-Pester -Configuration $config

    $failures = $result | Where-Object { $_.Result -eq 'Failed' }
    if ($failures) { Write-Error "Pester failed with $($failures.count) error(s)" }
}
