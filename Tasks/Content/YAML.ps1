<#
    .SYNOPSIS
    Validates YAML files can be parsed
#>
Add-BuildTask -Name YAML -Jobs {
    $convertFromYaml = Get-Command ConvertFrom-Yaml -ErrorAction SilentlyContinue
    $convertToYaml = Get-Command ConvertTo-Yaml -ErrorAction SilentlyContinue

    if (-not $convertFromYaml -or -not $convertToYaml) {
        Write-Build Yellow 'ConvertFrom-Yaml and ConvertTo-Yaml are not available'
        return
    }

    $yamlFiles = Get-ChildItem $BuildRoot -File -Include '*.yml', '*.yaml' -Recurse -ErrorAction SilentlyContinue
    if (-not $yamlFiles) {
        Write-Build Yellow 'No YAML files found'
        return
    }

    foreach ($yamlFile in $yamlFiles) {
        try {
            Get-Content $yamlFile.FullName -Raw -ErrorAction Stop |
                ConvertFrom-Yaml -ErrorAction Stop |
                ConvertTo-Yaml -ErrorAction Stop | Out-Null
        }
        catch {
            Write-Error "Invalid YAML in $($yamlFile.FullName): $($_.Exception.Message)"
        }
    }
}
