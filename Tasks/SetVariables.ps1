<#
    .SYNOPSIS
    Defines variables used by other tasks in the pipeline
#>
task SetVariables {
    $script:moduleFolders = @()
    "$BuildRoot\Public", "$BuildRoot\Private" | ForEach-Object {
        if (Test-Path $_) {$script:moduleFolders += $_}
    }

    $script:moduleName = $BuildRoot | Split-Path -Leaf
    $script:psd1 = Import-PowerShellDataFile "$BuildRoot\$script:moduleName.psd1"

    Write-Build White "BuildRoot:     $BuildRoot"
    Write-Build White "moduleName:    $script:moduleName"
    Write-Build White "moduleFolders: $script:moduleFolders"
}