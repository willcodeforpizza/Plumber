# CodeQuality

## Synopsis

Runs code quality validation.

## Description

Runs validation tasks that check script analysis, style rules, tests, and
coverage.

## Includes

- `PSScriptAnalyzer`
- `Backticks`
- `LineLength`
- `PesterUnit`
- `PesterIntegration`
- `CodeCoverage`

## Run

```powershell
Invoke-Plumber -Task CodeQuality
```
