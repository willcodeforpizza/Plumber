<#
    .SYNOPSIS
    Validates the test run's overall code coverage is over the configured minimum.

    .DESCRIPTION
    Uses the Pester unit test result and fails when the run's overall coverage
    percentage is below the configured minimum. When PesterUnit does not
    run, CodeCoverage registers as an explicit skip task that explains why,
    instead of disappearing from the task graph.

    .GROUP
    CodeQuality

    .CONFIGURATION
    `Tasks.CodeCoverage.Minimum` controls the minimum acceptable coverage
    percentage. The default is `75`.

    ### Example

    ```powershell
    . (Get-PlumberTaskLoader) -Config @{
        ModuleManifest = 'MyModule.psd1'
        Tasks          = @{
            CodeCoverage = @{
                Minimum = 85
            }
        }
    }
    ```

    .RUN
    ```powershell
    Invoke-Plumber -Task CodeCoverage
    ```

    .PASS
    ```text
    Overall coverage is greater than or equal to the configured minimum.
    ```

    .FAIL
    ```text
    Overall coverage is lower than the configured minimum.
    ```
#>
Add-BuildTask -Name CodeCoverage -Jobs ?PesterUnit, { Invoke-PlumberCodeCoverage }
