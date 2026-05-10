<#
    .SYNOPSIS
    Validates native task syntax.

    .DESCRIPTION
    Uses the Invoke-Build native task command instead of Add-BuildTask.

    .GROUP
    Content

    .CONFIGURATION
    None.

    .RUN
    ```powershell
    Invoke-Plumber -Task NativeTask
    ```

    .PASS
    ```text
    valid
    ```

    .FAIL
    ```text
    invalid
    ```
#>
Add-BuildTask NativeTask {}
