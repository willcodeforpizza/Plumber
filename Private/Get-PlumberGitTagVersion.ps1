function Get-PlumberGitTagVersion {
    <#
        .SYNOPSIS
        Gets the latest semantic version from git tags on a remote.
    #>
    [CmdletBinding()]
    param (
        [string]
        $Remote = 'origin',

        [bool]
        $IncludePrerelease = $false
    )

    $tagRefs = Invoke-PlumberGit -ArgumentList @('ls-remote', '--tags', $Remote)
    $versions = foreach ($tagRef in @($tagRefs)) {
        if ($tagRef -notmatch 'refs/tags/(?<TagName>[^\^]+)(?:\^\{\})?$') {
            continue
        }

        $version = ConvertTo-PlumberSemVer -VersionName $Matches.TagName
        if (-not $version) {
            continue
        }
        if (-not $IncludePrerelease -and $version.IsPrerelease) {
            continue
        }

        $version
    }

    $versions |
        Sort-Object -Property Version -Descending |
            Select-Object -First 1
}
