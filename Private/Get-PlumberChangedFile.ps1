function Get-PlumberChangedFile {
    <#
        .SYNOPSIS
        Gets repository files changed in git.

        .DESCRIPTION
        Returns changed, staged, unstaged and untracked file paths under the
        build root. When DiffBase is provided, committed changes between the
        base and HEAD are included.

        Deleted files are excluded because validation tasks can only inspect
        files that still exist.

        .PARAMETER BuildRoot
        The repository root used for git path resolution.

        .PARAMETER DiffBase
        Optional git revision used as the base for committed changes.

        .EXAMPLE
        Get-PlumberChangedFile -BuildRoot . -DiffBase origin/main

        Returns files changed from origin/main plus local working tree changes.
    #>
    [CmdletBinding()]
    [OutputType([System.IO.FileInfo])]
    param (
        [Parameter(Mandatory)]
        [string]
        $BuildRoot,

        [string]
        $DiffBase
    )

    $git = Get-Command git -ErrorAction SilentlyContinue
    if (-not $git) {
        throw 'FileScope Changed requires git.'
    }

    $resolvedBuildRoot = [System.IO.Path]::GetFullPath($BuildRoot)
    $gitRoot = & $git -C $resolvedBuildRoot rev-parse --show-toplevel 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $gitRoot) {
        throw 'FileScope Changed requires BuildRoot to be inside a git repository.'
    }
    $gitRoot = [System.IO.Path]::GetFullPath($gitRoot)

    $pathSet = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::OrdinalIgnoreCase
    )

    $diffArgs = [System.Collections.Generic.List[object]]::new()
    $diffArgs.Add(@('diff', '--name-only', '--diff-filter=ACMR'))
    $diffArgs.Add(@('diff', '--name-only', '--diff-filter=ACMR', '--cached'))
    $diffArgs.Add(@('ls-files', '--others', '--exclude-standard'))

    if ($DiffBase) {
        $diffArgs.Add(@('diff', '--name-only', '--diff-filter=ACMR', "$DiffBase...HEAD"))
    }

    foreach ($diffArg in $diffArgs) {
        $paths = & $git -C $resolvedBuildRoot @diffArg
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to get changed files from git using: git $($diffArg -join ' ')"
        }

        foreach ($path in $paths) {
            if (-not $path) {
                continue
            }

            $fullPath = [System.IO.Path]::GetFullPath((Join-Path $gitRoot $path))
            if (Test-Path $fullPath -PathType Leaf) {
                $null = $pathSet.Add($fullPath)
            }
        }
    }

    foreach ($path in $pathSet) {
        Get-Item $path
    }
}
