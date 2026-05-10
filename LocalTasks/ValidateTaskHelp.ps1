Add-BuildTask -Name ValidateTaskHelp -Jobs {
    . (Join-Path $script:PlumberConfig.ModuleRoot 'Private/ConvertFrom-PlumberTaskHelpComment.ps1')
    . (Join-Path $script:PlumberConfig.ModuleRoot 'Private/ConvertTo-PlumberTaskHelpSection.ps1')
    . (Join-Path $script:PlumberConfig.ModuleRoot 'Private/Get-PlumberTaskHelp.ps1')
    . (Join-Path $script:PlumberConfig.ModuleRoot 'Private/Get-PlumberTaskHelpSection.ps1')

    $taskRoot = Join-Path $BuildRoot 'Tasks'
    $taskFiles = Get-ChildItem $taskRoot -File -Recurse -Filter '*.ps1' |
        Where-Object {$_.Name -notmatch '^TaskLoader\.ps1$|^SetVariables\.ps1$'} |
            Sort-Object FullName

    $failures = foreach ($taskFile in $taskFiles) {
        try {
            $help = Get-PlumberTaskHelp -Path $taskFile.FullName
        }
        catch {
            "$($taskFile.FullName): $_"
            continue
        }

        $missingSections = [System.Collections.Generic.List[string]]::new()
        foreach ($requiredSection in 'SYNOPSIS', 'DESCRIPTION', 'RUN') {
            if (-not $help.$requiredSection) {
                $missingSections.Add($requiredSection)
            }
        }

        $isInternalTask = $taskFile.Directory.FullName -eq $taskRoot
        $isGroupTask =
            $taskFile.BaseName -eq $taskFile.Directory.Name -or
            ($taskFile.BaseName -eq 'Validate' -and $taskFile.Directory.Name -eq 'Pipeline')
        $isLeafTask = -not $isInternalTask -and -not $isGroupTask

        if ($isGroupTask) {
            if (-not $help.Includes) {
                $missingSections.Add('INCLUDES')
            }
            if ($help.Group) {
                $missingSections.Add('GROUP must be empty for group tasks')
            }
            if ($help.Configuration) {
                $missingSections.Add('CONFIGURATION must be empty for group tasks')
            }
            if ($help.Pass) {
                $missingSections.Add('PASS must be empty for group tasks')
            }
            if ($help.Fail) {
                $missingSections.Add('FAIL must be empty for group tasks')
            }
        } elseif ($isLeafTask) {
            foreach ($requiredSection in 'GROUP', 'CONFIGURATION', 'PASS', 'FAIL') {
                if (-not $help.$requiredSection) {
                    $missingSections.Add($requiredSection)
                }
            }
            if ($help.Includes) {
                $missingSections.Add('INCLUDES must be empty for validation tasks')
            }
        } elseif ($isInternalTask) {
            if ($help.Group) {
                $missingSections.Add('GROUP must be empty for internal tasks')
            }
            if ($help.Includes) {
                $missingSections.Add('INCLUDES must be empty for internal tasks')
            }
            if ($help.Configuration) {
                $missingSections.Add('CONFIGURATION must be empty for internal tasks')
            }
            if ($help.Pass) {
                $missingSections.Add('PASS must be empty for internal tasks')
            }
            if ($help.Fail) {
                $missingSections.Add('FAIL must be empty for internal tasks')
            }
        }

        if ($missingSections.Count -gt 0) {
            $relativeTaskPath = [System.IO.Path]::GetRelativePath($BuildRoot, $taskFile.FullName)
            $sectionList = $missingSections -join ', '
            "$relativeTaskPath ($($help.Name)): missing or invalid task help sections: $sectionList"
        }
    }

    if ($failures) {
        Write-Error ($failures -join [Environment]::NewLine)
    }
}
