<#
    .SYNOPSIS
    Validates all public functions are declared in the PSD1.

    .DESCRIPTION
    Checks files under `Public` and fails when a public function file name is
    not listed in the manifest `FunctionsToExport` value.

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
Add-BuildTask -Name PublicFunctions -Jobs {
    $failures = Get-ChildItem "$BuildRoot\Public" | ForEach-Object {
        if ($_.BaseName -notin $script:psd1.FunctionsToExport) {
            "$($_.BaseName) is not in FunctionsToExport"
        }
    }

    if ($failures) {
        Write-Error ($failures -join (', ' + [Environment]::NewLine))
    }
}
