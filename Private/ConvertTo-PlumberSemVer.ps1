function ConvertTo-PlumberSemVer {
    <#
        .SYNOPSIS
        Converts a version string or tag name to a semantic version.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $VersionName,

        [switch]
        $AllowSystemVersion
    )

    $normalizedVersion = $VersionName -replace '^v', ''
    if ($normalizedVersion -match '^\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?(?:\+[0-9A-Za-z.-]+)?$') {
        return [pscustomobject]@{
            OriginalName  = $VersionName
            Version       = [semver]$normalizedVersion
            IsPrerelease  = $normalizedVersion -match '-'
        }
    }

    if (-not $AllowSystemVersion) {
        return $null
    }

    try {
        $version = [version]$normalizedVersion
    } catch {
        return $null
    }
    $patch = if ($version.Build -ge 0) { $version.Build } else { 0 }
    [pscustomobject]@{
        OriginalName  = $VersionName
        Version       = [semver]"$($version.Major).$($version.Minor).$patch"
        IsPrerelease  = $false
    }
}
