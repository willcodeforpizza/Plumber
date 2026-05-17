<#
    .SYNOPSIS
    Validates the changelog has been updated.

    .DESCRIPTION
    Compares the latest version heading in `CHANGELOG.md` with the configured
    module manifest version and fails when they do not match.

    .GROUP
    ReleaseHygiene

    .CONFIGURATION
    `ModuleManifest` controls which module manifest supplies `ModuleVersion`.

    ### Example

    ```powershell
    . (Get-PlumberTaskLoader) -Config @{
        ModuleManifest = 'MyModule.psd1'
    }
    ```

    .RUN
    ```powershell
    Invoke-Plumber -Task ChangelogUpdated
    ```

    .PASS
    ```markdown
    ## 1.2.3
    ```

    .FAIL
    ```markdown
    ## 1.2.2
    ```
#>
Add-BuildTask -Name ChangelogUpdated -Jobs SetVariables, {
    $changelog = Get-Content (Join-Path $BuildRoot 'CHANGELOG.md') -ErrorAction SilentlyContinue
    if (-not $changelog) {
        Write-Build Yellow 'No changelog found'
        return
    }

    $latestLine = $changelog |
        Where-Object { $_ -match '^## [0-9]' } |
        Select-Object -First 1

    $changelogVersion = [version]($latestLine -replace '## ')
    $psd1Version = $script:psd1.ModuleVersion

    if ($psd1Version -ne $changelogVersion) {
        Write-Error (
            'Changelog might be out of date. ' +
            "PSD1 version $psd1Version " +
            "changelog version $changelogVersion"
        )
    }
}
