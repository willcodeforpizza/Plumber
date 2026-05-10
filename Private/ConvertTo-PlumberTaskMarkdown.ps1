function ConvertTo-PlumberTaskMarkdown {
    <#
        .SYNOPSIS
        Converts Plumber task help metadata to Markdown.

        .DESCRIPTION
        Builds the generated Markdown page for a parsed Plumber task help
        object.

        .PARAMETER Help
        The parsed task help metadata.

        .EXAMPLE
        ConvertTo-PlumberTaskMarkdown -Help $help

        Returns Markdown for the task help page.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory)]
        [pscustomobject]
        $Help
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

    ($lines -join "`n").TrimEnd() + "`n"
}
