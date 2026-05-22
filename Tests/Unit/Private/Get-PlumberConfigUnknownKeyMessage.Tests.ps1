BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../../Plumber.psd1" -Force
    }
}

Describe 'Get-PlumberConfigUnknownKeyMessage' {
    It 'includes a suggestion when a close match exists' {
        InModuleScope Plumber {
            $messageSplat = @{
                Path        = 'Tasks.PSScriptAnalyzer.Excdddlude'
                Kind        = 'setting'
                AllowedName = @('Exclude', 'IncludeTests')
            }
            $message = Get-PlumberConfigUnknownKeyMessage @messageSplat
            $expected = @(
                'Tasks.PSScriptAnalyzer.Excdddlude is not a known setting.'
                'Did you mean Exclude?'
            ) -join ' '

            $message | Should -Be $expected
        }
    }

    It 'omits suggestions when no close match exists' {
        InModuleScope Plumber {
            $messageSplat = @{
                Path        = 'Tasks.LineLength.Banana'
                Kind        = 'setting'
                AllowedName = @('Exclude', 'MaxLength')
            }
            $message = Get-PlumberConfigUnknownKeyMessage @messageSplat

            $message | Should -Be 'Tasks.LineLength.Banana is not a known setting'
        }
    }
}
