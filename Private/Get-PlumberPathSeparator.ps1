function Get-PlumberPathSeparator {
    <#
        .SYNOPSIS
        Finds Windows-style path separators in PowerShell string literals.

        .DESCRIPTION
        Parses a PowerShell file, walks the AST for every string constant and
        expandable string, and returns each literal that contains a backslash
        used as a path separator. Strings used as operands of regex operators
        (-match, -replace, -split family) are skipped, as are backslash
        sequences that look like regex escapes (\d, \s, \\, \., etc.).

        .PARAMETER Path
        The PowerShell file to inspect.

        .EXAMPLE
        Get-PlumberPathSeparator -Path ./Tasks/CodeQuality/PesterUnit.ps1

        Returns one record per offending literal, with line, column, and the
        raw source text of the literal.
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
    $ast = [System.Management.Automation.Language.Parser]::ParseFile(
        $Path,
        [ref] $tokens,
        [ref] $parseErrors
    )
    if ($parseErrors) {
        throw "Failed to parse $Path"
    }

    $regexOperators = @(
        [System.Management.Automation.Language.TokenKind]::Imatch
        [System.Management.Automation.Language.TokenKind]::Inotmatch
        [System.Management.Automation.Language.TokenKind]::Cmatch
        [System.Management.Automation.Language.TokenKind]::Cnotmatch
        [System.Management.Automation.Language.TokenKind]::Ireplace
        [System.Management.Automation.Language.TokenKind]::Creplace
        [System.Management.Automation.Language.TokenKind]::Isplit
        [System.Management.Automation.Language.TokenKind]::Csplit
    )

    # Backslash followed by either:
    #   (a) a character that is not a regex/escape special, or
    #   (b) a regex-letter that is followed by another word character - meaning
    #       it's part of a longer identifier, not a one-character regex escape.
    # The first branch catches \T, \Public, \$variable, etc. The second branch
    # catches \Tests, \two, \sources where the leading letter happens to be a
    # regex-escape letter but the rest of the word makes it clearly a path
    # component. The regex-context check below handles strings actually used
    # as regex (where \two might legitimately be tab + 'wo').
    #
    # Skip set covers commonly-used regex escapes: character classes (\d \s
    # \w \b and uppercase variants), control characters (\n \r \t \f \v \0),
    # and metachar escapes (\. \\ \| \+ \* \? \( \) \[ \] \{ \} \/). Rare
    # regex escapes (\A \Z \z \G \p \P \k \K \^ \$) are deliberately omitted.
    $pathLikeBackslash = '\\(?:[^dDsSwWbBnrtfv0.\\|+*?()\[\]{}/]|[dDsSwWbBnrtfv0]\w)'

    $stringPredicate = {
        param ($node)
        $node -is [System.Management.Automation.Language.StringConstantExpressionAst] -or
        $node -is [System.Management.Automation.Language.ExpandableStringExpressionAst]
    }
    $stringNodes = $ast.FindAll($stringPredicate, $true)

    foreach ($stringNode in $stringNodes) {
        $stringValue = $stringNode.Value
        if ($stringValue -notmatch $pathLikeBackslash) {
            continue
        }

        $parent = $stringNode.Parent
        $inRegexContext = (
            $parent -is [System.Management.Automation.Language.BinaryExpressionAst] -and
            $parent.Operator -in $regexOperators
        )
        if ($inRegexContext) {
            continue
        }

        [pscustomobject]@{
            Path   = $Path
            Line   = $stringNode.Extent.StartLineNumber
            Column = $stringNode.Extent.StartColumnNumber
            Text   = $stringNode.Extent.Text
        }
    }
}
