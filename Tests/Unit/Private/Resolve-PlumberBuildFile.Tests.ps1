BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../../Plumber.psd1" -Force
    }
}

Describe 'Resolve-PlumberBuildFile' {
    It 'resolves an explicit relative build file' {
        $moduleRoot = Join-Path $TestDrive 'ExplicitModule'
        New-Item -Path $moduleRoot -ItemType Directory | Out-Null
        Set-Content -Path (Join-Path $moduleRoot 'custom.build.ps1') -Value ''

        Push-Location $moduleRoot
        try {
            InModuleScope Plumber {
                $buildFile = Resolve-PlumberBuildFile -BuildFile 'custom.build.ps1'

                Split-Path $buildFile -Leaf | Should -Be 'custom.build.ps1'
            }
        } finally {
            Pop-Location
        }
    }

    It 'resolves an explicit absolute build file' {
        $moduleRoot = Join-Path $TestDrive 'AbsoluteModule'
        New-Item -Path $moduleRoot -ItemType Directory | Out-Null
        $expected = Join-Path $moduleRoot 'custom.build.ps1'
        Set-Content -Path $expected -Value ''

        InModuleScope Plumber -Parameters @{Expected = $expected} {
            Resolve-PlumberBuildFile -BuildFile $Expected |
                Should -Be $Expected
        }
    }

    It 'resolves a build file matching the current directory manifest' {
        $moduleRoot = Join-Path $TestDrive 'ManifestModule'
        New-Item -Path $moduleRoot -ItemType Directory | Out-Null
        Set-Content -Path (Join-Path $moduleRoot 'ManifestModule.psd1') -Value '@{}'
        Set-Content -Path (Join-Path $moduleRoot 'ManifestModule.build.ps1') -Value ''
        Set-Content -Path (Join-Path $moduleRoot 'other.build.ps1') -Value ''

        Push-Location $moduleRoot
        try {
            InModuleScope Plumber {
                $buildFile = Resolve-PlumberBuildFile

                Split-Path $buildFile -Leaf | Should -Be 'ManifestModule.build.ps1'
            }
        } finally {
            Pop-Location
        }
    }

    It 'resolves a single build file when no matching manifest exists' {
        $moduleRoot = Join-Path $TestDrive 'SingleBuildModule'
        New-Item -Path $moduleRoot -ItemType Directory | Out-Null
        Set-Content -Path (Join-Path $moduleRoot 'custom.build.ps1') -Value ''

        Push-Location $moduleRoot
        try {
            InModuleScope Plumber {
                $buildFile = Resolve-PlumberBuildFile

                Split-Path $buildFile -Leaf | Should -Be 'custom.build.ps1'
            }
        } finally {
            Pop-Location
        }
    }

    It 'throws when an explicit build file is missing' {
        $moduleRoot = Join-Path $TestDrive 'MissingExplicitModule'
        New-Item -Path $moduleRoot -ItemType Directory | Out-Null

        Push-Location $moduleRoot
        try {
            InModuleScope Plumber {
                {Resolve-PlumberBuildFile -BuildFile 'missing.build.ps1'} |
                    Should -Throw -ExpectedMessage 'Build file not found*'
            }
        } finally {
            Pop-Location
        }
    }

    It 'throws when multiple build files are ambiguous' {
        $moduleRoot = Join-Path $TestDrive 'AmbiguousModule'
        New-Item -Path $moduleRoot -ItemType Directory | Out-Null
        Set-Content -Path (Join-Path $moduleRoot 'first.build.ps1') -Value ''
        Set-Content -Path (Join-Path $moduleRoot 'second.build.ps1') -Value ''

        Push-Location $moduleRoot
        try {
            InModuleScope Plumber {
                {Resolve-PlumberBuildFile} |
                    Should -Throw -ExpectedMessage 'Multiple build files found*'
            }
        } finally {
            Pop-Location
        }
    }

    It 'throws when no build file is found' {
        $moduleRoot = Join-Path $TestDrive 'NoBuildModule'
        New-Item -Path $moduleRoot -ItemType Directory | Out-Null

        Push-Location $moduleRoot
        try {
            InModuleScope Plumber {
                {Resolve-PlumberBuildFile} |
                    Should -Throw -ExpectedMessage 'No build file found*'
            }
        } finally {
            Pop-Location
        }
    }
}
