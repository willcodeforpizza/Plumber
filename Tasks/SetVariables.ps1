<#
    .SYNOPSIS
    Defines variables used by other tasks in the pipeline
#>
Add-BuildTask -Name SetVariables -Jobs {
    $script:PlumberConfig.BuildRoot = $BuildRoot
    $script:PlumberFiles = $null
    $script:PlumberChangedFiles = $null
    $script:PlumberChangedFilesLoaded = $false
    $moduleFolders = [System.Collections.Generic.List[string]]::new()
    $moduleFolderPaths = @(
        'Public'
        'Private'
        $script:PlumberConfig.IncludeModuleFolders
    )
    foreach ($moduleFolderPath in $moduleFolderPaths) {
        $moduleFolder = if ([System.IO.Path]::IsPathRooted($moduleFolderPath)) {
            $moduleFolderPath
        } else {
            Join-Path $BuildRoot $moduleFolderPath
        }
        if (Test-Path $moduleFolder) { $moduleFolders.Add($moduleFolder) }
    }
    # Stored as an array: consumers hand this to Pester's CodeCoveragePath.
    $script:moduleFolders = $moduleFolders.ToArray()

    $manifestPath = Resolve-PlumberModuleManifest -BuildRoot $BuildRoot -ModuleManifest (
        $script:PlumberConfig.ModuleManifest
    )

    $script:moduleManifest = Get-Item $manifestPath
    $script:moduleName = $script:moduleManifest.BaseName
    $script:psd1 = Import-PowerShellDataFile $script:moduleManifest.FullName

    Write-Build White "BuildRoot: $BuildRoot"
    Write-Build White "moduleName: $script:moduleName"
    Write-Build White "moduleFolders: $script:moduleFolders"
}
