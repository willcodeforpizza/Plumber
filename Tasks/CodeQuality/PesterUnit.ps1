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
Add-BuildTask -Name PesterUnit -Jobs SetVariables, {
    if (-not (Test-Path "$BuildRoot\Tests\Unit")) {
        Write-Build Yellow 'No unit tests found'
        return
    }

    $pesterSplat = @{
        Path             = "$BuildRoot\Tests\Unit"
        ModuleManifest   = Join-Path $BuildRoot "$script:moduleName.psd1"
        CodeCoveragePath = $script:moduleFolders
    }
    $result = Invoke-PlumberPester @pesterSplat
    $script:pesterResult = $result

    $failures = $result | Where-Object { $_.Result -eq 'Failed' }
    if ($failures) { Write-Error "Pester failed with $($failures.count) error(s)" }
}
