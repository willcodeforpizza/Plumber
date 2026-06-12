function Get-PlumberTaskHelpValidationFailure {
    <#
        .SYNOPSIS
        Gets a task-help validation failure message for one task.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory)]
        [pscustomobject]
        $Help,

        [Parameter(Mandatory)]
        [System.IO.FileInfo]
        $TaskFile,

        [Parameter(Mandatory)]
        [string]
        $TaskRoot,

        [Parameter(Mandatory)]
        [string]
        $BuildRoot,

        [Parameter(Mandatory)]
        [hashtable[]]
        $TaskGroup
    )

    $missingSections = [System.Collections.Generic.List[string]]::new()
    foreach ($requiredSection in 'SYNOPSIS', 'DESCRIPTION', 'RUN') {
        if (-not $Help.$requiredSection) {
            $missingSections.Add($requiredSection)
        }
    }

    $isInternalTask = $TaskFile.Directory.FullName -eq $TaskRoot
    $isGroupTask =
        $TaskFile.BaseName -eq $TaskFile.Directory.Name -or
        ($TaskFile.BaseName -eq 'Validate' -and $TaskFile.Directory.Name -eq 'Pipeline')
    $isLeafTask = -not $isInternalTask -and -not $isGroupTask

    if ($isGroupTask) {
        if (-not $Help.Includes) {
            $missingSections.Add('INCLUDES')
        } else {
            $matchingGroup = $TaskGroup | Where-Object Parent -EQ $Help.Name
            if ($matchingGroup) {
                $expectedIncludes = @($matchingGroup.Children)
                $actualIncludes = @($Help.Includes)
                if (($actualIncludes -join "`n") -ne ($expectedIncludes -join "`n")) {
                    $missingSections.Add(
                        'INCLUDES must match task group children ' +
                        "(expected: $($expectedIncludes -join ', '); " +
                        "actual: $($actualIncludes -join ', '))"
                    )
                }
            }
        }
        if ($Help.Group) {
            $missingSections.Add('GROUP must be empty for group tasks')
        }
        if ($Help.Configuration) {
            $missingSections.Add('CONFIGURATION must be empty for group tasks')
        }
        if ($Help.Pass) {
            $missingSections.Add('PASS must be empty for group tasks')
        }
        if ($Help.Fail) {
            $missingSections.Add('FAIL must be empty for group tasks')
        }
    } elseif ($isLeafTask) {
        foreach ($requiredSection in 'GROUP', 'CONFIGURATION', 'PASS', 'FAIL') {
            if (-not $Help.$requiredSection) {
                $missingSections.Add($requiredSection)
            }
        }
        if ($Help.Includes) {
            $missingSections.Add('INCLUDES must be empty for validation tasks')
        }
    } elseif ($isInternalTask) {
        if ($Help.Group) {
            $missingSections.Add('GROUP must be empty for internal tasks')
        }
        if ($Help.Includes) {
            $missingSections.Add('INCLUDES must be empty for internal tasks')
        }
        if ($Help.Configuration) {
            $missingSections.Add('CONFIGURATION must be empty for internal tasks')
        }
        if ($Help.Pass) {
            $missingSections.Add('PASS must be empty for internal tasks')
        }
        if ($Help.Fail) {
            $missingSections.Add('FAIL must be empty for internal tasks')
        }
    }

    if ($missingSections.Count -eq 0) {
        return
    }

    $relativeTaskPath = [System.IO.Path]::GetRelativePath($BuildRoot, $TaskFile.FullName)
    $sectionList = $missingSections -join ', '
    "$relativeTaskPath ($($Help.Name)): missing or invalid task help sections: $sectionList"
}
