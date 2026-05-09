<#
    .SYNOPSIS
    Defines variables used by other tasks in the pipeline
#>
Add-BuildTask -Name SetVariables -Jobs {
    $script:moduleFolders = @()
    (Join-Path $BuildRoot 'Public'), (Join-Path $BuildRoot 'Private') | ForEach-Object {
        if (Test-Path $_) { $script:moduleFolders += $_ }
    }

    $script:moduleManifest = Get-ChildItem $BuildRoot -File -Filter '*.psd1' |
        Select-Object -First 1
    $script:moduleName = $script:moduleManifest.BaseName
    $script:psd1 = Import-PowerShellDataFile $script:moduleManifest.FullName

    Write-Build White "BuildRoot: $BuildRoot"
    Write-Build White "moduleName: $script:moduleName"
    Write-Build White "moduleFolders: $script:moduleFolders"
}
