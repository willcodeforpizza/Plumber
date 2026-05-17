function Get-PlumberToDoComment {
    <#
        .SYNOPSIS
        Finds TODO markers in PowerShell line comments.

        .DESCRIPTION
        Returns one record per line comment containing a TODO marker.
        Walks the AST token stream so TODO text inside string literals,
        here-strings, or code (variable names, etc.) is never flagged.

        Both leading-comment TODOs (`# TODO: fix this`) and inline TODOs
        (`$x = 1 # TODO: fix this`) are reported. PowerShell block
        comments are skipped because Plumber task help often contains
        documentation examples like .FAIL blocks that demonstrate the
        offending pattern.

        .PARAMETER Path
        The PowerShell file to inspect.

        .EXAMPLE
        Get-PlumberToDoComment -Path ./MyScript.ps1
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Mandatory)]
        [string]
        $Path
    )

    $tokens = $null
    $parseErrors = $null
    $null = [System.Management.Automation.Language.Parser]::ParseFile(
        $Path,
        [ref] $tokens,
        [ref] $parseErrors
    )
    if ($parseErrors) {
        throw "Failed to parse $Path"
    }

    $commentKind = [System.Management.Automation.Language.TokenKind]::Comment
    foreach ($token in $tokens) {
        if ($token.Kind -ne $commentKind) {
            continue
        }
        if ($token.Text.StartsWith('<#')) {
            continue
        }
        if ($token.Text -notmatch '\bTODO\b\s*:?\s*(.*)') {
            continue
        }

        [pscustomobject]@{
            Path    = $Path
            Line    = $token.Extent.StartLineNumber
            Column  = $token.Extent.StartColumnNumber
            Message = $Matches[1].Trim()
        }
    }
}
