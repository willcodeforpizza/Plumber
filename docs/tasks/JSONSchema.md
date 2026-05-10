# JSONSchema

## Synopsis

Validates JSON files against configured JSON schemas.

## Description

Uses configured JSON schema mappings to validate matching `.json` files
under the build root with `Test-Json`.

## Group

Content

## Configuration

`JsonSchemas` defines the JSON files and schema files to validate. Each
mapping has a repository-relative `Path` pattern for matching JSON files
and a `Schema` value for the schema file.

Use `**/*.json` to match JSON files recursively.

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
        JSONSchema = @('Resource/Schema/*.json')
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

## Navigation

- [Task index](index.md)
- [Group: Content](Content.md)
- Previous: [JSON](JSON.md)
- Next: [YAML](YAML.md)
