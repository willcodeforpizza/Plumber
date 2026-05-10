# ToDo

## Synopsis

Validates no TODO comments are left in files.

## Description

Checks files under the build root and fails when a code comment begins with
`TODO`.

## Group

ModuleConventions

## Configuration

`ExcludePaths.ToDo` excludes matching files from this task.

### Example

```powershell
. (Get-PlumberTaskLoader) -Config @{
    ModuleManifest = 'MyModule.psd1'
    ExcludePaths   = @{
        ToDo = @('docs/examples/*.ps1')
    }
}
```

## Run

```powershell
Invoke-Plumber -Task ToDo
```

## Pass

```powershell
# Documents why the next command exists.
```

## Fail

```text
A code comment begins with the TODO marker.
```

## Navigation

- [Task index](index.md)
- [Group: ModuleConventions](ModuleConventions.md)
- Previous: [PublicFunctions](PublicFunctions.md)
