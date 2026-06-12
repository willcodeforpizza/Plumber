BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../../Plumber.psd1" -Force
    }
}

Describe 'Invoke-PlumberYAML' {
    BeforeEach {
        $script:buildRoot = Join-Path $TestDrive 'YamlModule'
        Remove-Item -Path $script:buildRoot -Recurse -Force -ErrorAction SilentlyContinue
        $script:resourceRoot = Join-Path $script:buildRoot 'Resource'
        New-Item -Path $script:resourceRoot -ItemType Directory -Force | Out-Null
    }

    It 'reports invalid YAML files' {
        Set-Content -Path (Join-Path $script:resourceRoot 'config.yml') -Value @(
            'name: build'
            'steps:'
            '  - task: validate'
            '    invalid'
        )

        InModuleScope Plumber -Parameters @{BuildRoot = $script:buildRoot} {
            function Write-Build {
                param ($Color, $Message)

                $null = $Color
                $null = $Message
            }

            $script:PlumberFiles = $null
            $script:PlumberChangedFiles = $null
            $script:PlumberChangedFilesLoaded = $false
            $script:PlumberConfig = @{
                BuildRoot = $BuildRoot
                FileScope = 'All'
                Tasks     = @{
                    YAML = @{
                        Exclude = @()
                    }
                }
            }

            { Invoke-PlumberYAML -ErrorAction Stop } |
                Should -Throw -ExpectedMessage '*Invalid YAML*'
        }
    }

    It 'reports every invalid file in one aggregated error' {
        Set-Content -Path (Join-Path $script:resourceRoot 'invalid-one.yml') -Value @(
            'name: build'
            '  bad-indent: true'
        )
        Set-Content -Path (Join-Path $script:resourceRoot 'invalid-two.yml') -Value @(
            'steps:'
            '  - task: validate'
            '    invalid'
        )

        InModuleScope Plumber -Parameters @{BuildRoot = $script:buildRoot} {
            function Write-Build {
                param ($Color, $Message)

                $null = $Color
                $null = $Message
            }

            $script:PlumberFiles = $null
            $script:PlumberChangedFiles = $null
            $script:PlumberChangedFilesLoaded = $false
            $script:PlumberConfig = @{
                BuildRoot = $BuildRoot
                FileScope = 'All'
                Tasks     = @{
                    YAML = @{
                        Exclude = @()
                    }
                }
            }

            Invoke-PlumberYAML -ErrorAction SilentlyContinue -ErrorVariable yamlErrors

            $failures = @(
                $yamlErrors | Where-Object {$_.ToString() -like 'Invalid YAML in*'}
            )
            $failures.Count | Should -Be 1
            $failures[0].ToString() | Should -BeLike '*invalid-one.yml*'
            $failures[0].ToString() | Should -BeLike '*invalid-two.yml*'
        }
    }
}
