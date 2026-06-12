function Invoke-PlumberModuleVersion {
    <#
        .SYNOPSIS
        Runs the ModuleVersion task body.
    #>
    [CmdletBinding()]
    param ()

    $versionSource = $script:PlumberConfig.Tasks.ModuleVersion.Source
    switch ($versionSource) {
        'PSGallery' {
            $findErrors = $null
            $findModuleSplat = @{
                Name          = $script:moduleName
                ErrorAction   = 'SilentlyContinue'
                ErrorVariable = 'findErrors'
            }
            $publishedModule = Find-Module @findModuleSplat
            if (-not $publishedModule) {
                # Find-Module returns nothing both for an unpublished module
                # and for a gallery that could not be queried; only a
                # no-match error means the module is genuinely unpublished.
                $queryFailures = @($findErrors | Where-Object {
                    $_.FullyQualifiedErrorId -notlike 'NoMatchFoundForCriteria*'
                })
                if ($queryFailures) {
                    throw (
                        "Could not query PSGallery for $($script:moduleName): " +
                        "$($queryFailures[0]) " +
                        'This may be a transient gallery failure; retry before ' +
                        'assuming the module is unpublished.'
                    )
                }

                Write-Error (
                    "$script:moduleName is not published to PSGallery. " +
                    "Set Tasks.ModuleVersion.Source to GitTag for modules published from git tags."
                )
                return
            }

            $publishedSemVerSplat = @{
                VersionName        = [string]$publishedModule.Version
                AllowSystemVersion = $true
            }
            $publishedVersionInfo = ConvertTo-PlumberSemVer @publishedSemVerSplat
            if (-not $publishedVersionInfo) {
                throw "PSGallery version '$($publishedModule.Version)' is not a valid version."
            }
            $psd1SemVerSplat = @{
                VersionName        = $script:psd1.ModuleVersion
                AllowSystemVersion = $true
            }
            $psd1VersionInfo = ConvertTo-PlumberSemVer @psd1SemVerSplat
            if (-not $psd1VersionInfo) {
                throw "ModuleVersion '$($script:psd1.ModuleVersion)' is not a valid version."
            }
            $publishedVersion = $publishedVersionInfo.Version
            $psd1Version = $psd1VersionInfo.Version
        }
        'GitTag' {
            $gitTagVersionSplat = @{
                Remote            = $script:PlumberConfig.Tasks.ModuleVersion.Remote
                IncludePrerelease = $script:PlumberConfig.Tasks.ModuleVersion.IncludePrerelease
            }
            $publishedVersionInfo = Get-PlumberGitTagVersion @gitTagVersionSplat
            if (-not $publishedVersionInfo) {
                $remoteName = $script:PlumberConfig.Tasks.ModuleVersion.Remote
                Write-Build Yellow "No semantic versions found from $remoteName tags"
                return
            }

            $publishedVersion = $publishedVersionInfo.Version
            $psd1VersionInfo = ConvertTo-PlumberSemVer -VersionName $script:psd1.ModuleVersion -AllowSystemVersion
            if (-not $psd1VersionInfo) {
                throw "ModuleVersion '$($script:psd1.ModuleVersion)' is not a valid version."
            }
            $psd1Version = $psd1VersionInfo.Version
        }
        default {
            throw "Unsupported Tasks.ModuleVersion.Source '$versionSource'."
        }
    }

    if ($psd1Version -le $publishedVersion) {
        Write-Error (
            "ModuleVersion is not merge-ready. PSD1 version $psd1Version " +
            "must be greater than $versionSource version $publishedVersion " +
            'before this change is merged.'
        )
    }
}
