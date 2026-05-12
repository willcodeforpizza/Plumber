# Naming

## Synopsis

Validates the RootModule name matches the module file name on disk.

## Description

Checks that the configured manifest `RootModule` value uses the same casing
as the module `.psm1` file on disk.

## Group

ModuleConventions

## Configuration

`ModuleManifest` controls which module manifest supplies `RootModule`.

### Example

```powershell
. (Get-PlumberTaskLoader) -Config @{
    ModuleManifest = 'MyModule.psd1'
}
```

## Run

```powershell
Invoke-Plumber -Task Naming
```

## Pass

```powershell
RootModule = 'MyModule.psm1'
```

## Fail

```powershell
RootModule = 'mymodule.psm1'
```

## Navigation

- [Task index](index.md)
- [Group: ModuleConventions](ModuleConventions.md)
- Previous: [Manifest](Manifest.md)
- Next: [PublicFunctionPrefix](PublicFunctionPrefix.md)
