# PublishRelease

## Synopsis

Creates the GitHub tag and release for Plumber.

## Description

This is an internal build task for Plumber, and not part of the core task list.

Uses the module manifest version to create a `v<version>` git tag and a
GitHub release with notes from the matching changelog section.

By default this task only reports what it would do. Set
`PLUMBER_RELEASE_CONFIRM` to `true` to create and push the tag and release.

## Run

```powershell
Invoke-Build -File ./Plumber.build.ps1 -Task PublishRelease
```

## Navigation

- [Task index](index.md)
