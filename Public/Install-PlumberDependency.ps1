function Install-PlumberDependency {
    <#
        .SYNOPSIS
        Installs Plumber-related PowerShell module dependencies.

        .DESCRIPTION
        Without -Internal, reads a Plumber.dependencies.psd1 file at the
        supplied path and installs the modules listed under the Modules key.
        This is the consumer-repo surface: it installs the build and release
        modules a repository's Plumber tasks need.

        With -Internal, installs Plumber's own task dependencies (Pester,
        PSScriptAnalyzer, InvokeBuild, powershell-yaml) from the
        Plumber.dependencies.psd1 file that ships inside the Plumber module.
        This is the bootstrap surface, exposed so users can resolve a missing
        dependency state without an install-on-import side effect.

        Importing Plumber should not install dependencies as a side effect.
        Callers opt in by running this command before invoking Plumber tasks.

        .PARAMETER Path
        A repository directory or dependency file path. When a directory is
        provided, Plumber looks for Plumber.dependencies.psd1 in that
        directory. Ignored when -Internal is supplied.

        .PARAMETER Internal
        Install Plumber's own task dependencies from the file bundled inside
        the Plumber module.

        .EXAMPLE
        Install-PlumberDependency -Path .

        Install the calling repository's build and release dependencies.

        .EXAMPLE
        Install-PlumberDependency -Internal
        Import-Module Plumber -Force

        Bootstrap Plumber on a clean machine: install Plumber's own task
        dependencies, then re-import to load the full module.

        .EXAMPLE
        Install-PlumberDependency -Internal
        Install-PlumberDependency
        Invoke-Plumber -OutputMode CI

        CI flow: install Plumber's task dependencies, install this repo's
        build dependencies, run validation.
    #>
    [CmdletBinding()]
    param (
        [string]
        $Path = '.',

        [switch]
        $Internal
    )

    $dependencyPath = if ($Internal) {
        Join-Path $script:moduleRoot 'Plumber.dependencies.psd1'
    }
    elseif (Test-Path -LiteralPath $Path -PathType Container) {
        Join-Path $Path 'Plumber.dependencies.psd1'
    }
    else {
        $Path
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
