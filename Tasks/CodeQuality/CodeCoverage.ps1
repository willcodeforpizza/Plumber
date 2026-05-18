<#
    .SYNOPSIS
    Validates code coverage is over the configured minimum for each file tested.

    .DESCRIPTION
    Uses the Pester unit test result and fails when any covered file reports a
    coverage percentage below the configured minimum.

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
    Covered file reports coverage greater than or equal to the configured minimum.
    ```

    .FAIL
    ```text
    Covered file reports coverage lower than the configured minimum.
    ```
#>
Add-BuildTask -Name CodeCoverage -Jobs ?PesterUnit, { Invoke-PlumberCodeCoverage }
