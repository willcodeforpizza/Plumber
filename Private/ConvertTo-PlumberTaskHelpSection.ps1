function ConvertTo-PlumberTaskHelpSection {
    <#
        .SYNOPSIS
        Normalizes indentation in a Plumber task help section.
    #>
    param (
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string[]]
        $Lines
    )

    $values = @($Lines)
    while ($values.Count -gt 0 -and -not $values[0].Trim()) {
        $values = @($values | Select-Object -Skip 1)
    }
    while ($values.Count -gt 0 -and -not $values[-1].Trim()) {
        $values = @($values | Select-Object -First ($values.Count - 1))
    }
    if (-not $values) {
        return $null
    }

    $indents = @(
        foreach ($value in $values) {
            if ($value.Trim()) {
                ([regex]::Match($value, '^\s*')).Value.Length
            }
        }
    )
    $indent = if ($indents) {
        ($indents | Measure-Object -Minimum).Minimum
    } else {
        0
    }

    @(
        foreach ($value in $values) {
            if ($value.Length -ge $indent) {
                $value.Substring($indent)
            } else {
                $value
            }
        }
    ) -join "`n"
}
