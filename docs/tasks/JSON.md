# JSON

## Synopsis

Validates JSON files can be parsed.

## Description

Finds `.json` files directly under the `Resource` directory and verifies
that each file can be parsed from JSON and serialized back to JSON.

## Group

Content

## Configuration

`ExcludePaths.JSON` excludes matching files from this task.

### Example

```powershell
. (Get-PlumberTaskLoader) -Config @{
    ModuleManifest = 'MyModule.psd1'
    ExcludePaths   = @{
        JSON = @('Resource/generated.json')
    }
}
```

## Run

```powershell
Invoke-Plumber -Task JSON
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
  "name": "Plumber",
  "enabled": true
```
