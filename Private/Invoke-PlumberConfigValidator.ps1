function Invoke-PlumberConfigValidator {
    <#
        .SYNOPSIS
        Runs a named Plumber config value validator.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory)]
        [AllowNull()]
        $Value,

        [Parameter(Mandatory)]
        [hashtable]
        $Rule
    )

    if ($null -eq $Value) {
        if ($Rule.Nullable) {
            return
        }

        return 'Expected value, got null'
    }

    switch ($Rule.Validate) {
        'boolean' {
            if ($Value -isnot [bool]) {
                return "Expected boolean, got $($Value.GetType().Name)"
            }
        }
        'integer' {
            if ($Value -isnot [int]) {
                return "Expected integer, got $($Value.GetType().Name)"
            }
            if ($Rule.ContainsKey('Min') -and $Value -lt $Rule.Min) {
                return "Expected at least $($Rule.Min), got $Value"
            }
            if ($Rule.ContainsKey('Max') -and $Value -gt $Rule.Max) {
                return "Expected at most $($Rule.Max), got $Value"
            }
        }
        'object-array' {
            if ($Value -isnot [System.Collections.IList] -or $Value -is [string]) {
                return "Expected array, got $($Value.GetType().Name)"
            }

            if ($Rule.ItemRule) {
                for ($index = 0; $index -lt $Value.Count; $index++) {
                    $item = $Value[$index]
                    if ($item -isnot [hashtable]) {
                        return "Expected item $index to be hashtable, got $($item.GetType().Name)"
                    }

                    foreach ($key in $Rule.ItemRule.Keys) {
                        if (-not $item.ContainsKey($key)) {
                            return "Expected item $index to include $key"
                        }

                        $message = Invoke-PlumberConfigValidator -Value $item[$key] -Rule $Rule.ItemRule[$key]
                        if ($message) {
                            return "Item $index.$key`: $message"
                        }
                    }
                }
            }
        }
        'string' {
            if ($Value -isnot [string]) {
                return "Expected string, got $($Value.GetType().Name)"
            }
        }
        'string-array' {
            if ($Value -isnot [System.Collections.IList] -or $Value -is [string]) {
                return "Expected string array, got $($Value.GetType().Name)"
            }
            foreach ($item in $Value) {
                if ($item -isnot [string]) {
                    return "Expected string array, got item of type $($item.GetType().Name)"
                }
            }
        }
        'enum' {
            if ($Value -notin $Rule.Values) {
                return "Expected one of '$($Rule.Values -join "', '")', got '$Value'"
            }
        }
    }
}
