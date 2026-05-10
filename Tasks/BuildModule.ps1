<#
    .SYNOPSIS
    Builds a publishable Plumber module folder.

    .DESCRIPTION
    This is an internal build task for Plumber, and not part of the core task list.

    Creates a clean module folder under `out/Plumber` using an explicit
    allow-list of files and folders required for publishing.

    .RUN
    ```powershell
    Invoke-Build -File ./Plumber.build.ps1 -Task BuildModule
    ```
#>
Add-BuildTask -Name BuildModule -Jobs {
    $outputRoot = Join-Path $BuildRoot 'out'
    $moduleOutputRoot = Join-Path $outputRoot 'Plumber'

    if (Test-Path $moduleOutputRoot) {
        Remove-Item $moduleOutputRoot -Recurse -Force
    }
    New-Item -Path $moduleOutputRoot -ItemType Directory -Force | Out-Null

    $items = @(
        'Private',
        'Public',
        'Resource',
        'Tasks',
        'docs',
        'LICENSE',
        'README.md',
        'changelog.md',
        'Plumber.psd1',
        'Plumber.psm1'
    )

    foreach ($item in $items) {
        $source = Join-Path $BuildRoot $item
        if (-not (Test-Path $source)) {
            Write-Error "Required publish item not found: $item"
            continue
        }

        Copy-Item -Path $source -Destination $moduleOutputRoot -Recurse -Force
    }

    $manifestPath = Join-Path $moduleOutputRoot 'Plumber.psd1'
    Test-ModuleManifest -Path $manifestPath | Out-Null
    Import-Module $manifestPath -Force -PassThru | Out-Null
    Write-Build Green "Built publish folder: $moduleOutputRoot"
}
