param (
    [object]
    $ImportOptions = @{}
)

$script:moduleRoot = $PSScriptRoot

$dependencyDefinition = Import-PowerShellDataFile (Join-Path $PSScriptRoot 'Plumber.dependencies.psd1')
. (Join-Path $PSScriptRoot 'Private/Install-PlumberModuleDependency.ps1')
. (Join-Path $PSScriptRoot 'Private/Import-PlumberDependency.ps1')
. (Join-Path $PSScriptRoot 'Private/Select-PlumberDependency.ps1')
$installMissingDependencies = if ($ImportOptions -is [hashtable]) {
    $ImportOptions.InstallMissingDependencies -eq $true
} else {
    $ImportOptions -eq $true
}
$dependencyScope = if ($installMissingDependencies) {
    $null
} else {
    'Core'
}
$dependencySplat = @{
    Dependency = Select-PlumberDependency -Dependency $dependencyDefinition.Modules -Scope $dependencyScope
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
