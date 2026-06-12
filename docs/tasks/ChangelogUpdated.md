# ChangelogUpdated

## Synopsis

Validates the changelog has been updated.

## Description

Compares the latest version heading in `CHANGELOG.md` with the configured
module manifest version and fails when they do not match. Prerelease
headings such as `## 1.2.0-beta.1` are supported and match when the
manifest declares the same `Prerelease` tag in `PrivateData.PSData`.
A changelog without any version heading fails with a clear message.

## Group

ReleaseHygiene

## Configuration

`ModuleManifest` controls which module manifest supplies `ModuleVersion`.

### Example

```powershell
. (Get-PlumberTaskLoader) -Config @{
    ModuleManifest = 'MyModule.psd1'
}
```

## Run

```powershell
Invoke-Plumber -Task ChangelogUpdated
```

## Pass

```markdown
## 1.2.3
```

## Fail

```markdown
## 1.2.2
```

## Navigation

- [Task index](index.md)
- [Group: ReleaseHygiene](ReleaseHygiene.md)
- Next: [ModuleVersion](ModuleVersion.md)
