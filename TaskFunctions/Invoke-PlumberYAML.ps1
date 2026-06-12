function Invoke-PlumberYAML {
    <#
        .SYNOPSIS
        Runs the YAML task body.
    #>
    [CmdletBinding()]
    param ()

    $convertFromYaml = Get-Command ConvertFrom-Yaml -ErrorAction SilentlyContinue
    $convertToYaml = Get-Command ConvertTo-Yaml -ErrorAction SilentlyContinue

    if (-not $convertFromYaml -or -not $convertToYaml) {
        throw 'ConvertFrom-Yaml and ConvertTo-Yaml are required. Install the powershell-yaml module.'
    }

    $yamlFiles = Get-PlumberTaskFile -Task YAML -Extension '.yml', '.yaml'
    if (-not $yamlFiles) {
        Write-Build Yellow 'No YAML files found'
        return
    }

    $failures = [System.Collections.Generic.List[string]]::new()
    foreach ($yamlFile in $yamlFiles) {
        try {
            Get-Content $yamlFile.FullName -Raw -ErrorAction Stop |
                ConvertFrom-Yaml -ErrorAction Stop |
                ConvertTo-Yaml -ErrorAction Stop | Out-Null
        }
        catch {
            # Write-Error per file would terminate the loop under
            # Invoke-Build's ErrorActionPreference Stop; collect instead.
            $failures.Add("Invalid YAML in $($yamlFile.FullName): $($_.Exception.Message)")
        }
    }

    if ($failures) {
        Write-Error ($failures -join (', ' + [Environment]::NewLine))
    }
}
