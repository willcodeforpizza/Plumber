<#
    .SYNOPSIS
    Generates Plumber documentation.

    .DESCRIPTION
    This is an internal build task for Plumber, and not part of the core task list.

    Generates Markdown task pages from the custom task help comments in the
    Plumber task files.

    .RUN
    ```powershell
    Invoke-Plumber -Task GenerateDocs
    ```
#>
Add-BuildTask -Name GenerateDocs -Jobs {
    $taskRoot = Join-Path $BuildRoot 'Tasks'
    $outputRoot = Join-Path $BuildRoot 'docs/tasks'
    New-PlumberTaskMarkdown -TaskRoot $taskRoot -OutputRoot $outputRoot
}
