function ConvertFrom-PlumberTaskHelpComment {
    <#
        .SYNOPSIS
        Parses the help comment from a Plumber task into strucured output.
    #>
    param (
        [Parameter(Mandatory)]
        [string]
        $Text
    )

    $sectionNames = 'SYNOPSIS|DESCRIPTION|GROUP|INCLUDES|CONFIGURATION|RUN|PASS|FAIL'
    $sections = @{}
    $currentSection = $null
    $currentLines = [System.Collections.Generic.List[string]]::new()
    $body = $Text -replace '^\s*<#', '' -replace '#>\s*$', ''

    foreach ($line in ($body -split '\r?\n')) {
        if ($line -match "^\s*\.($sectionNames)\s*$") {
            if ($currentSection) {
                $sections[$currentSection] = ConvertTo-PlumberTaskHelpSection -Lines $currentLines
            }

            $currentSection = $matches[1].ToUpperInvariant()
            $currentLines = [System.Collections.Generic.List[string]]::new()
            continue
        }

        if ($currentSection) {
            $currentLines.Add($line)
        }
    }

    if ($currentSection) {
        $sections[$currentSection] = ConvertTo-PlumberTaskHelpSection -Lines $currentLines
    }

    $sections
}
