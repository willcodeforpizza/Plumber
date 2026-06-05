function Install-PlumberDependency {
    <#
        .SYNOPSIS
        Installs Plumber-related PowerShell module dependencies.

        .DESCRIPTION
        By default, installs Plumber's own task dependencies from the dependency
        file bundled inside the Plumber module. This is the bootstrap surface for
        clean machines.

        With -Build, reads a Plumber.dependencies.psd1 file at the supplied path
        and installs the modules listed under the Modules key. This is the
        consumer-repo surface: it installs the build and release modules a
        repository's Plumber tasks need.

        Importing Plumber does not install dependencies as a side effect.
        Callers opt in by running this command before invoking Plumber tasks.

        .PARAMETER Path
        A repository directory or dependency file path. When a directory is
        provided, Plumber looks for Plumber.dependencies.psd1 in that directory.
        Path is only used with -Build.

        .PARAMETER Build
        Install the calling repository's build/release dependencies from
        Plumber.dependencies.psd1. Without -Build, Plumber installs its own
        internal task dependencies.

        .EXAMPLE
        Install-PlumberDependency

        Bootstrap Plumber on a clean machine by installing Plumber's own task
        dependencies.

        .EXAMPLE
        Install-PlumberDependency -Build -Path .

        Install the calling repository's build and release dependencies.

        .EXAMPLE
        Import-Module Plumber
        Install-PlumberDependency
        Install-PlumberDependency -Build
        Invoke-Plumber -OutputMode CI

        CI flow: import Plumber, install Plumber's task dependencies, install
        this repo's build dependencies, run validation.
    #>
    [CmdletBinding()]
    param (
        [string]
        $Path = '.',

        [switch]
        $Build
    )

    if (-not $Build -and $PSBoundParameters.ContainsKey('Path')) {
        throw (
            'Path is only valid with -Build. Run Install-PlumberDependency ' +
            'for Plumber dependencies, or Install-PlumberDependency -Build ' +
            '-Path . for repository build dependencies.'
        )
    }

    $dependencyPath = if ($Build) {
        if (Test-Path -LiteralPath $Path -PathType Container) {
            Join-Path $Path 'Plumber.dependencies.psd1'
        } else {
            $Path
        }
    } else {
        Join-Path $script:moduleRoot 'Plumber.internal.dependencies.psd1'
    }

    if (-not (Test-Path -LiteralPath $dependencyPath -PathType Leaf)) {
        throw "Could not find Plumber dependency file '$dependencyPath'."
    }

    $definition = Import-PowerShellDataFile -Path $dependencyPath
    $dependencies = @($definition.Modules)
    if (-not $dependencies) {
        throw "Plumber dependency file '$dependencyPath' does not define any Modules."
    }

    Import-PlumberDependency -Dependency $dependencies -InstallMissing
}
