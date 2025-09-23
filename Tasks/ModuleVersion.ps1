<#
    .SYNOPSIS
    Validates current PSD1 version is higher then current published version
#>
task -Name ModuleVersion -Jobs SetVariables, {
    $source = $script:psd1.PrivateData.PSData.PublishSource

    switch ($source) {
        'Local' { $publishedVersion = '1.0.0' }

        'PowershellGallery' {
            $publishedVersion = Find-Module $script:moduleName |
            Select-Object -Expand Version
        }

        'Github' {
            $releaseParams = @{
                OwnerName      = $script:psd1.Author
                RepositoryName = $script:moduleName
                Latest         = $true
            }
            $release = Get-GitHubRelease @releaseParams
            $publishedVersion = $release.tag_name -replace 'v'
        }

        default { $publishedVersion = '1.0.0' }
    }

    $publishedVersion = [version]$publishedVersion
    $psd1Version = [version]$script:psd1.ModuleVersion
    if ($script:psd1.ModuleVersion -le $publishedVersion) {
        Write-Error (
            'PSD1 version might be out of date. ' +
            "PSD1 version $psd1Version " +
            "Published version $publishedVersion"
        )
    }
}