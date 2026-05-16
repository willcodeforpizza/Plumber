function Test-PlumberTaskPathExcluded {
    <#
        .SYNOPSIS
        Tests whether a path is excluded for a Plumber task.

        .DESCRIPTION
        Reads task-scoped exclude patterns from PlumberConfig.Tasks.<Task>.Exclude and
        returns true when the supplied path matches a pattern for the task.

        .PARAMETER Task
        The task name to check.

        .PARAMETER Path
        The path to check.

        .EXAMPLE
        Test-PlumberTaskPathExcluded -Task Backticks -Path ./Tests/Assets/File.ps1

        Returns true when the Backticks task has an exclude path matching the
        supplied path.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory)]
        [string]
        $Task,

        [Parameter(Mandatory)]
        [string]
        $Path
    )

    if (-not $script:PlumberConfig.Tasks) {
        return $false
    }

    if (-not $script:PlumberConfig.Tasks.ContainsKey($Task)) {
        return $false
    }

    $taskConfig = $script:PlumberConfig.Tasks[$Task]
    if (-not $taskConfig.Exclude) {
        return $false
    }

    $absolutePath = [System.IO.Path]::GetFullPath($Path).Replace('\', '/')
    $relativePath = if ($script:PlumberConfig.BuildRoot) {
        [System.IO.Path]::GetRelativePath($script:PlumberConfig.BuildRoot, $Path)
    } else {
        $Path
    }
    $normalizedPath = $relativePath.Replace('\', '/')

    foreach ($pattern in @($taskConfig.Exclude)) {
        $normalizedPattern = $pattern.Replace('\', '/')
        if (
            $normalizedPath -like $normalizedPattern -or
            $absolutePath -like $normalizedPattern -or
            $absolutePath -like "*/$normalizedPattern"
        ) {
            return $true
        }
    }

    $false
}
