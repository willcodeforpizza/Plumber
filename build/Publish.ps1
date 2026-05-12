<#
    .SYNOPSIS
    Builds, publishes to PowerShell Gallery, and creates a GitHub release.

    .DESCRIPTION
    Top-level release workflow and entry point for all release tasks. Runs
    `BuildModule`, `PublishModule`, and `PublishRelease` in order.

    Both publish steps default to dry-run mode. Set both
    `PSGALLERY_PUBLISH_CONFIRM` and `GITHUB_RELEASE_CONFIRM` to `true` to
    publish for real.

    .RUN
    ```powershell
    # full release (dry run by default)
    Invoke-Build -File ./Tasks/Publish.ps1

    # individual tasks
    Invoke-Build -File ./Tasks/Publish.ps1 BuildModule
    Invoke-Build -File ./Tasks/Publish.ps1 PublishModule
    Invoke-Build -File ./Tasks/Publish.ps1 PublishRelease

    # override the output location
    Invoke-Build -File ./Tasks/Publish.ps1 -ModuleOutputRoot /tmp/my-build

    # full release for real
    $env:PSGALLERY_API_KEY = '<api-key>'
    $env:PSGALLERY_PUBLISH_CONFIRM = 'true'
    $env:GITHUB_RELEASE_CONFIRM = 'true'
    Invoke-Build -File ./Tasks/Publish.ps1
    ```
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSReviewUnusedParameter',
    'ModuleOutputRoot',
    Justification = 'Used by dot-sourced release tasks.'
)]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSReviewUnusedParameter',
    'ModuleBuildExtraItems',
    Justification = 'Used by dot-sourced release tasks.'
)]
param(
    [string]$ModuleRoot = (Split-Path $PSScriptRoot -Parent),
    [string]$ModuleName = (
        (
            Get-ChildItem -Path $ModuleRoot -Filter '*.psd1' -File -ErrorAction SilentlyContinue |
                Select-Object -First 1
        ).BaseName
    ),
    [string]$ModuleOutputRoot = (Join-Path ([System.IO.Path]::GetTempPath()) $ModuleName),
    [string[]]$ModuleBuildExtraItems = @()
)

if (-not $ModuleName) {
    throw "Could not auto-discover module name (no *.psd1 found in '$ModuleRoot'). Pass -ModuleName explicitly."
}

. (Join-Path $PSScriptRoot 'BuildModule.ps1')
. (Join-Path $PSScriptRoot 'PublishRelease.ps1')
. (Join-Path $PSScriptRoot 'PublishModule.ps1')

Add-BuildTask -Name Publish -Jobs BuildModule, PublishModule, PublishRelease
Add-BuildTask -Name . -Jobs Publish
