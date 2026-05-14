BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../../Plumber.psd1" -Force
    }
}

Describe 'ConvertTo-PlumberSemVer' {
    It 'accepts semantic tags with or without a leading v' {
        InModuleScope Plumber {
            (ConvertTo-PlumberSemVer -VersionName 'v1.2.3').Version | Should -Be ([semver]'1.2.3')
            (ConvertTo-PlumberSemVer -VersionName '1.2.4').Version | Should -Be ([semver]'1.2.4')
        }
    }

    It 'ignores non-semantic tag names' {
        InModuleScope Plumber {
            ConvertTo-PlumberSemVer -VersionName 'release-2026-05-15' | Should -BeNullOrEmpty
            ConvertTo-PlumberSemVer -VersionName '1.2' | Should -BeNullOrEmpty
        }
    }

    It 'normalizes manifest versions when requested' {
        InModuleScope Plumber {
            (ConvertTo-PlumberSemVer -VersionName '1.2' -AllowSystemVersion).Version |
                Should -Be ([semver]'1.2.0')
        }
    }
}

Describe 'Get-PlumberGitTagVersion' {
    It 'gets the highest stable semantic tag from the configured remote' {
        InModuleScope Plumber {
            Mock Invoke-PlumberGit {
                @(
                    "1111111111111111111111111111111111111111`trefs/tags/v1.1.0"
                    "2222222222222222222222222222222222222222`trefs/tags/v1.3.0-alpha.1"
                    "3333333333333333333333333333333333333333`trefs/tags/1.2.0"
                    "4444444444444444444444444444444444444444`trefs/tags/not-a-version"
                )
            }

            $version = Get-PlumberGitTagVersion -Remote upstream

            $version.OriginalName | Should -Be '1.2.0'
            $version.Version | Should -Be ([semver]'1.2.0')
            Should -Invoke Invoke-PlumberGit -ParameterFilter {
                $ArgumentList[0] -eq 'ls-remote' -and
                    $ArgumentList[1] -eq '--tags' -and
                    $ArgumentList[2] -eq 'upstream'
            }
        }
    }

    It 'includes prerelease tags when configured' {
        InModuleScope Plumber {
            Mock Invoke-PlumberGit {
                @(
                    "1111111111111111111111111111111111111111`trefs/tags/v1.1.0"
                    "2222222222222222222222222222222222222222`trefs/tags/v1.3.0-alpha.1"
                )
            }

            $version = Get-PlumberGitTagVersion -IncludePrerelease $true

            $version.OriginalName | Should -Be 'v1.3.0-alpha.1'
        }
    }

    It 'ignores peeled annotated tag refs' {
        InModuleScope Plumber {
            Mock Invoke-PlumberGit {
                @(
                    "1111111111111111111111111111111111111111`trefs/tags/v1.1.0"
                    "2222222222222222222222222222222222222222`trefs/tags/v1.1.0^{}"
                )
            }

            $version = Get-PlumberGitTagVersion

            $version.OriginalName | Should -Be 'v1.1.0'
        }
    }
}
