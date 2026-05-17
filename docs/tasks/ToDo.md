# ToDo

## Synopsis

Validates no TODO comments are left in files.

## Description

Checks `.ps1`, `.psm1`, and `.psd1` files and fails when a line comment
contains a TODO marker. Detection is AST-aware so TODO text inside string
literals or block comments is not flagged. Both leading-line TODOs
(`# TODO: fix this`) and inline TODOs after code on the same line
(`$x = 1 # TODO: fix this`) are reported.

## Group

ModuleConventions

## Configuration

`Tasks.ToDo.Exclude` excludes matching files from this task.

### Example

```powershell
. (Get-PlumberTaskLoader) -Config @{
    ModuleManifest = 'MyModule.psd1'
    Tasks          = @{
        ToDo = @{
            Exclude = @('docs/examples/*.ps1')
        }
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
A line comment contains the TODO marker.
```

## Navigation

- [Task index](index.md)
- [Group: ModuleConventions](ModuleConventions.md)
- Previous: [PublicFunctions](PublicFunctions.md)
