function Get-PlumberLineContinuation {
    <#
        .SYNOPSIS
        Finds PowerShell line-continuation backticks.

        .DESCRIPTION
        Returns one record per source line whose final non-whitespace
        character is a backtick used as a line continuation. Backticks
        inside strings, here-strings, and comments are excluded by
        cross-referencing the AST token extents, so a literal backtick at
        the end of a string line (e.g. inside a code fence in a comment
        block) is not flagged.

        Escaped backticks (a trailing pair of backticks like `` ``) are
        also skipped: they represent a literal backtick character in the
        source, not a line continuation.

        .PARAMETER Path
        The PowerShell file to inspect.

        .EXAMPLE
        Get-PlumberLineContinuation -Path ./MyScript.ps1
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

    $shadowKinds = @(
        [System.Management.Automation.Language.TokenKind]::StringLiteral
        [System.Management.Automation.Language.TokenKind]::StringExpandable
        [System.Management.Automation.Language.TokenKind]::HereStringLiteral
        [System.Management.Automation.Language.TokenKind]::HereStringExpandable
        [System.Management.Automation.Language.TokenKind]::Comment
    )
    $shadowExtents = @($tokens | Where-Object { $_.Kind -in $shadowKinds })

    $sourceLines = Get-Content -Path $Path
    for ($i = 0; $i -lt $sourceLines.Count; $i++) {
        $line = $sourceLines[$i]
        $lineNumber = $i + 1
        $trimmed = $line -replace '\s+$', ''
        if (-not $trimmed.EndsWith('`')) {
            continue
        }
        if ($trimmed.EndsWith('``')) {
            continue
        }

        $backtickColumn = $trimmed.Length

        $shadowed = $false
        foreach ($shadow in $shadowExtents) {
            $startLine = $shadow.Extent.StartLineNumber
            $endLine = $shadow.Extent.EndLineNumber
            if ($lineNumber -lt $startLine -or $lineNumber -gt $endLine) {
                continue
            }
            $startCol = if ($lineNumber -eq $startLine) {
                $shadow.Extent.StartColumnNumber
            } else {
                1
            }
            $endCol = if ($lineNumber -eq $endLine) {
                $shadow.Extent.EndColumnNumber
            } else {
                [int]::MaxValue
            }
            if ($backtickColumn -ge $startCol -and $backtickColumn -lt $endCol) {
                $shadowed = $true
                break
            }
        }

        if (-not $shadowed) {
            [pscustomobject]@{
                Path   = $Path
                Line   = $lineNumber
                Column = $backtickColumn
                Text   = $line
            }
        }
    }
}
