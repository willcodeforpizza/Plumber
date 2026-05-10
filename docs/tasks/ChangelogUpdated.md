# ChangelogUpdated

## Synopsis

Validates the changelog has been updated.

## Description

Compares the latest version heading in `changelog.md` with the configured
module manifest version and fails when they do not match.

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
