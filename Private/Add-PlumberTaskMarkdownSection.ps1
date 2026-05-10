function Add-PlumberTaskMarkdownSection {
    <#
        .SYNOPSIS
        Adds a task Markdown section when content is present.
    #>
    param (
        [Parameter(Mandatory)]
        [System.Collections.IList]
        $Lines,

        [Parameter(Mandatory)]
        [string]
        $Title,

        [AllowNull()]
        [string]
        $Content
    )

    if (-not $Content) {
        return
    }

    $Lines.Add("## $Title")
    $Lines.Add('')
    foreach ($line in ($Content -split '\r?\n')) {
        $Lines.Add($line)
    }
    $Lines.Add('')
}
