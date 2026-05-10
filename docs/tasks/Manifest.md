# Manifest

## Synopsis

Validates the module manifest.

## Description

Runs `Test-ModuleManifest` against the configured module manifest.

## Group

ModuleConventions

## Configuration

`ModuleManifest` controls which module manifest is validated.

### Example

```powershell
. (Get-PlumberTaskLoader) -Config @{
    ModuleManifest = 'MyModule.psd1'
}
```

## Run

```powershell
Invoke-Plumber -Task Manifest
```

## Pass

```powershell
Test-ModuleManifest -Path ./MyModule.psd1
```

## Fail

```powershell
Test-ModuleManifest -Path ./Missing.psd1
```
