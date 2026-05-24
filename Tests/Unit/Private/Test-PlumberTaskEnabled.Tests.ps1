BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../../Plumber.psd1" -Force
    }
}

Describe 'Test-PlumberTaskEnabled' {
    BeforeEach {
        $script:previousReleaseIntent = $env:PLUMBER_RELEASE_INTENT
        Remove-Item Env:/PLUMBER_RELEASE_INTENT -ErrorAction SilentlyContinue
    }

    AfterEach {
        if ($null -eq $script:previousReleaseIntent) {
            Remove-Item Env:/PLUMBER_RELEASE_INTENT -ErrorAction SilentlyContinue
        } else {
            $env:PLUMBER_RELEASE_INTENT = $script:previousReleaseIntent
        }
    }

    It 'returns true when EnforceWhen is Always' {
        InModuleScope Plumber {
            Test-PlumberTaskEnabled -Name JSON -EnforceWhen Always |
                Should -BeTrue
        }
    }

    It 'returns false when EnforceWhen is Never' {
        InModuleScope Plumber {
            Test-PlumberTaskEnabled -Name YAML -EnforceWhen Never |
                Should -BeFalse
        }
    }

    It 'returns false when EnforceWhen is OnRelease without release intent' {
        InModuleScope Plumber {
            Test-PlumberTaskEnabled -Name ModuleVersion -EnforceWhen OnRelease |
                Should -BeFalse
        }
    }

    It 'returns true when EnforceWhen is OnRelease with release intent' {
        $env:PLUMBER_RELEASE_INTENT = 'true'

        InModuleScope Plumber {
            Test-PlumberTaskEnabled -Name ModuleVersion -EnforceWhen OnRelease |
                Should -BeTrue
        }
    }

    It 'accepts common truthy release intent values' {
        foreach ($releaseIntent in @('True', 'TRUE', '1', 'yes')) {
            $env:PLUMBER_RELEASE_INTENT = $releaseIntent

            InModuleScope Plumber {
                Test-PlumberTaskEnabled -Name ModuleVersion -EnforceWhen OnRelease |
                    Should -BeTrue
            }
        }
    }

    It 'throws for unknown EnforceWhen values' {
        InModuleScope Plumber {
            { Test-PlumberTaskEnabled -Name JSON -EnforceWhen Sometimes } |
                Should -Throw '*EnforceWhen*Sometimes*'
        }
    }
}
