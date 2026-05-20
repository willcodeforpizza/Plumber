BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../../Plumber.psd1" -Force
    }
}

Describe 'Get-PlumberConfigSuggestion' {
    It 'returns the closest likely config name' {
        InModuleScope Plumber {
            Get-PlumberConfigSuggestion -Name 'LiiiineLength' -AllowedName @('LineLength', 'JSON') |
                Should -Be 'LineLength'
        }
    }

    It 'matches candidates case-insensitively' {
        InModuleScope Plumber {
            Get-PlumberConfigSuggestion -Name 'linelenght' -AllowedName @('LineLength', 'JSON') |
                Should -Be 'LineLength'
        }
    }

    It 'does not return distant suggestions' {
        InModuleScope Plumber {
            Get-PlumberConfigSuggestion -Name 'CompletelyDifferent' -AllowedName @('LineLength', 'JSON') |
                Should -BeNullOrEmpty
        }
    }
}
