<#
    .SYNOPSIS
    Builds a publishable module folder.

    .DESCRIPTION
    Creates a clean module folder in `$ModuleOutputRoot` using an explicit
    allow-list of files and folders. Missing items are skipped; the
    `Test-ModuleManifest` call is the strict gate.

    `$ModuleRoot`, `$ModuleName`, `$ModuleOutputRoot`, and
    `$ModuleBuildExtraItems` default if not already set by a caller (e.g.
    `Publish.ps1`'s `param()` block).

    .RUN
    ```powershell
    # standalone (uses defaults)
    Invoke-Build -File ./Tasks/BuildModule.ps1

    # via the entry point (supports CLI overrides)
    Invoke-Build -File ./Tasks/Publish.ps1 BuildModule
    ```
#>
if ($script:_loadedBuildModule) { return }
$script:_loadedBuildModule = $true

if (-not $ModuleRoot) { $ModuleRoot = Split-Path $PSScriptRoot -Parent }
if (-not $ModuleName) {
    $ModuleName = (Get-ChildItem -Path $ModuleRoot -Filter '*.psd1' -File -ErrorAction SilentlyContinue |
        Select-Object -First 1).BaseName
}
if (-not $ModuleName) {
    throw @"
Could not auto-discover module name (no *.psd1 found in '$ModuleRoot').
Set `$ModuleName before invoking.
"@
}
if (-not $ModuleOutputRoot) { $ModuleOutputRoot = Join-Path ([System.IO.Path]::GetTempPath()) $ModuleName }
if (-not $ModuleBuildExtraItems) { $ModuleBuildExtraItems = @() }

Add-BuildTask -Name BuildModule -Jobs {
    if (Test-Path $ModuleOutputRoot) {
        Remove-Item $ModuleOutputRoot -Recurse -Force
    }
    New-Item -Path $ModuleOutputRoot -ItemType Directory -Force | Out-Null

    $items = @(
        'Private',
        'Public',
        'Resource',
        'LICENSE',
        'README.md',
        'CHANGELOG.md',
        'changelog.md',
        "$ModuleName.psd1",
        "$ModuleName.psm1"
    ) + @($ModuleBuildExtraItems)

    foreach ($item in $items) {
        $source = Join-Path $ModuleRoot $item
        if (-not (Test-Path $source)) {
            Write-Verbose "Skipping missing item: $item"
            continue
        }

        Copy-Item -Path $source -Destination $ModuleOutputRoot -Recurse -Force
    }

    $manifestPath = Join-Path $ModuleOutputRoot "$ModuleName.psd1"
    Test-ModuleManifest -Path $manifestPath | Out-Null
    Import-Module $manifestPath -Force -PassThru | Out-Null
    Write-Build Green "Built publish folder: $ModuleOutputRoot"
}
