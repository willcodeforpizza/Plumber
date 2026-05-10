function Get-PlumberTaskFile {
    <#
        .SYNOPSIS
        Gets files for a Plumber task.

        .DESCRIPTION
        Returns files under the build root after applying optional extension,
        base path, and task-scoped exclude filters. The full build-root file
        list is cached for the current build run.

        .PARAMETER Task
        The task name used to apply task-scoped exclusions.

        .PARAMETER Extension
        Optional file extensions to include.

        .PARAMETER Path
        Optional path under the build root to search.

        .EXAMPLE
        Get-PlumberTaskFile -Task Backticks -Extension '.ps1', '.psm1', '.psd1'

        Returns PowerShell files for Backticks validation after exclusions.
    #>
    [CmdletBinding()]
    [OutputType([System.IO.FileInfo])]
    param (
        [Parameter(Mandatory)]
        [string]
        $Task,

        [string[]]
        $Extension,

        [string]
        $Path
    )

    if (-not $script:PlumberFiles) {
        $script:PlumberFiles = @(Get-ChildItem $BuildRoot -File -Recurse)
    }

    $basePath = if ($Path) {
        if ([System.IO.Path]::IsPathRooted($Path)) {
            [System.IO.Path]::GetFullPath($Path)
        } else {
            [System.IO.Path]::GetFullPath((Join-Path $BuildRoot $Path))
        }
    }

    $files = $script:PlumberFiles
    if ($basePath) {
        $basePath = $basePath.TrimEnd(
            [System.IO.Path]::DirectorySeparatorChar,
            [System.IO.Path]::AltDirectorySeparatorChar
        )
        $basePathWithSeparator = "$basePath$([System.IO.Path]::DirectorySeparatorChar)"
        $files = @(
            $files |
                Where-Object {
                    $_.FullName.Equals(
                        $basePath,
                        [System.StringComparison]::OrdinalIgnoreCase
                    ) -or
                    $_.FullName.StartsWith(
                        $basePathWithSeparator,
                        [System.StringComparison]::OrdinalIgnoreCase
                    )
                }
        )
    }

    if ($Extension) {
        $files = @($files | Where-Object {$_.Extension -in $Extension})
    }

    $files |
        Where-Object {
            -not (Test-PlumberTaskPathExcluded -Task $Task -Path $_.FullName)
        }
}
