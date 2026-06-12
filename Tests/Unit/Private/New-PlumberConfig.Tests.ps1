BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../../Plumber.psd1" -Force
    }
}

Describe 'New-PlumberConfig' {
    It 'sets defaults for optional configuration' {
        InModuleScope Plumber {
            $config = New-PlumberConfig

            $config.FileScope | Should -Be 'All'
            $config.IncludeModuleFolders | Should -Be @()
            $config.ExcludeDirectories | Should -Be @('.git', 'out')
            $config.Tasks.CodeCoverage.Minimum | Should -Be 75
            $config.Tasks.PSScriptAnalyzer.IncludeTests | Should -BeTrue
            $config.Tasks.ContainsKey('Exclude') | Should -BeFalse
            $config.Tasks.CodeQuality.RunWhen | Should -Be 'Always'
            $config.Tasks.ReleaseHygiene.RunWhen | Should -Be 'Always'
            $config.Tasks.Content.RunWhen | Should -Be 'Always'
            $config.Tasks.ModuleConventions.RunWhen | Should -Be 'Always'
            $config.Tasks.Backticks.Exclude | Should -Be @()
            $config.Tasks.Backticks.RunWhen | Should -Be 'Always'
            $config.Tasks.CodeCoverage.RunWhen | Should -Be 'Always'
            $config.Tasks.ModuleVersion.RunWhen | Should -Be 'Always'
            $config.Tasks.ChangelogUpdated.RunWhen | Should -Be 'Always'
            $config.Tasks.Manifest.RunWhen | Should -Be 'Always'
            $config.Tasks.PublicFunctions.RunWhen | Should -Be 'Always'
            $config.Tasks.FunctionFiles.RunWhen | Should -Be 'Always'
            $config.Tasks.Naming.RunWhen | Should -Be 'Always'
            $config.Tasks.Local | Should -Be @()
            $config.Tasks.PublicFunctionPrefix.Prefix | Should -BeNullOrEmpty
            $config.Tasks.PublicFunctionPrefix.Exclusions | Should -Be @()
            $config.Tasks.PesterUnit.StreamOutput | Should -BeTrue
            $config.Tasks.PesterIntegration.StreamOutput | Should -BeTrue
            $config.Tasks.ModuleVersion.IncludePrerelease | Should -BeFalse
            $config.Tasks.ModuleVersion.Remote | Should -Be 'origin'
            $config.Tasks.ModuleVersion.Source | Should -Be 'PSGallery'
        }
    }

    It 'overrides configured values and normalizes empty collections' {
        InModuleScope Plumber {
            $config = New-PlumberConfig -Config @{
                FileScope = 'Changed'
                IncludeModuleFolders = @('TaskFunctions')
                Tasks     = @{
                    CodeCoverage = @{
                        Minimum     = 90
                        RunWhen = 'OnRelease'
                    }
                    Content = @{
                        RunWhen = 'Never'
                    }
                    Local = $null
                    PublicFunctionPrefix = @{
                        Prefix     = 'Thing'
                        Exclusions = $null
                    }
                    PesterUnit = @{
                        StreamOutput = $false
                    }
                    ModuleVersion = @{
                        IncludePrerelease = $true
                        Remote            = 'upstream'
                        Source            = 'GitTag'
                    }
                }
            }

            $config.FileScope | Should -Be 'Changed'
            $config.IncludeModuleFolders | Should -Be @('TaskFunctions')
            $config.Tasks.CodeCoverage.Minimum | Should -Be 90
            $config.Tasks.CodeCoverage.RunWhen | Should -Be 'OnRelease'
            $config.Tasks.Content.RunWhen | Should -Be 'Never'
            $config.Tasks.ContainsKey('Exclude') | Should -BeFalse
            $config.Tasks.Local | Should -Be @()
            $config.Tasks.PublicFunctionPrefix.Prefix | Should -Be 'Thing'
            $config.Tasks.PublicFunctionPrefix.Exclusions | Should -Be @()
            $config.Tasks.PesterUnit.StreamOutput | Should -BeFalse
            $config.Tasks.ModuleVersion.IncludePrerelease | Should -BeTrue
            $config.Tasks.ModuleVersion.Remote | Should -Be 'upstream'
            $config.Tasks.ModuleVersion.Source | Should -Be 'GitTag'
        }
    }

    It 'uses the build invocation Pester output mode when provided' {
        InModuleScope Plumber {
            Set-Variable -Name PlumberStreamPesterOutput -Scope Global -Value $false

            try {
                $config = New-PlumberConfig -Config @{
                    Tasks = @{
                        PesterIntegration = @{
                            StreamOutput = $true
                        }
                        PesterUnit = @{
                            StreamOutput = $true
                        }
                    }
                }

                $config.Tasks.PesterIntegration.StreamOutput | Should -BeFalse
                $config.Tasks.PesterUnit.StreamOutput | Should -BeFalse
            } finally {
                Remove-Variable -Name PlumberStreamPesterOutput -Scope Global -ErrorAction SilentlyContinue
            }
        }
    }
}
