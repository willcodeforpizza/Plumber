# PathSeparator

## Synopsis

Validates string literals do not contain Windows-style path separators.

## Description

Parses `.ps1`, `.psm1`, and `.psd1` files and fails when a string literal
contains a backslash used as a path separator. Strings that are operands
of regex operators (`-match`, `-replace`, `-split` family) and backslash
sequences that look like regex escapes (`\d`, `\s`, `\\`, `\.`, etc.) are
not flagged. Use `Join-Path` or `[IO.Path]::Combine` for cross-platform
paths.

## Group

CodeQuality

## Configuration

`Tasks.PathSeparator.Exclude` excludes matching files from this task.

### Example

```powershell
. (Get-PlumberTaskLoader) -Config @{
    ModuleManifest = 'MyModule.psd1'
    Tasks          = @{
        PathSeparator = @{
            Exclude = @('Tests/Assets/WindowsOnly.ps1')
        }
    }
}
```

## Run

```powershell
Invoke-Plumber -Task PathSeparator
```

## Pass

```powershell
$configPath = Join-Path $BuildRoot 'config.json'
```

## Fail

```text
A string literal contains a backslash path separator, for example
"$BuildRoot\config.json".
```

## Navigation

- [Task index](index.md)
- [Group: CodeQuality](CodeQuality.md)
- Previous: [LineLength](LineLength.md)
- Next: [PesterIntegration](PesterIntegration.md)
