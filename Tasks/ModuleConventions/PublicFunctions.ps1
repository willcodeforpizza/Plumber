<#
    .SYNOPSIS
    Validates all public functions are declared in the PSD1.

    .DESCRIPTION
    Checks files under `Public` and fails when a public function file name is
    not listed in the manifest `FunctionsToExport` value, an exported function
    has no matching public file, a public file does not define a matching
    function, or a private function is exported.

    .GROUP
    ModuleConventions

    .CONFIGURATION
    `ModuleManifest` controls which module manifest supplies
    `FunctionsToExport`.

    ### Example

    ```powershell
    . (Get-PlumberTaskLoader) -Config @{
        ModuleManifest = 'MyModule.psd1'
    }
    ```

    .RUN
    ```powershell
    Invoke-Plumber -Task PublicFunctions
    ```

    .PASS
    ```powershell
    FunctionsToExport = @('Get-Thing')
    ```

    .FAIL
    ```powershell
    FunctionsToExport = @()
    ```
#>
Add-BuildTask -Name PublicFunctions -Jobs SetVariables, { Invoke-PlumberPublicFunctions }
