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
    # Invoke-Build scope will not see private scoped functions, but these are not public, so we dot source them
    . (Join-Path $script:PlumberConfig.ModuleRoot 'Private/Add-PlumberTaskMarkdownSection.ps1')
    . (Join-Path $script:PlumberConfig.ModuleRoot 'Private/ConvertTo-PlumberTaskMarkdownIndex.ps1')
    . (Join-Path $script:PlumberConfig.ModuleRoot 'Private/ConvertTo-PlumberTaskMarkdown.ps1')
    . (Join-Path $script:PlumberConfig.ModuleRoot 'Private/ConvertFrom-PlumberTaskHelpComment.ps1')
    . (Join-Path $script:PlumberConfig.ModuleRoot 'Private/ConvertTo-PlumberTaskHelpSection.ps1')
    . (Join-Path $script:PlumberConfig.ModuleRoot 'Private/Get-PlumberTaskHelp.ps1')
    . (Join-Path $script:PlumberConfig.ModuleRoot 'Private/Get-PlumberTaskHelpSection.ps1')
    . (Join-Path $script:PlumberConfig.ModuleRoot 'Private/New-PlumberTaskMarkdown.ps1')

    $taskRoot = Join-Path $BuildRoot 'Tasks'
    $outputRoot = Join-Path $BuildRoot 'docs/tasks'
    New-PlumberTaskMarkdown -TaskRoot $taskRoot -OutputRoot $outputRoot
}
