<#
    .SYNOPSIS
    Validates current PSD1 version is merge-ready.

    .DESCRIPTION
    Looks up the latest published module version from PSGallery or git tags.
    Fails when the configured manifest version is not greater than the
    published version because a mergeable change must advance the next
    publishable module version.

    .GROUP
    ReleaseHygiene

    .CONFIGURATION
    ModuleManifest controls which module manifest supplies the module name
    and ModuleVersion.

    Tasks.ModuleVersion.Source controls where the published version is read
    from. Supported values are PSGallery and GitTag. PSGallery is the default.

    Tasks.ModuleVersion.Remote controls which git remote supplies tags for
    GitTag checks. The default is origin.

    Tasks.ModuleVersion.IncludePrerelease controls whether prerelease git tags
    are included. The default is false.

    ### Example

    ```powershell
    . (Get-PlumberTaskLoader) -Config @{
        ModuleManifest = 'MyModule.psd1'
        Tasks          = @{
            ModuleVersion = @{
                Source = 'GitTag'
                Remote = 'origin'
            }
        }
    }
    ```

    .RUN
    ```powershell
    Invoke-Plumber -Task ModuleVersion
    ```

    .PASS
    ```powershell
    ModuleVersion = '1.2.3'
    ```

    .FAIL
    ```powershell
    ModuleVersion = '1.2.2'
    ```
#>
Add-BuildTask -Name ModuleVersion -Jobs SetVariables, {
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
