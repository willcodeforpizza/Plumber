function Import-PlumberDependency {
    <#
        .SYNOPSIS
        Imports or installs PowerShell module dependencies.

        .DESCRIPTION
        Iterates a list of ModuleName/ModuleVersion entries and imports each
        dependency at the requested minimum version. When -InstallMissing is
        supplied, missing or out-of-range dependencies are installed first.
        Installation prefers Install-PSResource (PSResourceGet) when available
        and falls back to Install-Module (PowerShellGet v2).

        .PARAMETER Dependency
        A collection of hashtables, each with ModuleName and ModuleVersion.

        .PARAMETER InstallMissing
        Install dependencies that are not present at the required version.
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

        $requiredVersion = [System.Management.Automation.SemanticVersion]$version

        $loadedModule = Get-Module -Name $name |
            Where-Object {
                ([System.Management.Automation.SemanticVersion]$_.Version) -ge $requiredVersion
            } |
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
                "Could not load $name v$version or higher. " +
                "Install with 'Install-PSResource $name -Version ""[$version,)"" -Scope CurrentUser' " +
                "or 'Install-Module $name -MinimumVersion $version -Scope CurrentUser -Force'. " +
                "To let Plumber install its own missing dependencies, run " +
                "'Install-PlumberDependency -Internal' then re-import Plumber. " +
                "Error: $importError"
            )
        }

        $installPSResource = Get-Command Install-PSResource -ErrorAction SilentlyContinue
        $installModule = Get-Command Install-Module -ErrorAction SilentlyContinue
        if (-not $installPSResource -and -not $installModule) {
            throw (
                "Could not load $name v$version and neither Install-PSResource " +
                "nor Install-Module is available. Install the dependency manually. " +
                "Error: $importError"
            )
        }

        try {
            if ($installPSResource) {
                $installSplat = @{
                    Name            = $name
                    Version         = "[$version,)"
                    Scope           = 'CurrentUser'
                    TrustRepository = $true
                    ErrorAction     = 'Stop'
                }
                Install-PSResource @installSplat
            }
            else {
                $installSplat = @{
                    Name               = $name
                    MinimumVersion     = $version
                    Scope              = 'CurrentUser'
                    Force              = $true
                    SkipPublisherCheck = $true
                    ErrorAction        = 'Stop'
                }
                Install-Module @installSplat
            }
            Import-Module -Name $name -MinimumVersion $version -ErrorAction Stop
        }
        catch {
            throw (
                "Could not install or load $name v$version. " +
                "Install with 'Install-PSResource $name -Version ""[$version,)"" -Scope CurrentUser' " +
                "or 'Install-Module $name -MinimumVersion $version -Scope CurrentUser -Force'. " +
                "Error: $PSItem"
            )
        }
    }
}
