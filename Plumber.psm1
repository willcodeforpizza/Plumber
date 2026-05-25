$script:moduleRoot = $PSScriptRoot

# Phase 1: load the bootstrap-safe surface. Import-PlumberDependency and
# Install-PlumberDependency depend only on built-in cmdlets, so they can run
# before Plumber's own task dependencies are present.
. (Join-Path $PSScriptRoot 'Private/Import-PlumberDependency.ps1')
. (Join-Path $PSScriptRoot 'Public/Install-PlumberDependency.ps1')

$dependencyDefinition = Import-PowerShellDataFile (
    Join-Path $PSScriptRoot 'Plumber.dependencies.psd1'
)

try {
    Import-PlumberDependency -Dependency $dependencyDefinition.Modules -ErrorAction Stop
}
catch {
    Write-Warning (
        "Plumber dependencies are not available. Run " +
        "'Install-PlumberDependency -Internal' to install them, then " +
        "'Import-Module Plumber -Force' to load the full module. " +
        "Error: $PSItem"
    )
    Export-ModuleMember -Function Install-PlumberDependency
    return
}

# Phase 2: full load. Sort by FullName so dot-source order is deterministic
# across platforms, protecting against future class/enum ordering issues.
Get-ChildItem (
    Join-Path $PSScriptRoot 'Public'
), (
    Join-Path $PSScriptRoot 'Private'
), (
    Join-Path $PSScriptRoot 'TaskFunctions'
) |
    Sort-Object FullName |
        ForEach-Object { . $_.FullName }
