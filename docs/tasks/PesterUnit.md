# PesterUnit

## Synopsis

Runs unit tests and validates they pass.

## Description

Runs Pester tests from `Tests/Unit`, captures code coverage for module
source folders, and fails when any unit test fails.

## Group

CodeQuality

## Configuration

None.

## Run

```powershell
Invoke-Plumber -Task PesterUnit
```

## Pass

```powershell
It 'returns the expected value' {
    Get-Thing | Should -Be 'value'
}
```

## Fail

```powershell
It 'returns the expected value' {
    Get-Thing | Should -Be 'other'
}
```
