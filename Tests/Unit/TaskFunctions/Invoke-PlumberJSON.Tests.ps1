BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../../Plumber.psd1" -Force
    }
}

Describe 'Invoke-PlumberJSON' {
    BeforeEach {
        $script:buildRoot = Join-Path $TestDrive 'JsonModule'
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
}
