<#
    .SYNOPSIS
    Validates YAML files.

    .DESCRIPTION
    Finds `.yml` and `.yaml` files under the build root and verifies that each
    file can be parsed from YAML and serialized back to YAML.

    .GROUP
    Content

    .CONFIGURATION
    None.

    .RUN
    ```powershell
    Invoke-Plumber -Task YAML
    ```

    .PASS
    ```yaml
    name: build
    steps:
      - task: validate
    ```

    .FAIL
    ```yaml
    name: build
    steps:
      - task: validate
        invalid
    ```
#>
Add-BuildTask -Name YAML -Jobs {
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
