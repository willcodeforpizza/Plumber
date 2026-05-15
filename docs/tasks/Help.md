# Help

## Synopsis

Validates public and private function help.

## Description

Validates comment-based help on functions in `Public` and `Private`.
Public functions require a synopsis, description, example and parameter help. Private functions
require synopsis-only help unless configured otherwise.

## Group

ModuleConventions

## Configuration

`Tasks.Help.PrivateSynopsisOnly` controls whether private functions require
only a synopsis or full help. The default is `$true`.

### Example

```powershell
. (Get-PlumberTaskLoader) -Config @{
    ModuleManifest = 'MyModule.psd1'
    Tasks          = @{
        Help = @{
            PrivateSynopsisOnly = $false
        }
    }
}
```

## Run

```powershell
Invoke-Plumber -Task Help
```

## Pass

```text
Public/Get-Thing.ps1 contains comment-based help with a SYNOPSIS section.
```

## Fail

```text
Public/Get-Thing.ps1 contains a function with no comment-based help.
```

## Navigation

- [Task index](index.md)
- [Group: ModuleConventions](ModuleConventions.md)
- Next: [Manifest](Manifest.md)
