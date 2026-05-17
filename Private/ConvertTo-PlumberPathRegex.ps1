function ConvertTo-PlumberPathRegex {
    <#
        .SYNOPSIS
        Converts a path glob pattern to a regex.

        .DESCRIPTION
        Translates the glob shapes Plumber accepts in `Tasks.JSONSchema.Schemas[].Path`
        into a regex anchored to the start and end of a normalized relative path:

        - `**/`  matches zero or more directory segments
        - `**`   matches any sequence of characters including slashes
        - `*`    matches any sequence except a slash
        - `?`    matches a single character except a slash

        All other regex metacharacters in the pattern are escaped.

        .PARAMETER Pattern
        The glob pattern. Backslashes are normalised to forward slashes.

        .EXAMPLE
        ConvertTo-PlumberPathRegex -Pattern 'Resource/*.json'

        Returns `^Resource/[^/]*\.json$`.

        .EXAMPLE
        'Resource/foo.json' -match (ConvertTo-PlumberPathRegex -Pattern '**/*.json')

        Returns $true.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory)]
        [string]
        $Pattern
    )

    $normalized = $Pattern.Replace('\', '/')
    $regex = [regex]::Escape($normalized).
        Replace('\*\*/', '(?:.*/)?').
        Replace('\*\*', '.*').
        Replace('\*', '[^/]*').
        Replace('\?', '[^/]')
    "^$regex$"
}
