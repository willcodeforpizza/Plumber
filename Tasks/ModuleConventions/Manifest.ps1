<#
    .SYNOPSIS
    Validates the module manifest.

    .DESCRIPTION
    Runs `Test-ModuleManifest` against the configured module manifest.

    .GROUP
    ModuleConventions

    .CONFIGURATION
    `ModuleManifest` controls which module manifest is validated.

    ### Example

    ```powershell
    . (Get-PlumberTaskLoader) -Config @{
        ModuleManifest = 'MyModule.psd1'
    }
    ```

    .RUN
    ```powershell
    Invoke-Plumber -Task Manifest
    ```

    .PASS
    ```powershell
    Test-ModuleManifest -Path ./MyModule.psd1
    ```

    .FAIL
    ```powershell
    Test-ModuleManifest -Path ./Missing.psd1
    ```
#>
Add-BuildTask -Name Manifest -Jobs SetVariables, {
    Test-ModuleManifest -Path $script:moduleManifest.FullName | Out-Null
}
