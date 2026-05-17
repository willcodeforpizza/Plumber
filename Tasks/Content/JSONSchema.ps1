<#
    .SYNOPSIS
    Validates JSON files against configured JSON schemas.

    .DESCRIPTION
    Uses configured JSON schema mappings to validate matching `.json` files
    under the build root with `Test-Json`.

    .GROUP
    Content

    .CONFIGURATION
    `Tasks.JSONSchema.Schemas` defines the JSON files and schema files to
    validate. Each mapping has a repository-relative `Path` pattern for matching
    JSON files and a `Schema` value for the schema file.

    Use `**/*.json` to match JSON files recursively.

    `Tasks.JSONSchema.Exclude` excludes matching files from this task.

    ### Example

    ```powershell
    . (Get-PlumberTaskLoader) -Config @{
        ModuleManifest = 'MyModule.psd1'
        Tasks          = @{
            JSONSchema = @{
                Schemas = @(
                    @{
                        Path   = 'Resource/*.json'
                        Schema = 'Resource/Schema/config.schema.json'
                    }
                )
                Exclude = @('Resource/Schema/*.json')
            }
        }
    }
    ```

    .RUN
    ```powershell
    Invoke-Plumber -Task JSONSchema
    ```

    .PASS
    ```json
    {
      "name": "Plumber",
      "enabled": true
    }
    ```

    .FAIL
    ```json
    {
      "enabled": true
    }
    ```
#>
Add-BuildTask -Name JSONSchema -Jobs {
    if (-not (Get-Command Test-Json -ErrorAction SilentlyContinue)) {
        Write-Error 'Test-Json is required for JSON schema validation'
        return
    }

    if (-not $script:PlumberConfig.Tasks.JSONSchema.Schemas) {
        Write-Build Yellow 'No JSON schema mappings configured'
        return
    }

    foreach ($mapping in $script:PlumberConfig.Tasks.JSONSchema.Schemas) {
        $schema = Join-Path $BuildRoot $mapping.Schema

        if (-not (Test-Path $schema)) {
            Write-Error "JSON schema not found: $schema"
            continue
        }

        $pathRegex = ConvertTo-PlumberPathRegex -Pattern $mapping.Path

        $jsonFiles = @(
            Get-PlumberTaskFile -Task JSONSchema -Extension '.json' |
                Where-Object {
                    $relativePath = [System.IO.Path]::GetRelativePath($BuildRoot, $_.FullName)
                    $relativePath.Replace('\', '/') -match $pathRegex
                }
        )
        if (-not $jsonFiles) {
            Write-Build Yellow "No JSON files matched schema path: $($mapping.Path)"
            continue
        }

        foreach ($jsonFile in $jsonFiles) {
            $valid = Test-Json -Path $jsonFile.FullName -SchemaFile $schema -ErrorAction Stop
            if (-not $valid) {
                Write-Error "JSON schema validation failed: $($jsonFile.FullName)"
            }
        }
    }
}
