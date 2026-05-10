# CodeCoverage

## Synopsis

Validates code coverage is over the configured minimum for each file tested.

## Description

Uses the Pester unit test result and fails when any covered file reports a
coverage percentage below the configured minimum.

## Group

CodeQuality

## Configuration

`CoverageMinimum` controls the minimum acceptable coverage percentage. The
default is `75`.

### Example

```powershell
. (Get-PlumberTaskLoader) -Config @{
    ModuleManifest  = 'MyModule.psd1'
    CoverageMinimum = 85
}
```

## Run

```powershell
Invoke-Plumber -Task CodeCoverage
```

## Pass

```text
Covered file reports coverage greater than or equal to CoverageMinimum.
```

## Fail

```text
Covered file reports coverage lower than CoverageMinimum.
```
