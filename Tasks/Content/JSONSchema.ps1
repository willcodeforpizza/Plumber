<#
    .SYNOPSIS
    Validates JSON files against configured JSON schemas.

    .DESCRIPTION
    Uses configured JSON schema mappings to validate matching `.json` files
    with `Test-Json`.

    .GROUP
    Content

    .CONFIGURATION
    `JsonSchemas` defines the JSON files and schema files to validate. Each
    mapping has a `Path` value for matching JSON files and a `Schema` value for
    the schema file.

    `ExcludePaths.JSONSchema` excludes matching files from this task.

    ### Example

    ```powershell
    . (Get-PlumberTaskLoader) -Config @{
        ModuleManifest = 'MyModule.psd1'
        JsonSchemas    = @(
            @{
                Path   = 'Resource/*.json'
                Schema = 'Resource/Schema/config.schema.json'
            }
        )
        ExcludePaths   = @{
            JSONSchema = @('Resource/generated.json')
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
    # Scope can be lost when running Plumber on Plumber multiple times
    if (-not (Get-Command Get-PlumberTaskFile -ErrorAction SilentlyContinue)) {
        . (Join-Path $script:PlumberConfig.ModuleRoot 'Private/Test-PlumberTaskPathExcluded.ps1')
        . (Join-Path $script:PlumberConfig.ModuleRoot 'Private/Get-PlumberTaskFile.ps1')
    }

    if (-not (Get-Command Test-Json -ErrorAction SilentlyContinue)) {
        Write-Error 'Test-Json is required for JSON schema validation'
        return
    }

    if (-not $script:PlumberConfig.JsonSchemas) {
        Write-Build Yellow 'No JSON schema mappings configured'
        return
    }

    foreach ($mapping in $script:PlumberConfig.JsonSchemas) {
        $jsonPath = Split-Path $mapping.Path -Parent
        $jsonFilter = Split-Path $mapping.Path -Leaf
        if (-not $jsonPath) {
            $jsonPath = '.'
        }
        $jsonRoot = Join-Path $BuildRoot $jsonPath

        $schema = Join-Path $BuildRoot $mapping.Schema

        if (-not (Test-Path $schema)) {
            Write-Error "JSON schema not found: $schema"
            continue
        }

        $jsonFiles = @(
            Get-PlumberTaskFile -Task JSONSchema -Extension '.json' -Path $jsonPath |
                Where-Object {
                    $_.Name -like $jsonFilter -and
                    $_.DirectoryName.Equals(
                        $jsonRoot,
                        [System.StringComparison]::OrdinalIgnoreCase
                    )
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
