function Resolve-PlumberBuildFile {
    <#
        .SYNOPSIS
        Resolves the build file Invoke-Plumber should run.

        .DESCRIPTION
        Resolves an explicit build file path when supplied. Otherwise, looks in
        the current directory for a module manifest and uses the matching
        `<ModuleName>.build.ps1` file.

        .PARAMETER BuildFile
        Optional build file path. Relative paths are resolved from the current
        directory.

        .EXAMPLE
        Resolve-PlumberBuildFile

        Returns the build file matching the module manifest in the current
        directory.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [string]
        $BuildFile
    )

    $currentPath = (Get-Location).ProviderPath
    if ($BuildFile) {
        $resolvedBuildFile = if ([System.IO.Path]::IsPathRooted($BuildFile)) {
            $BuildFile
        } else {
            Join-Path $currentPath $BuildFile
        }

        if (-not (Test-Path $resolvedBuildFile -PathType Leaf)) {
            throw "Build file not found: $resolvedBuildFile"
        }

        return (Resolve-Path $resolvedBuildFile).Path
    }

    $manifests = @(Get-ChildItem $currentPath -File -Filter '*.psd1')
    foreach ($manifest in $manifests) {
        $candidate = Join-Path $currentPath "$($manifest.BaseName).build.ps1"
        if (Test-Path $candidate -PathType Leaf) {
            return (Resolve-Path $candidate).Path
        }
    }

    $buildFiles = @(Get-ChildItem $currentPath -File -Filter '*.build.ps1')
    if ($buildFiles.Count -eq 1) {
        return $buildFiles[0].FullName
    }

    if ($buildFiles.Count -gt 1) {
        throw 'Multiple build files found. Use -BuildFile to choose one.'
    }

    throw "No build file found in $currentPath"
}
