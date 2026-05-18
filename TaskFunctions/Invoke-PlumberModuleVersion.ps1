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
            $publishedModule = Find-Module $script:moduleName -ErrorAction SilentlyContinue
            if (-not $publishedModule) {
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
