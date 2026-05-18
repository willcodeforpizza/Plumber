BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../../Plumber.psd1" -Force
    }
}

Describe 'Invoke-PlumberManifest' {
    It 'validates the configured module manifest' {
        $manifestPath = Join-Path $TestDrive 'ManifestModule.psd1'
        Set-Content -Path $manifestPath -Value '@{}'

        InModuleScope Plumber -Parameters @{ManifestPath = $manifestPath} {
            Mock Test-ModuleManifest {}

            $script:moduleManifest = Get-Item $ManifestPath

            Invoke-PlumberManifest

            Should -Invoke Test-ModuleManifest -ParameterFilter {
                $Path -eq $ManifestPath
            }
        }
    }
}
