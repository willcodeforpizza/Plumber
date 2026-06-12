# CodeCoverage

## Synopsis

Validates the test run's overall code coverage is over the configured minimum.

## Description

Uses the Pester unit test result and fails when the run's overall coverage
percentage is below the configured minimum. When PesterUnit does not
run, CodeCoverage registers as an explicit skip task that explains why,
instead of disappearing from the task graph.

## Group

CodeQuality

## Configuration

`Tasks.CodeCoverage.Minimum` controls the minimum acceptable coverage
percentage. The default is `75`.

### Example

```powershell
. (Get-PlumberTaskLoader) -Config @{
    ModuleManifest = 'MyModule.psd1'
    Tasks          = @{
        CodeCoverage = @{
            Minimum = 85
        }
    }
}
```

## Run

```powershell
Invoke-Plumber -Task CodeCoverage
```

## Pass

```text
Overall coverage is greater than or equal to the configured minimum.
```

## Fail

```text
Overall coverage is lower than the configured minimum.
```

## Navigation

- [Task index](index.md)
- [Group: CodeQuality](CodeQuality.md)
- Previous: [Backticks](Backticks.md)
- Next: [LineLength](LineLength.md)
