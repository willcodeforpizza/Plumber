BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../../Plumber.psd1" -Force
    }
}

Describe 'Invoke-PlumberChangelogUpdated' {
    BeforeEach {
        $script:buildRoot = Join-Path $TestDrive 'ChangelogModule'
        New-Item -Path $script:buildRoot -ItemType Directory -Force | Out-Null
    }

    It 'passes when the latest changelog heading matches the module version' {
        Set-Content -Path (Join-Path $script:buildRoot 'CHANGELOG.md') -Value @(
            '# Changelog'
            ''
            '## 1.2.3'
            '- Changed: example.'
        )

        InModuleScope Plumber -Parameters @{BuildRoot = $script:buildRoot} {
            $script:psd1 = @{
                ModuleVersion = '1.2.3'
            }

            { Invoke-PlumberChangelogUpdated -ErrorAction Stop } | Should -Not -Throw
        }
    }

    It 'reports a stale changelog heading' {
        Set-Content -Path (Join-Path $script:buildRoot 'CHANGELOG.md') -Value @(
            '# Changelog'
            ''
            '## 1.2.2'
            '- Changed: example.'
        )

        InModuleScope Plumber -Parameters @{BuildRoot = $script:buildRoot} {
            $script:psd1 = @{
                ModuleVersion = '1.2.3'
            }

            { Invoke-PlumberChangelogUpdated -ErrorAction Stop } |
                Should -Throw -ExpectedMessage '*PSD1 version 1.2.3 changelog version 1.2.2*'
        }
    }

    It 'passes when a prerelease heading matches the manifest version and prerelease tag' {
        Set-Content -Path (Join-Path $script:buildRoot 'CHANGELOG.md') -Value @(
            '# Changelog'
            ''
            '## 1.2.0-beta.1'
            '- Changed: example.'
        )

        InModuleScope Plumber -Parameters @{BuildRoot = $script:buildRoot} {
            $script:psd1 = @{
                ModuleVersion = '1.2.0'
                PrivateData   = @{
                    PSData = @{
                        Prerelease = 'beta.1'
                    }
                }
            }

            { Invoke-PlumberChangelogUpdated -ErrorAction Stop } | Should -Not -Throw
        }
    }

    It 'reports a mismatch between a prerelease heading and a stable manifest version' {
        Set-Content -Path (Join-Path $script:buildRoot 'CHANGELOG.md') -Value @(
            '# Changelog'
            ''
            '## 1.2.0-beta.1'
            '- Changed: example.'
        )

        InModuleScope Plumber -Parameters @{BuildRoot = $script:buildRoot} {
            $script:psd1 = @{
                ModuleVersion = '1.2.0'
            }

            { Invoke-PlumberChangelogUpdated -ErrorAction Stop } |
                Should -Throw -ExpectedMessage '*PSD1 version 1.2.0 changelog version 1.2.0-beta.1*'
        }
    }

    It 'reports a mismatch between prerelease tags' {
        Set-Content -Path (Join-Path $script:buildRoot 'CHANGELOG.md') -Value @(
            '# Changelog'
            ''
            '## 1.2.0-beta.1'
            '- Changed: example.'
        )

        InModuleScope Plumber -Parameters @{BuildRoot = $script:buildRoot} {
            $script:psd1 = @{
                ModuleVersion = '1.2.0'
                PrivateData   = @{
                    PSData = @{
                        Prerelease = 'beta.2'
                    }
                }
            }

            { Invoke-PlumberChangelogUpdated -ErrorAction Stop } |
                Should -Throw -ExpectedMessage '*PSD1 version 1.2.0-beta.2 changelog version 1.2.0-beta.1*'
        }
    }

    It 'reports a changelog with no version heading' {
        Set-Content -Path (Join-Path $script:buildRoot 'CHANGELOG.md') -Value @(
            '# Changelog'
            ''
            '- Changed: example without a version heading.'
        )

        InModuleScope Plumber -Parameters @{BuildRoot = $script:buildRoot} {
            $script:psd1 = @{
                ModuleVersion = '1.2.3'
            }

            { Invoke-PlumberChangelogUpdated -ErrorAction Stop } |
                Should -Throw -ExpectedMessage '*Changelog has no version heading*'
        }
    }

    It 'reports an unparseable version heading' {
        Set-Content -Path (Join-Path $script:buildRoot 'CHANGELOG.md') -Value @(
            '# Changelog'
            ''
            '## 1.bad'
            '- Changed: example.'
        )

        InModuleScope Plumber -Parameters @{BuildRoot = $script:buildRoot} {
            $script:psd1 = @{
                ModuleVersion = '1.2.3'
            }

            { Invoke-PlumberChangelogUpdated -ErrorAction Stop } |
                Should -Throw -ExpectedMessage "*Changelog version heading '1.bad' is not a valid version*"
        }
    }
}
