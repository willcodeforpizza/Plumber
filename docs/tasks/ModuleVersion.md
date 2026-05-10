# ModuleVersion

## Synopsis

Validates current PSD1 version is higher than current PSGallery version.

## Description

Looks up the module on PSGallery and fails when the configured manifest
version is not greater than the published version.

## Group

ReleaseHygiene

## Configuration

`ModuleManifest` controls which module manifest supplies the module name
and `ModuleVersion`.

### Example

```powershell
. (Get-PlumberTaskLoader) -Config @{
    ModuleManifest = 'MyModule.psd1'
}
```

## Run

```powershell
Invoke-Plumber -Task ModuleVersion
```

## Pass

```powershell
ModuleVersion = '1.2.3'
```

## Fail

```powershell
ModuleVersion = '1.2.2'
```
