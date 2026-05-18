<#
    .SYNOPSIS
    Validates PowerShell source files do not exceed the configured line length.

    .DESCRIPTION
    Checks `.ps1`, `.psm1`, and `.psd1` files under the build root and fails
    when a line is longer than the configured maximum.

    .GROUP
    CodeQuality

    .CONFIGURATION
    `Tasks.LineLength.MaxLength` controls the maximum allowed line length. The
    default is `115`.

    `Tasks.LineLength.Exclude` excludes matching files from this task.

    ### Example

    ```powershell
    . (Get-PlumberTaskLoader) -Config @{
        ModuleManifest = 'MyModule.psd1'
        Tasks          = @{
            LineLength = @{
                MaxLength = 80
                Exclude   = @('Tests/Assets/LongLines.ps1')
            }
        }
    }
    ```

    .RUN
    ```powershell
    Invoke-Plumber -Task LineLength
    ```

    .PASS
    ```powershell
    $name = 'LineLength'
    "Task: $name"
    ```

    .FAIL
    ```powershell
    $line = '<more than configured maximum characters on one physical line>'
    ```
#>
Add-BuildTask -Name LineLength -Jobs { Invoke-PlumberLineLength }
