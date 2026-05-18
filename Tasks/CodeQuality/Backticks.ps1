<#
    .SYNOPSIS
    Validates PowerShell files do not use line-continuation backticks.

    .DESCRIPTION
    Checks `.ps1`, `.psm1`, and `.psd1` files and fails when a backtick is used
    as a line continuation. Detection is AST-aware: backticks inside strings,
    here-strings, and comments are not flagged, and a trailing pair of backticks
    (a literal escaped backtick) is treated as intentional source rather than a
    continuation.

    .GROUP
    CodeQuality

    .CONFIGURATION
    `Tasks.Backticks.Exclude` excludes matching files from this task.

    ### Example

    ```powershell
    . (Get-PlumberTaskLoader) -Config @{
        ModuleManifest = 'MyModule.psd1'
        Tasks          = @{
            Backticks = @{
                Exclude = @('Tests/Assets/TaskHelp/*.ps1')
            }
        }
    }
    ```

    .RUN
    ```powershell
    Invoke-Plumber -Task Backticks
    ```

    .PASS
    ```powershell
    Get-Foo -DoBar -AddFizz
    ```

    .FAIL
    ```text
    A PowerShell line whose final non-whitespace character is a backtick
    used as a line continuation.
    ```
#>
Add-BuildTask -Name Backticks -Jobs { Invoke-PlumberBackticks }
