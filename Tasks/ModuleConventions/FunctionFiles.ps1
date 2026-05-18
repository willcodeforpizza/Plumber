<#
    .SYNOPSIS
    Validates PowerShell function files contain one matching function.

    .DESCRIPTION
    Checks files under `Public` and `Private` and fails when a PowerShell
    function file contains no function, more than one function, cannot be
    parsed, or defines a function whose name does not match the file name.

    .GROUP
    ModuleConventions

    .CONFIGURATION
    `FunctionFiles.Exclude` excludes repository-relative paths from validation.

    ### Example

    ```powershell
    . (Get-PlumberTaskLoader) -Config @{
        Tasks = @{
            FunctionFiles = @{
                Exclude = @('Private/Generated/*.ps1')
            }
        }
    }
    ```

    .RUN
    ```powershell
    Invoke-Plumber -Task FunctionFiles
    ```

    .PASS
    ```powershell
    # Public/Get-Thing.ps1
    function Get-Thing {
    }
    ```

    .FAIL
    ```powershell
    # Private/Helpers.ps1
    function Get-Thing {
    }

    function Set-Thing {
    }
    ```
#>
Add-BuildTask -Name FunctionFiles -Jobs SetVariables, { Invoke-PlumberFunctionFiles }
