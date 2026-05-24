BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../../Plumber.psd1" -Force
    }
}

Describe 'Test-PlumberTaskShouldRun' {
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

    It 'returns true when RunWhen is Always' {
        InModuleScope Plumber {
            Test-PlumberTaskShouldRun -Name JSON -RunWhen Always |
                Should -BeTrue
        }
    }

    It 'returns false when RunWhen is Never' {
        InModuleScope Plumber {
            Test-PlumberTaskShouldRun -Name YAML -RunWhen Never |
                Should -BeFalse
        }
    }

    It 'returns false when RunWhen is OnRelease without release intent' {
        InModuleScope Plumber {
            Test-PlumberTaskShouldRun -Name ModuleVersion -RunWhen OnRelease |
                Should -BeFalse
        }
    }

    It 'returns true when RunWhen is OnRelease with release intent' {
        $env:PLUMBER_RELEASE_INTENT = 'true'

        InModuleScope Plumber {
            Test-PlumberTaskShouldRun -Name ModuleVersion -RunWhen OnRelease |
                Should -BeTrue
        }
    }

    It 'accepts common truthy release intent values' {
        foreach ($releaseIntent in @('True', 'TRUE', '1', 'yes')) {
            $env:PLUMBER_RELEASE_INTENT = $releaseIntent

            InModuleScope Plumber {
                Test-PlumberTaskShouldRun -Name ModuleVersion -RunWhen OnRelease |
                    Should -BeTrue
            }
        }
    }

    It 'throws for unknown RunWhen values' {
        InModuleScope Plumber {
            { Test-PlumberTaskShouldRun -Name JSON -RunWhen Sometimes } |
                Should -Throw '*RunWhen*Sometimes*'
        }
    }
}
