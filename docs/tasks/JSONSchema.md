# JSONSchema

## Synopsis

Validates JSON files against configured JSON schemas.

## Description

Uses configured JSON schema mappings to validate matching `.json` files
with `Test-Json`.

## Group

Content

## Configuration

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

## Run

```powershell
Invoke-Plumber -Task JSONSchema
```

## Pass

```json
{
  "name": "Plumber",
  "enabled": true
}
```

## Fail

```json
{
  "enabled": true
}
```
