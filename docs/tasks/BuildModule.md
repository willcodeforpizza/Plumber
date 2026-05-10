# BuildModule

## Synopsis

Builds a publishable Plumber module folder.

## Description

This is an internal build task for Plumber, and not part of the core task list.

Creates a clean module folder under `out/Plumber` using an explicit
allow-list of files and folders required for publishing.

## Run

```powershell
Invoke-Build -File ./Plumber.build.ps1 -Task BuildModule
```

## Navigation

- [Task index](index.md)
