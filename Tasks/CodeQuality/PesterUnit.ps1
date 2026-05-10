<#
    .SYNOPSIS
    Runs unit tests and validates they pass.

    .DESCRIPTION
    Runs Pester tests from `Tests/Unit`, captures code coverage for module
    source folders, and fails when any unit test fails.

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
Add-BuildTask -Name PesterUnit -Jobs SetVariables, {
    if (-not (Test-Path "$BuildRoot\Tests\Unit")) {
        Write-Build Yellow 'No unit tests found'
        return
    }

    $config = New-PesterConfiguration
    $config.Run.Path = "$BuildRoot\Tests\Unit"
    $config.Run.PassThru = $true
    $config.CodeCoverage.Enabled = $true
    $config.CodeCoverage.Path = $script:moduleFolders
    $result = Invoke-Pester -Configuration $config
    $script:pesterResult = $result

    $failures = $result | Where-Object { $_.Result -eq 'Failed' }
    if ($failures) { Write-Error "Pester failed with $($failures.count) error(s)" }
}
