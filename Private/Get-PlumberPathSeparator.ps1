function Get-PlumberPathSeparator {
    <#
        .SYNOPSIS
        Finds Windows-style path separators in PowerShell string literals.

        .DESCRIPTION
        Parses a PowerShell file, walks the AST for every string constant and
        expandable string, and returns each literal that contains a backslash
        used as a path separator.

        The detection has three layers of false-positive suppression:

        - Backslash sequences that look like regex escapes (\d, \s, \\, \.,
          etc.) are not flagged by the path-like regex itself.
        - Strings whose ancestor in the AST is a binary regex operator
          (-match, -replace, -split family) are skipped, including strings
          that sit inside array literals or parenthesised expressions
          between the string and the operator.
        - Strings assigned to a variable whose name contains pattern, regex,
          re, or match (case-insensitive) are skipped.
        - Strings whose content starts with (? are skipped (regex prefix
          shape).

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
    #   (a) a character that is neither a regex/escape special nor `$` - catches
    #       \T, \Public, etc.
    #   (b) a regex-letter (d s w b n r t f v 0 and uppercase variants) followed
    #       by another word character - catches \Tests, \two where the leading
    #       letter happens to be a regex-escape letter but the rest of the word
    #       makes it clearly a path component.
    #   (c) `\$` followed by `[A-Za-z_]` - catches `\$variable` paths like
    #       "$BuildRoot\$script:moduleName.psm1" without matching regex `\${`,
    #       `\$\d`, `\$(`, etc.
    #
    # Skip set covers commonly-used regex escapes: character classes (\d \s
    # \w \b and uppercase variants), control characters (\n \r \t \f \v \0),
    # metachar escapes (\. \\ \| \+ \* \? \( \) \[ \] \{ \} \/), and the
    # end-of-string anchor (\$). Rare regex escapes (\A \Z \z \G \p \P \k \K
    # \^) are deliberately omitted.
    $pathLikeBackslash =
        '\\(?:[^dDsSwWbBnrtfv0.\\|+*?()\[\]{}/$]|[dDsSwWbBnrtfv0]\w|\$[A-Za-z_])'

    # Variable-name conventions that indicate the string is a regex pattern.
    $regexVariableNames = 'pattern|regex|matcher|matchpattern|^re$|^re\d'

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

        # Strings that start with (? are regex (case-insensitive flags, named
        # groups, non-capturing groups, etc.).
        if ($stringValue.StartsWith('(?')) {
            continue
        }

        # Walk up the parent chain looking for a regex operator. Strings inside
        # array literals, paren expressions, or unary expressions between the
        # string and the operator are still in regex context. Cap the walk at
        # a few levels so we don't accidentally treat a deeply-nested literal
        # as regex.
        $inRegexContext = $false
        $ancestor = $stringNode.Parent
        for ($depth = 0; $depth -lt 4 -and $null -ne $ancestor; $depth++) {
            if (
                $ancestor -is [System.Management.Automation.Language.BinaryExpressionAst] -and
                $ancestor.Operator -in $regexOperators
            ) {
                $inRegexContext = $true
                break
            }
            # Stop walking up once we hit a statement or command boundary - the
            # string isn't going to feed a regex operator from inside one of
            # those.
            if (
                $ancestor -is [System.Management.Automation.Language.StatementAst] -or
                $ancestor -is [System.Management.Automation.Language.CommandAst]
            ) {
                break
            }
            $ancestor = $ancestor.Parent
        }
        if ($inRegexContext) {
            continue
        }

        # Strings assigned to a variable whose name suggests it holds a regex
        # are skipped. The variable might be used as a -match operand later
        # without us being able to trace it via AST walking.
        $parent = $stringNode.Parent
        if (
            $parent -is [System.Management.Automation.Language.AssignmentStatementAst] -and
            $parent.Left -is [System.Management.Automation.Language.VariableExpressionAst]
        ) {
            $variableName = $parent.Left.VariablePath.UserPath
            if ($variableName -match $regexVariableNames) {
                continue
            }
        }

        [pscustomobject]@{
            Path   = $Path
            Line   = $stringNode.Extent.StartLineNumber
            Column = $stringNode.Extent.StartColumnNumber
            Text   = $stringNode.Extent.Text
        }
    }
}
