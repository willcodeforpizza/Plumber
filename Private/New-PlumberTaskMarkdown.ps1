function New-PlumberTaskMarkdown {
    <#
        .SYNOPSIS
        Generates Markdown files for documented Plumber tasks.

        .DESCRIPTION
        Reads task documentation from task files, converts the parsed help to
        Markdown, and writes one page per documented task.

        .PARAMETER TaskRoot
        The task root to scan.

        .PARAMETER OutputRoot
        The directory where generated Markdown files are written.

        .EXAMPLE
        New-PlumberTaskMarkdown -TaskRoot ./Tasks -OutputRoot ./docs/tasks

        Generates task Markdown pages.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory)]
        [string]
        $TaskRoot,

        [Parameter(Mandatory)]
        [string]
        $OutputRoot
    )

    if (-not (Test-Path $OutputRoot) -and $PSCmdlet.ShouldProcess($OutputRoot, 'Create directory')) {
        New-Item -Path $OutputRoot -ItemType Directory -Force | Out-Null
    }

    $taskFiles = Get-ChildItem $TaskRoot -File -Recurse -Filter '*.ps1' |
        Where-Object {$_.Name -notmatch '^TaskLoader\.ps1$|^SetVariables\.ps1$'} |
        Sort-Object FullName

    $taskHelp = foreach ($taskFile in $taskFiles) {
        try {
            $help = Get-PlumberTaskHelp -Path $taskFile.FullName
        }
        catch {
            continue
        }
        if (-not $help.Run) {
            continue
        }

        $help
    }

    foreach ($help in $taskHelp) {
        $markdown = ConvertTo-PlumberTaskMarkdown -Help $help -AllHelp $taskHelp
        $outputPath = Join-Path $OutputRoot "$($help.Name).md"
        if ($PSCmdlet.ShouldProcess($outputPath, 'Write task Markdown')) {
            Set-Content -Path $outputPath -Value $markdown -NoNewline
        }
    }

    $index = ConvertTo-PlumberTaskMarkdownIndex -Help $taskHelp
    $indexPath = Join-Path $OutputRoot 'index.md'
    if ($PSCmdlet.ShouldProcess($indexPath, 'Write task Markdown index')) {
        Set-Content -Path $indexPath -Value $index -NoNewline
    }
}
