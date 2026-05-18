<#
    .SYNOPSIS
    Validates string literals do not contain Windows-style path separators.

    .DESCRIPTION
    Parses `.ps1`, `.psm1`, and `.psd1` files and fails when a string literal
    contains a backslash used as a path separator. Strings that are operands
    of regex operators (`-match`, `-replace`, `-split` family) and backslash
    sequences that look like regex escapes (`\d`, `\s`, `\\`, `\.`, etc.) are
    not flagged. Use `Join-Path` or `[IO.Path]::Combine` for cross-platform
    paths.

    .GROUP
    CodeQuality

    .CONFIGURATION
    `Tasks.PathSeparator.Exclude` excludes matching files from this task.

    ### Example

    ```powershell
    . (Get-PlumberTaskLoader) -Config @{
        ModuleManifest = 'MyModule.psd1'
        Tasks          = @{
            PathSeparator = @{
                Exclude = @('Tests/Assets/WindowsOnly.ps1')
            }
        }
    }
    ```

    .RUN
    ```powershell
    Invoke-Plumber -Task PathSeparator
    ```

    .PASS
    ```powershell
    $configPath = Join-Path $BuildRoot 'config.json'
    ```

    .FAIL
    ```text
    A string literal contains a backslash path separator, for example
    "$BuildRoot\config.json".
    ```
#>
Add-BuildTask -Name PathSeparator -Jobs { Invoke-PlumberPathSeparator }
