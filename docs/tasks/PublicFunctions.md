# PublicFunctions

## Synopsis

Validates all public functions are declared in the PSD1.

## Description

Checks files under `Public` and fails when a public function file name is
not listed in the manifest `FunctionsToExport` value.

## Group

ModuleConventions

## Configuration

`ModuleManifest` controls which module manifest supplies
`FunctionsToExport`.

### Example

```powershell
. (Get-PlumberTaskLoader) -Config @{
    ModuleManifest = 'MyModule.psd1'
}
```

## Run

```powershell
Invoke-Plumber -Task PublicFunctions
```

## Pass

```powershell
FunctionsToExport = @('Get-Thing')
```

## Fail

```powershell
FunctionsToExport = @()
```

## Navigation

- [Task index](index.md)
- [Group: ModuleConventions](ModuleConventions.md)
- Previous: [Naming](Naming.md)
- Next: [ToDo](ToDo.md)
