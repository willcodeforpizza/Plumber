<#
    .SYNOPSIS
    Defines variables used by other tasks in the pipeline
#>
Add-BuildTask -Name SetVariables -Jobs {
    $script:moduleFolders = @()
    (Join-Path $BuildRoot 'Public'), (Join-Path $BuildRoot 'Private') | ForEach-Object {
        if (Test-Path $_) { $script:moduleFolders += $_ }
    }

    $manifestPath = if ($script:PlumberConfig.ModuleManifest) {
        if ([System.IO.Path]::IsPathRooted($script:PlumberConfig.ModuleManifest)) {
            $script:PlumberConfig.ModuleManifest
        } else {
            Join-Path $BuildRoot $script:PlumberConfig.ModuleManifest
        }
    } else {
        Get-ChildItem $BuildRoot -File -Filter '*.psd1' |
            Select-Object -First 1 -ExpandProperty FullName
    }

    $script:moduleManifest = Get-Item $manifestPath
    $script:moduleName = $script:moduleManifest.BaseName
    $script:psd1 = Import-PowerShellDataFile $script:moduleManifest.FullName

    Write-Build White "BuildRoot: $BuildRoot"
    Write-Build White "moduleName: $script:moduleName"
    Write-Build White "moduleFolders: $script:moduleFolders"
}
