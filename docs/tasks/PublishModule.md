# PublishModule

## Synopsis

Publishes Plumber to PowerShell Gallery.

## Description

This is an internal build task for Plumber, and not part of the core task list.

Builds a clean module folder with `BuildModule` and publishes `out/Plumber`
using `Publish-PSResource`.

The PowerShell Gallery API key is read from `PSGALLERY_API_KEY`.

By default this task runs with `-WhatIf`. Set `PLUMBER_PUBLISH_CONFIRM` to
`true` to publish for real.

## Run

```powershell
$env:PSGALLERY_API_KEY = '<api-key>'
Invoke-Build -File ./Plumber.build.ps1 -Task PublishModule
```

## Navigation

- [Task index](index.md)
