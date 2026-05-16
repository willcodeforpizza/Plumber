function Import-PlumberDependency {
    <#
        .SYNOPSIS
        Imports or installs PowerShell module dependencies.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [object[]]
        $Dependency,

        [switch]
        $InstallMissing
    )

    foreach ($item in $Dependency) {
        $name = $item.ModuleName
        $version = $item.ModuleVersion

        if (-not $name -or -not $version) {
            throw 'Plumber dependency entries must include ModuleName and ModuleVersion.'
        }

        $loadedModule = Get-Module -Name $name |
            Where-Object { $_.Version -ge [version]$version } |
                Select-Object -First 1
        if ($loadedModule) {
            continue
        }

        try {
            Import-Module -Name $name -MinimumVersion $version -ErrorAction Stop
            continue
        }
        catch {
            $importError = $PSItem
        }

        if (-not $InstallMissing) {
            throw (
                "Could not load $name v$version. " +
                "Install with 'Install-Module $name -RequiredVersion $version -Scope CurrentUser -Force'. " +
                "To allow Plumber to install missing dependencies during import, use " +
                "'Import-Module Plumber -ArgumentList @{ InstallMissingDependencies = `$true }'. " +
                "Error: $importError"
            )
        }

        $installModule = Get-Command Install-Module -ErrorAction SilentlyContinue
        if (-not $installModule) {
            throw (
                "Could not load $name v$version and Install-Module is not available. " +
                "Install the dependency manually. Error: $importError"
            )
        }

        try {
            Install-PlumberModuleDependency -Name $name -RequiredVersion $version
            Import-Module -Name $name -MinimumVersion $version -ErrorAction Stop
        }
        catch {
            throw (
                "Could not install or load $name v$version. " +
                "Install with 'Install-Module $name -RequiredVersion $version -Scope CurrentUser -Force'. " +
                "Error: $PSItem"
            )
        }
    }
}
