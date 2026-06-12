Add-BuildTask -Name ValidateTaskHelp -Jobs {
    $taskRoot = Join-Path $BuildRoot 'Tasks'
    $taskFiles = Get-ChildItem $taskRoot -File -Recurse -Filter '*.ps1' |
        Where-Object {$_.Name -notmatch '^TaskLoader\.ps1$|^SetVariables\.ps1$'} |
            Sort-Object FullName
    $taskGroups = @(Get-PlumberTaskGroup)

    $failures = foreach ($taskFile in $taskFiles) {
        try {
            $help = Get-PlumberTaskHelp -Path $taskFile.FullName
        }
        catch {
            "$($taskFile.FullName): $_"
            continue
        }

        $validationSplat = @{
            Help      = $help
            TaskFile  = $taskFile
            TaskRoot  = $taskRoot
            BuildRoot = $BuildRoot
            TaskGroup = $taskGroups
        }
        Get-PlumberTaskHelpValidationFailure @validationSplat
    }

    if ($failures) {
        Write-Error ($failures -join [Environment]::NewLine)
    }
}
