<#
    .SYNOPSIS
    Validates current PSD1 version is higher than the published version.

    .DESCRIPTION
    Looks up the latest published module version from PSGallery or git tags
    and fails when the configured manifest version is not greater than the
    published version.

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
    . (Join-Path $script:PlumberConfig.ModuleRoot 'Private/ConvertTo-PlumberSemVer.ps1')
    . (Join-Path $script:PlumberConfig.ModuleRoot 'Private/Invoke-PlumberGit.ps1')
    . (Join-Path $script:PlumberConfig.ModuleRoot 'Private/Get-PlumberGitTagVersion.ps1')

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

            $publishedVersion = [version]$publishedModule.Version
            $psd1Version = [version]$script:psd1.ModuleVersion
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
            'PSD1 version might be out of date. ' +
            "PSD1 version $psd1Version " +
            "$versionSource version $publishedVersion"
        )
    }
}
