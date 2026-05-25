# Invoke-Plumber JSON output contract

`Invoke-Plumber -OutputMode Json -NoFormat` is the supported automation contract for tools that need structured Plumber results.

## Contract

The command writes exactly one parseable JSON object to stdout. The object conforms to [`schemas/invoke-plumber-result.schema.json`](schemas/invoke-plumber-result.schema.json). Consumers should keep stdout, stderr, and the PowerShell error stream separate and parse only stdout as JSON.

Core fields are stable:

- `Success` (`boolean`): `true` when all reported tasks passed.
- `Passed` (`integer`, minimum `0`): count of reported passed tasks.
- `Failed` (`integer`, minimum `0`): count of reported failed tasks.
- `Tasks` (`array`): reported task result objects.
- `Failures` (`array`): failed task result objects from `Tasks`.

Task result objects include:

- `Name` (`string`): task name.
- `Status` (`Passed` or `Failed`): task status.
- `Error` (`string` or `null`, optional): diagnostic text for failed tasks.

The schema allows additional properties for future-compatible automation. Callers should ignore unknown fields.

## Failure behavior

When validation fails, `Invoke-Plumber -OutputMode Json -NoFormat` writes the JSON result to stdout first, then raises the existing terminating `Build failed!` error. In command-line execution this produces a non-zero process exit after stdout has already received the JSON object.

Diagnostics from the terminating error are for stderr/error handling only. They are not part of the JSON contract. Do not parse merged streams such as `*>&1`; keep streams separate and parse stdout.

Example pattern:

```powershell
$stdout = Join-Path $PWD 'plumber.json'
$stderr = Join-Path $PWD 'plumber.err'

pwsh -NoProfile -Command 'Invoke-Plumber -OutputMode Json -NoFormat' 1> $stdout 2> $stderr
$exitCode = $LASTEXITCODE
$result = Get-Content -Raw $stdout | ConvertFrom-Json

if (-not $result.Success -or $exitCode -ne 0) {
    # Inspect $result.Failures for machine-readable failure details.
    # Inspect $stderr only for human diagnostic context.
}
```
