# ModuleVersion

## Synopsis

Validates current PSD1 version is merge-ready.

## Description

Looks up the latest published module version from PSGallery or git tags.
Fails when the configured manifest version is not greater than the
published version because a mergeable change must advance the next
publishable module version.

## Group

ReleaseHygiene

## Configuration

ModuleManifest controls which module manifest supplies the module name
and ModuleVersion.

Tasks.ModuleVersion.Source controls where the published version is read
from. Supported values are PSGallery and GitTag. PSGallery is the default.

Tasks.ModuleVersion.Remote controls which git remote supplies tags for
GitTag checks. The default is origin.

Tasks.ModuleVersion.IncludePrerelease controls whether prerelease git tags
are included. The default is false.

### Example

```powershell
. (Get-PlumberTaskLoader) -Config @{
    ModuleManifest = 'MyModule.psd1'
    Tasks          = @{
        ModuleVersion = @{
            Source = 'GitTag'
            Remote = 'origin'
        }
    }
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
