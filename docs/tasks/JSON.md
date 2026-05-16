# JSON

## Synopsis

Validates JSON files can be parsed.

## Description

Finds `.json` files under the build root and verifies that each file can be
parsed from JSON and serialized back to JSON.

## Group

Content

## Configuration

`Tasks.JSON.Exclude` excludes matching files from this task.

### Example

```powershell
. (Get-PlumberTaskLoader) -Config @{
    ModuleManifest = 'MyModule.psd1'
    Tasks          = @{
        JSON = @{
            Exclude = @('Resource/generated.json')
        }
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

## Navigation

- [Task index](index.md)
- [Group: Content](Content.md)
- Next: [JSONSchema](JSONSchema.md)
