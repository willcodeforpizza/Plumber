BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../../Plumber.psd1" -Force
    }
}

Describe 'StreamPesterOutput helpers' {
    BeforeEach {
        Remove-Variable -Name PlumberStreamPesterOutput -Scope Global -ErrorAction SilentlyContinue
    }

    AfterEach {
        Remove-Variable -Name PlumberStreamPesterOutput -Scope Global -ErrorAction SilentlyContinue
    }

    It 'returns $null when no preference is set' {
        InModuleScope Plumber {
            Get-PlumberStreamPesterOutput | Should -BeNullOrEmpty
        }
    }

    It 'returns the value set by Set-PlumberStreamPesterOutput' {
        InModuleScope Plumber {
            $null = Set-PlumberStreamPesterOutput -Value $true
            Get-PlumberStreamPesterOutput | Should -BeTrue
        }
    }

    It 'Restore removes the variable when no previous value existed' {
        InModuleScope Plumber {
            $token = Set-PlumberStreamPesterOutput -Value $true
            Get-PlumberStreamPesterOutput | Should -BeTrue
            Restore-PlumberStreamPesterOutput -Token $token
            Get-PlumberStreamPesterOutput | Should -BeNullOrEmpty
        }
    }

    It 'Restore returns the variable to its previous value when one existed' {
        InModuleScope Plumber {
            Set-Variable -Name PlumberStreamPesterOutput -Scope Global -Value $false
            $token = Set-PlumberStreamPesterOutput -Value $true
            Get-PlumberStreamPesterOutput | Should -BeTrue
            Restore-PlumberStreamPesterOutput -Token $token
            Get-PlumberStreamPesterOutput | Should -BeFalse
        }
    }

    It 'supports stack-safe nesting' {
        # Simulates nested Invoke-Plumber calls: outer sets $true, inner sets
        # $false, inner restores ($true again), outer restores (gone).
        InModuleScope Plumber {
            $outer = Set-PlumberStreamPesterOutput -Value $true
            Get-PlumberStreamPesterOutput | Should -BeTrue

            $inner = Set-PlumberStreamPesterOutput -Value $false
            Get-PlumberStreamPesterOutput | Should -BeFalse

            Restore-PlumberStreamPesterOutput -Token $inner
            Get-PlumberStreamPesterOutput | Should -BeTrue

            Restore-PlumberStreamPesterOutput -Token $outer
            Get-PlumberStreamPesterOutput | Should -BeNullOrEmpty
        }
    }
}
