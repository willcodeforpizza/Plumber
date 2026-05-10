<#
    .SYNOPSIS
    Validates current PSD1 version is higher than current PSGallery version.

    .DESCRIPTION
    Looks up the module on PSGallery and fails when the configured manifest
    version is not greater than the published version.

    .GROUP
    ReleaseHygiene

    .CONFIGURATION
    `ModuleManifest` controls which module manifest supplies the module name
    and `ModuleVersion`.

    ### Example

    ```powershell
    . (Get-PlumberTaskLoader) -Config @{
        ModuleManifest = 'MyModule.psd1'
    }
    ```

    .RUN
    ```powershell
    Invoke-Plumber -Task ModuleVersion
    ```

    .PASS
    ```powershell
    ModuleVersion = '1.2.3'
    ```

    .FAIL
    ```powershell
    ModuleVersion = '1.2.2'
    ```
#>
Add-BuildTask -Name ModuleVersion -Jobs SetVariables, {
    $publishedModule = Find-Module $script:moduleName -ErrorAction SilentlyContinue
    if (-not $publishedModule) {
        Write-Build Yellow "$script:moduleName is not published to PSGallery"
        return
    }

    $publishedVersion = [version]$publishedModule.Version
    $psd1Version = [version]$script:psd1.ModuleVersion
    if ($psd1Version -le $publishedVersion) {
        Write-Error (
            'PSD1 version might be out of date. ' +
            "PSD1 version $psd1Version " +
            "Published version $publishedVersion"
        )
    }
}
