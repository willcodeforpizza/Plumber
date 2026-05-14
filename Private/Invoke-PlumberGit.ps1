function Invoke-PlumberGit {
    <#
        .SYNOPSIS
        Runs git with the supplied arguments.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string[]]
        $ArgumentList
    )

    $output = & git @ArgumentList 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "git $($ArgumentList -join ' ') failed. $output"
    }

    $output
}
