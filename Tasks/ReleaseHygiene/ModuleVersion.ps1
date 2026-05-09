<#
    .SYNOPSIS
    Validates current PSD1 version is higher than current PSGallery version
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
