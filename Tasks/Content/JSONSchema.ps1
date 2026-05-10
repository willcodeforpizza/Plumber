<#
    .SYNOPSIS
    Validates JSON files against configured JSON schemas
#>
Add-BuildTask -Name JSONSchema -Jobs {
    if (-not (Get-Command Test-Json -ErrorAction SilentlyContinue)) {
        Write-Error 'Test-Json is required for JSON schema validation'
        return
    }

    if (-not $script:PlumberConfig.JsonSchemas) {
        Write-Build Yellow 'No JSON schema mappings configured'
        return
    }

    foreach ($mapping in $script:PlumberConfig.JsonSchemas) {
        $path = Join-Path $BuildRoot $mapping.Path
        $schema = Join-Path $BuildRoot $mapping.Schema

        if (-not (Test-Path $schema)) {
            Write-Error "JSON schema not found: $schema"
            continue
        }

        $jsonFiles = @(Get-ChildItem $path -File -ErrorAction SilentlyContinue)
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
