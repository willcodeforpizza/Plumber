<#
    .SYNOPSIS
    Validates public functions use the configured command prefix.

    .DESCRIPTION
    Checks files under `Public` and fails when a public function name does not
    use the configured noun prefix. The default prefix is the module name.

    .GROUP
    ModuleConventions

    .CONFIGURATION
    `Tasks.PublicFunctionPrefix.Prefix` overrides the expected prefix. The
    default is the configured module name.

    `Tasks.PublicFunctionPrefix.Exclusions` excludes exact public function names
    from this check.

    ### Example

    ```powershell
    . (Get-PlumberTaskLoader) -Config @{
        Tasks = @{
            PublicFunctionPrefix = @{
                Prefix     = 'My'
                Exclusions = @('New-Thing')
            }
        }
    }
    ```

    .RUN
    ```powershell
    Invoke-Plumber -Task PublicFunctionPrefix
    ```

    .PASS
    ```powershell
    function Get-MyThing {}
    ```

    .FAIL
    ```powershell
    function Get-Thing {}
    ```
#>
Add-BuildTask -Name PublicFunctionPrefix -Jobs SetVariables, { Invoke-PlumberPublicFunctionPrefix }
