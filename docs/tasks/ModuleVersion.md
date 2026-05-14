# ModuleVersion

## Synopsis

Validates current PSD1 version is higher than the published version.

## Description

Looks up the latest published module version from PSGallery or git tags
and fails when the configured manifest version is not greater than the
published version.

## Group

ReleaseHygiene

## Configuration

`ModuleManifest` controls which module manifest supplies the module name
and `ModuleVersion`.

`VersionSource` controls where the published version is read from. Supported
values are `PSGallery` and `GitTag`. `PSGallery` is the default.

`VersionRemote` controls which git remote supplies tags for `GitTag` checks.
The default is `origin`.

`VersionIncludePrerelease` controls whether prerelease git tags are included.
The default is `$false`.

### Example

```powershell
. (Get-PlumberTaskLoader) -Config @{
    ModuleManifest = 'MyModule.psd1'
    VersionSource = 'GitTag'
    VersionRemote = 'origin'
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

## Navigation

- [Task index](index.md)
- [Group: ReleaseHygiene](ReleaseHygiene.md)
- Previous: [ChangelogUpdated](ChangelogUpdated.md)
