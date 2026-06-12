BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../../Plumber.psd1" -Force
    }
}

Describe 'Invoke-PlumberJSON' {
    BeforeEach {
        $script:buildRoot = Join-Path $TestDrive 'JsonModule'
        Remove-Item -Path $script:buildRoot -Recurse -Force -ErrorAction SilentlyContinue
        $script:resourceRoot = Join-Path $script:buildRoot 'Resource/Nested'
        New-Item -Path $script:resourceRoot -ItemType Directory -Force | Out-Null
    }

    It 'reports invalid nested JSON files' {
        Set-Content -Path (Join-Path $script:resourceRoot 'config.json') -Value '{"name":'

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
                    JSON = @{
                        Exclude = @()
                    }
                }
            }

            { Invoke-PlumberJSON -ErrorAction Stop } |
                Should -Throw -ExpectedMessage '*Invalid JSON*'
        }
    }

    It 'reports every invalid file in one aggregated error' {
        Set-Content -Path (Join-Path $script:resourceRoot 'invalid-one.json') -Value '{"name":'
        Set-Content -Path (Join-Path $script:resourceRoot 'invalid-two.json') -Value '[1,'

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
                    JSON = @{
                        Exclude = @()
                    }
                }
            }

            Invoke-PlumberJSON -ErrorAction SilentlyContinue -ErrorVariable jsonErrors

            $failures = @(
                $jsonErrors | Where-Object {$_.ToString() -like 'Invalid JSON in*'}
            )
            $failures.Count | Should -Be 1
            $failures[0].ToString() | Should -BeLike '*invalid-one.json*'
            $failures[0].ToString() | Should -BeLike '*invalid-two.json*'
        }
    }
}
