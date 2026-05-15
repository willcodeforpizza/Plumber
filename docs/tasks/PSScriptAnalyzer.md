# PSScriptAnalyzer

## Synopsis

Validates PSScriptAnalyzer passes.

## Description

Runs PSScriptAnalyzer against PowerShell files under the build root and
fails when analyzer diagnostics are returned.

## Group

CodeQuality

## Configuration

Set `Tasks.PSScriptAnalyzer.IncludeTests` to control whether files under
`Tests` are analyzed. The default is `$true`.

`Tasks.PSScriptAnalyzer.Exclude` excludes matching files from this task.

PSScriptAnalyzer settings can be supplied at the build root in
`PSScriptAnalyzerSettings.psd1`.

### Example

```powershell
. (Get-PlumberTaskLoader) -Config @{
    ModuleManifest = 'MyModule.psd1'
    Tasks          = @{
        PSScriptAnalyzer = @{
            IncludeTests = $false
            Exclude      = @('Tests/Assets/*.ps1')
        }
    }
}
```

## Run

```powershell
Invoke-Plumber -Task PSScriptAnalyzer
```

## Pass

```powershell
function Get-Thing {
    [CmdletBinding()]
    param ()
}
```

## Fail

```powershell
function get-thing {
}
```

## Navigation

- [Task index](index.md)
- [Group: CodeQuality](CodeQuality.md)
- Previous: [PesterUnit](PesterUnit.md)
