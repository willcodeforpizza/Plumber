# PesterIntegration

## Synopsis

Runs integration tests and validates they pass.

## Description

Runs Pester tests from `Tests/Integration` when that directory exists and
fails when any integration test fails.

## Group

CodeQuality

## Configuration

None.

## Run

```powershell
Invoke-Plumber -Task PesterIntegration
```

## Pass

```powershell
It 'returns a value' {
    Get-Thing | Should -Not -BeNullOrEmpty
}
```

## Fail

```powershell
It 'returns a value' {
    Get-Thing | Should -BeNullOrEmpty
}
```

## Navigation

- [Task index](index.md)
- [Group: CodeQuality](CodeQuality.md)
- Previous: [LineLength](LineLength.md)
- Next: [PesterUnit](PesterUnit.md)
