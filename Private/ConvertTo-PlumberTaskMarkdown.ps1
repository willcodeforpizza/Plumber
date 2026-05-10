function ConvertTo-PlumberTaskMarkdown {
    <#
        .SYNOPSIS
        Converts Plumber task help metadata to Markdown.

        .DESCRIPTION
        Builds the generated Markdown page for a parsed Plumber task help
        object.

        .PARAMETER Help
        The parsed task help metadata.

        .PARAMETER AllHelp
        All parsed task help metadata, used to build navigation links.

        .EXAMPLE
        ConvertTo-PlumberTaskMarkdown -Help $help

        Returns Markdown for the task help page.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory)]
        [pscustomobject]
        $Help,

        [pscustomobject[]]
        $AllHelp = @()
    )

    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add("# $($Help.Name)")
    $lines.Add('')

    Add-PlumberTaskMarkdownSection -Lines $lines -Title 'Synopsis' -Content $Help.Synopsis
    Add-PlumberTaskMarkdownSection -Lines $lines -Title 'Description' -Content $Help.Description

    if ($Help.Group) {
        Add-PlumberTaskMarkdownSection -Lines $lines -Title 'Group' -Content $Help.Group
    }

    if ($Help.Includes) {
        $includes = @(
            foreach ($include in $Help.Includes) {
                '- `' + $include + '`'
            }
        ) -join "`n"
        Add-PlumberTaskMarkdownSection -Lines $lines -Title 'Includes' -Content $includes
    }

    Add-PlumberTaskMarkdownSection -Lines $lines -Title 'Configuration' -Content $Help.Configuration
    Add-PlumberTaskMarkdownSection -Lines $lines -Title 'Run' -Content $Help.Run
    Add-PlumberTaskMarkdownSection -Lines $lines -Title 'Pass' -Content $Help.Pass
    Add-PlumberTaskMarkdownSection -Lines $lines -Title 'Fail' -Content $Help.Fail

    $navigation = [System.Collections.Generic.List[string]]::new()
    $navigation.Add('- [Task index](index.md)')

    if ($Help.Group) {
        $navigation.Add("- [Group: $($Help.Group)]($($Help.Group).md)")
        $siblings = @(
            $AllHelp |
                Where-Object {$_.Group -eq $Help.Group -and -not $_.Includes} |
                Sort-Object Name
        )
    } else {
        $siblings = @(
            $AllHelp |
                Where-Object Includes |
                Sort-Object Name
        )
    }

    $currentIndex = [array]::IndexOf(@($siblings.Name), $Help.Name)
    if ($currentIndex -gt 0) {
        $previous = $siblings[$currentIndex - 1]
        $navigation.Add("- Previous: [$($previous.Name)]($($previous.Name).md)")
    }
    if ($currentIndex -ge 0 -and $currentIndex -lt ($siblings.Count - 1)) {
        $next = $siblings[$currentIndex + 1]
        $navigation.Add("- Next: [$($next.Name)]($($next.Name).md)")
    }

    Add-PlumberTaskMarkdownSection -Lines $lines -Title 'Navigation' -Content ($navigation -join "`n")

    ($lines -join "`n").TrimEnd() + "`n"
}
