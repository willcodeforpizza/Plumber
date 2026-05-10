# Backticks

## Synopsis

Validates PowerShell files do not use line-continuation backticks.

## Description

Checks `.ps1`, `.psm1`, and `.psd1` files and fails when a backtick is used
as the final non-whitespace character on a line.

## Group

CodeQuality

## Configuration

`ExcludePaths.Backticks` excludes matching files from this task.

### Example

```powershell
. (Get-PlumberTaskLoader) -Config @{
    ModuleManifest = 'MyModule.psd1'
    ExcludePaths   = @{
        Backticks = @('Tests/Assets/TaskHelp/*.ps1')
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
A PowerShell line whose final non-whitespace character is a backtick.
```

## Navigation

- [Task index](index.md)
- [Group: CodeQuality](CodeQuality.md)
- Next: [CodeCoverage](CodeCoverage.md)
