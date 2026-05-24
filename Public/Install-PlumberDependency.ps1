function Install-PlumberDependency {
    <#
        .SYNOPSIS
        Installs build dependencies declared for a Plumber-enabled repository.

        .DESCRIPTION
        Reads a Plumber.dependencies.psd1 file and installs the modules listed
        under the Modules key. This is intended for development and CI setup so
        runtime module manifests do not need to declare Plumber build tooling.
        Importing a consumer module should not install dependencies; callers
        opt in by running this command before invoking Plumber tasks.

        .PARAMETER Path
        A repository directory or dependency file path. When a directory is
        provided, Plumber looks for Plumber.dependencies.psd1 in that directory.

        .PARAMETER Scope
        Optional task scope names to install. Core dependencies are always
        included when a scope is supplied. Dependency scopes should match
        Plumber task or task-group names, for example PesterUnit, YAML, or
        ReleaseHygiene.

        .EXAMPLE
        Install-PlumberDependency -Path .

        .EXAMPLE
        Import-Module Plumber -ArgumentList @{ InstallMissingDependencies = $true }
        Install-PlumberDependency
        Invoke-Plumber -OutputMode CI
    #>
    [CmdletBinding()]
    param (
        [string]
        $Path = '.',

        [string[]]
        $Scope
    )

    $dependencyPath = if (Test-Path -LiteralPath $Path -PathType Container) {
        Join-Path $Path 'Plumber.dependencies.psd1'
    } else {
        $Path
    }

    if (-not (Test-Path -LiteralPath $dependencyPath -PathType Leaf)) {
        throw "Could not find Plumber dependency file '$dependencyPath'."
    }

    $definition = Import-PowerShellDataFile -Path $dependencyPath
    $dependencies = @(Select-PlumberDependency -Dependency $definition.Modules -Scope $Scope)
    if (-not $dependencies) {
        throw "Plumber dependency file '$dependencyPath' does not define any Modules for the requested scope."
    }

    Import-PlumberDependency -Dependency $dependencies -InstallMissing
}
