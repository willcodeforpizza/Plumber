# LineLength

## Synopsis

Validates PowerShell source files do not exceed the configured line length.

## Description

Checks `.ps1`, `.psm1`, and `.psd1` files under the build root and fails
when a line is longer than the configured maximum.

## Group

CodeQuality

## Configuration

`Tasks.LineLength.MaxLength` controls the maximum allowed line length. The
default is `115`.

`Tasks.LineLength.Exclude` excludes matching files from this task.

### Example

```powershell
. (Get-PlumberTaskLoader) -Config @{
    ModuleManifest = 'MyModule.psd1'
    Tasks          = @{
        LineLength = @{
            MaxLength = 80
            Exclude   = @('Tests/Assets/LongLines.ps1')
        }
    }
}
```

## Run

```powershell
Invoke-Plumber -Task LineLength
```

## Pass

```powershell
$name = 'LineLength'
"Task: $name"
```

## Fail

```powershell
$line = '<more than configured maximum characters on one physical line>'
```

## Navigation

- [Task index](index.md)
- [Group: CodeQuality](CodeQuality.md)
- Previous: [CodeCoverage](CodeCoverage.md)
- Next: [PathSeparator](PathSeparator.md)
