BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../../Plumber.psd1" -Force
    }
}

Describe 'Get-PlumberConfigEditDistance' {
    It 'returns zero for matching names' {
        InModuleScope Plumber {
            Get-PlumberConfigEditDistance -Left 'LineLength' -Right 'LineLength' |
                Should -Be 0
        }
    }

    It 'counts insertions, deletions and replacements' {
        InModuleScope Plumber {
            Get-PlumberConfigEditDistance -Left 'LineLength' -Right 'LiiiineLength' |
                Should -Be 3
            Get-PlumberConfigEditDistance -Left 'Exclude' -Right 'Excdddlude' |
                Should -Be 3
            Get-PlumberConfigEditDistance -Left 'Local' -Right 'Lacal' |
                Should -Be 1
        }
    }
}
