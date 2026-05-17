# Backticks

## Synopsis

Validates PowerShell files do not use line-continuation backticks.

## Description

Checks `.ps1`, `.psm1`, and `.psd1` files and fails when a backtick is used
as a line continuation. Detection is AST-aware: backticks inside strings,
here-strings, and comments are not flagged, and a trailing pair of backticks
(a literal escaped backtick) is treated as intentional source rather than a
continuation.

## Group

CodeQuality

## Configuration

`Tasks.Backticks.Exclude` excludes matching files from this task.

### Example

```powershell
. (Get-PlumberTaskLoader) -Config @{
    ModuleManifest = 'MyModule.psd1'
    Tasks          = @{
        Backticks = @{
            Exclude = @('Tests/Assets/TaskHelp/*.ps1')
        }
    }
}
```

## Run

```powershell
Invoke-Plumber -Task Backticks
```

## Pass

```powershell
Get-Foo -DoBar -AddFizz
```

## Fail

```text
A PowerShell line whose final non-whitespace character is a backtick
used as a line continuation.
```

## Navigation

- [Task index](index.md)
- [Group: CodeQuality](CodeQuality.md)
- Next: [CodeCoverage](CodeCoverage.md)
