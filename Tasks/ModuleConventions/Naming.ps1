<#
    .SYNOPSIS
    Validates the RootModule name matches the module file name on disk.

    .DESCRIPTION
    Checks that the configured manifest `RootModule` value uses the same casing
    as the module `.psm1` file on disk.

    .GROUP
    ModuleConventions

    .CONFIGURATION
    `ModuleManifest` controls which module manifest supplies `RootModule`.

    ### Example

    ```powershell
    . (Get-PlumberTaskLoader) -Config @{
        ModuleManifest = 'MyModule.psd1'
    }
    ```

    .RUN
    ```powershell
    Invoke-Plumber -Task Naming
    ```

    .PASS
    ```powershell
    RootModule = 'MyModule.psm1'
    ```

    .FAIL
    ```powershell
    RootModule = 'mymodule.psm1'
    ```
#>
Add-BuildTask -Name Naming -Jobs SetVariables, {
    $psm1Name = Get-Item (Join-Path $BuildRoot "$script:moduleName.psm1")
    if (-not ($script:psd1.RootModule -ceq $psm1Name.Name)) {
        Write-Error "$($psm1Name.Name) case does not match RootModule"
    }
}
