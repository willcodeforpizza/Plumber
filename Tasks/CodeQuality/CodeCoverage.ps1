<#
    .SYNOPSIS
    Validates code coverage is over the configured minimum for each file tested.

    .DESCRIPTION
    Uses the Pester unit test result and fails when any covered file reports a
    coverage percentage below the configured minimum.

    .GROUP
    CodeQuality

    .CONFIGURATION
    `CoverageMinimum` controls the minimum acceptable coverage percentage. The
    default is `75`.

    ### Example

    ```powershell
    . (Get-PlumberTaskLoader) -Config @{
        ModuleManifest  = 'MyModule.psd1'
        CoverageMinimum = 85
    }
    ```

    .RUN
    ```powershell
    Invoke-Plumber -Task CodeCoverage
    ```

    .PASS
    ```text
    Covered file reports coverage greater than or equal to CoverageMinimum.
    ```

    .FAIL
    ```text
    Covered file reports coverage lower than CoverageMinimum.
    ```
#>
Add-BuildTask -Name CodeCoverage -Jobs ?PesterUnit, {
    if (-not $script:pesterResult) {
        Write-Build Yellow 'No Pester unit test results found'
        return
    }

    $script:pesterResult | ForEach-Object {
        $file = $_.Containers[0].Name
        $percent = $_.CodeCoverage.CoveragePercent
        if ($percent -lt $script:PlumberConfig.CoverageMinimum) {
            Write-Error "$percent% coverage for $file"
        }
    }
}
