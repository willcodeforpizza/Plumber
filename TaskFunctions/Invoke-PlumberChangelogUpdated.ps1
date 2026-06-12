function Invoke-PlumberChangelogUpdated {
    <#
        .SYNOPSIS
        Runs the ChangelogUpdated task body.
    #>
    [CmdletBinding()]
    param ()

    $changelog = Get-Content (Join-Path $BuildRoot 'CHANGELOG.md') -ErrorAction SilentlyContinue
    if (-not $changelog) {
        Write-Build Yellow 'No changelog found'
        return
    }

    $latestLine = $changelog |
        Where-Object { $_ -match '^## [0-9]' } |
        Select-Object -First 1

    if (-not $latestLine) {
        Write-Error (
            'Changelog has no version heading. ' +
            "Add a '## <version>' heading matching the module version."
        )
        return
    }

    $headingVersionName = ($latestLine -replace '^##').Trim()
    $changelogVersionInfo = ConvertTo-PlumberSemVer -VersionName $headingVersionName -AllowSystemVersion
    if (-not $changelogVersionInfo) {
        Write-Error "Changelog version heading '$headingVersionName' is not a valid version."
        return
    }

    $psd1VersionName = [string]$script:psd1.ModuleVersion
    $prereleaseTag = $script:psd1.PrivateData.PSData.Prerelease
    if ($prereleaseTag) {
        $psd1VersionName = "$psd1VersionName-$prereleaseTag"
    }
    $psd1VersionInfo = ConvertTo-PlumberSemVer -VersionName $psd1VersionName -AllowSystemVersion
    if (-not $psd1VersionInfo) {
        throw "ModuleVersion '$psd1VersionName' is not a valid version."
    }

    if ($psd1VersionInfo.Version -ne $changelogVersionInfo.Version) {
        Write-Error (
            'Changelog might be out of date. ' +
            "PSD1 version $($psd1VersionInfo.Version) " +
            "changelog version $($changelogVersionInfo.Version)"
        )
    }
}
