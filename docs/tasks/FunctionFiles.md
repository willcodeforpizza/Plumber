# FunctionFiles

## Synopsis

Validates PowerShell function files contain one matching function.

## Description

Checks files under `Public` and `Private` and fails when a PowerShell
function file contains no function, more than one function, cannot be
parsed, or defines a function whose name does not match the file name.

## Group

ModuleConventions

## Configuration

`FunctionFiles.Exclude` excludes repository-relative paths from validation.

### Example

```powershell
. (Get-PlumberTaskLoader) -Config @{
    Tasks = @{
        FunctionFiles = @{
            Exclude = @('Private/Generated/*.ps1')
        }
    }
}
```

## Run

```powershell
Invoke-Plumber -Task FunctionFiles
```

## Pass

```powershell
# Public/Get-Thing.ps1
function Get-Thing {
}
```

## Fail

```powershell
# Private/Helpers.ps1
function Get-Thing {
}

function Set-Thing {
}
```

## Navigation

- [Task index](index.md)
- [Group: ModuleConventions](ModuleConventions.md)
- Next: [Help](Help.md)
