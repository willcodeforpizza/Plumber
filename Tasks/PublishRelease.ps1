<#
    .SYNOPSIS
    Creates the GitHub tag and release for Plumber.

    .DESCRIPTION
    This is an internal build task for Plumber, and not part of the core task list.

    Uses the module manifest version to create a `v<version>` git tag and a
    GitHub release with notes from the matching changelog section.

    By default this task only reports what it would do. Set
    `PLUMBER_RELEASE_CONFIRM` to `true` to create and push the tag and release.

    .RUN
    ```powershell
    Invoke-Build -File ./Plumber.build.ps1 -Task PublishRelease
    ```
#>
Add-BuildTask -Name PublishRelease -Jobs {
    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
        Write-Error 'GitHub CLI is required to publish a GitHub release.'
        return
    }

    $manifestPath = Join-Path $BuildRoot 'Plumber.psd1'
    $manifest = Test-ModuleManifest -Path $manifestPath
    $version = $manifest.Version.ToString()
    $tagName = "v$version"

    $existingTag = git tag --list $tagName
    if ($existingTag) {
        Write-Error "Git tag already exists: $tagName"
        return
    }

    $changelog = Get-Content (Join-Path $BuildRoot 'changelog.md')
    $sectionStart = [array]::IndexOf($changelog, "## $version")
    if ($sectionStart -lt 0) {
        Write-Error "No changelog section found for version $version."
        return
    }

    $sectionEnd = $changelog.Count
    for ($i = $sectionStart + 1; $i -lt $changelog.Count; $i++) {
        if ($changelog[$i] -match '^## \d') {
            $sectionEnd = $i
            break
        }
    }

    $releaseNotes = @($changelog[($sectionStart + 1)..($sectionEnd - 1)]).Trim() |
        Where-Object {$_}
    $releaseNotesPath = Join-Path $BuildRoot 'out/release-notes.md'
    $releaseNotesRoot = Split-Path $releaseNotesPath -Parent
    New-Item -Path $releaseNotesRoot -ItemType Directory -Force | Out-Null
    Set-Content -Path $releaseNotesPath -Value $releaseNotes

    if ($env:PLUMBER_RELEASE_CONFIRM -ne 'true') {
        Write-Build Yellow "Would create and push git tag $tagName"
        Write-Build Yellow "Would create GitHub release $tagName"
        Write-Build Yellow "Set PLUMBER_RELEASE_CONFIRM=true to publish the release."
        return
    }

    git tag $tagName
    git push origin $tagName
    gh release create $tagName --title $tagName --notes-file $releaseNotesPath
}
