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
Add-BuildTask -Name PesterIntegration -Jobs SetVariables, {
    if (-not (Test-Path "$BuildRoot\Tests\Integration")) {
        Write-Build Yellow 'No integration tests found'
        return
    }

    $pesterSplat = @{
        Path           = "$BuildRoot\Tests\Integration"
        ModuleManifest = Join-Path $BuildRoot "$script:moduleName.psd1"
        StreamOutput   = $script:PlumberConfig.StreamPesterOutput
    }
    $result = Invoke-PlumberPester @pesterSplat

    $failures = $result | Where-Object { $_.Result -eq 'Failed' }
    if ($failures) { Write-Error "Pester failed with $($failures.count) error(s)" }
}
