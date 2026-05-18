function Invoke-PlumberJSONSchema {
    <#
        .SYNOPSIS
        Runs the JSONSchema task body.
    #>
    [CmdletBinding()]
    param ()

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
