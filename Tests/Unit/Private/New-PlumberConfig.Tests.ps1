BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../../Plumber.psd1" -Force
    }
}

Describe 'New-PlumberConfig' {
    It 'sets defaults for optional configuration' {
        InModuleScope Plumber {
            $config = New-PlumberConfig

            $config.CoverageMinimum | Should -Be 75
            $config.FileScope | Should -Be 'All'
            $config.IncludeTestsInPssa | Should -BeTrue
            $config.ExcludeTasks | Should -Be @()
            $config.ExcludePaths.Count | Should -Be 0
            $config.LocalTasks | Should -Be @()
            $config.PublicFunctionPrefix | Should -BeNullOrEmpty
            $config.PublicFunctionPrefixExclusions | Should -Be @()
            $config.StreamPesterOutput | Should -BeTrue
            $config.VersionIncludePrerelease | Should -BeFalse
            $config.VersionRemote | Should -Be 'origin'
            $config.VersionSource | Should -Be 'PSGallery'
        }
    }

    It 'overrides configured values and normalizes empty collections' {
        InModuleScope Plumber {
            $config = New-PlumberConfig -Config @{
                CoverageMinimum = 90
                ExcludeTasks    = $null
                ExcludePaths    = $null
                LocalTasks      = $null
                FileScope       = 'Changed'
                PublicFunctionPrefix = 'Thing'
                PublicFunctionPrefixExclusions = $null
                StreamPesterOutput = $false
                VersionIncludePrerelease = $true
                VersionRemote = 'upstream'
                VersionSource = 'GitTag'
            }

            $config.CoverageMinimum | Should -Be 90
            $config.FileScope | Should -Be 'Changed'
            $config.ExcludeTasks | Should -Be @()
            $config.ExcludePaths.Count | Should -Be 0
            $config.LocalTasks | Should -Be @()
            $config.PublicFunctionPrefix | Should -Be 'Thing'
            $config.PublicFunctionPrefixExclusions | Should -Be @()
            $config.StreamPesterOutput | Should -BeFalse
            $config.VersionIncludePrerelease | Should -BeTrue
            $config.VersionRemote | Should -Be 'upstream'
            $config.VersionSource | Should -Be 'GitTag'
        }
    }

    It 'uses the build invocation Pester output mode when provided' {
        InModuleScope Plumber {
            Set-Variable -Name PlumberStreamPesterOutput -Scope Global -Value $false

            try {
                $config = New-PlumberConfig -Config @{
                    StreamPesterOutput = $true
                }

                $config.StreamPesterOutput | Should -BeFalse
            } finally {
                Remove-Variable -Name PlumberStreamPesterOutput -Scope Global -ErrorAction SilentlyContinue
            }
        }
    }
}
