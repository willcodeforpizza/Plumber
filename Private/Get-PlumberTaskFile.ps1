function Get-PlumberTaskFile {
    <#
        .SYNOPSIS
        Gets files for a Plumber task.

        .DESCRIPTION
        Returns files under the build root after applying optional changed-file
        scope, extension, base path, and task-scoped exclude filters. Files
        under directories named in the ExcludeDirectories config (`.git` and
        `out` by default, matched as path segments at any depth) never enter
        the shared file list. The full build-root file list is cached for the
        current build run.

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
        $discoveredFiles = @(Get-ChildItem $BuildRoot -File -Recurse -Force)

        $excludedDirectories = @($script:PlumberConfig.ExcludeDirectories)
        if ($excludedDirectories) {
            $excludedDirectorySet = [System.Collections.Generic.HashSet[string]]::new(
                [string[]]$excludedDirectories,
                (Get-PlumberPathStringComparer)
            )
            # [char[]] is load-bearing: an object[] binds to Split(string,...)
            # and silently fails to split on the separator characters.
            $separators = [char[]]@(
                [System.IO.Path]::DirectorySeparatorChar
                [System.IO.Path]::AltDirectorySeparatorChar
            )
            $discoveredFiles = @(
                $discoveredFiles | Where-Object {
                    $relativeDirectory = [System.IO.Path]::GetRelativePath(
                        $BuildRoot,
                        $_.DirectoryName
                    )
                    $excluded = $false
                    foreach ($segment in $relativeDirectory.Split($separators)) {
                        if ($excludedDirectorySet.Contains($segment)) {
                            $excluded = $true
                            break
                        }
                    }
                    -not $excluded
                }
            )
        }

        $script:PlumberFiles = $discoveredFiles
    }

    if (
        $script:PlumberConfig.FileScope -and
        $script:PlumberConfig.FileScope -notin 'All', 'Changed'
    ) {
        throw "Unsupported FileScope '$($script:PlumberConfig.FileScope)'. Use 'All' or 'Changed'."
    }

    if (
        $script:PlumberConfig.FileScope -eq 'Changed' -and
        -not $script:PlumberChangedFilesLoaded
    ) {
        $script:PlumberChangedFiles = @(
            Get-PlumberChangedFile -BuildRoot $BuildRoot -DiffBase $script:PlumberConfig.DiffBase
        )
        $script:PlumberChangedFilesLoaded = $true

        if ($script:PlumberChangedFiles.Count -gt 0) {
            Write-Build Yellow "FileScope Changed: $($script:PlumberChangedFiles.Count) file(s)"
        } else {
            Write-Build Yellow 'FileScope Changed: no changed files'
        }
    }

    $basePath = if ($Path) {
        if ([System.IO.Path]::IsPathRooted($Path)) {
            [System.IO.Path]::GetFullPath($Path)
        } else {
            [System.IO.Path]::GetFullPath((Join-Path $BuildRoot $Path))
        }
    }

    $files = $script:PlumberFiles
    if ($script:PlumberConfig.FileScope -eq 'Changed') {
        $changedPathSet = [System.Collections.Generic.HashSet[string]]::new(
            (Get-PlumberPathStringComparer)
        )
        foreach ($changedFile in $script:PlumberChangedFiles) {
            $null = $changedPathSet.Add($changedFile.FullName)
        }

        $files = @($files | Where-Object {$changedPathSet.Contains($_.FullName)})
    }

    if ($basePath) {
        $pathComparison = Get-PlumberPathStringComparison
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
                        $pathComparison
                    ) -or
                    $_.FullName.StartsWith(
                        $basePathWithSeparator,
                        $pathComparison
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
