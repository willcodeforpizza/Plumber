param (
    [object]
    $ImportOptions = @{}
)

$script:moduleRoot = $PSScriptRoot

$manifest = Import-PowerShellDataFile (Join-Path $PSScriptRoot 'Plumber.psd1')
. (Join-Path $PSScriptRoot 'Private/Install-PlumberModuleDependency.ps1')
. (Join-Path $PSScriptRoot 'Private/Import-PlumberDependency.ps1')
$dependencySplat = @{
    Dependency = $manifest.ModuleList
}
$installMissingDependencies = if ($ImportOptions -is [hashtable]) {
    $ImportOptions.InstallMissingDependencies -eq $true
} else {
    $ImportOptions -eq $true
}
if ($installMissingDependencies) {
    $dependencySplat.InstallMissing = $true
}
Import-PlumberDependency @dependencySplat

Get-ChildItem (
    Join-Path $PSScriptRoot 'Public'
), (
    Join-Path $PSScriptRoot 'Private'
), (
    Join-Path $PSScriptRoot 'TaskFunctions'
) |
    ForEach-Object {. $_.FullName}
