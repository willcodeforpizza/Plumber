BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../Plumber.psd1" -Force
    }
}

Describe 'Get-PlumberTaskFile' {
    BeforeEach {
        $script:buildRoot = Join-Path $TestDrive 'Module'
        New-Item -Path $script:buildRoot -ItemType Directory -Force | Out-Null
        New-Item -Path (Join-Path $script:buildRoot 'Public') -ItemType Directory -Force | Out-Null
        New-Item -Path (Join-Path $script:buildRoot 'Resource') -ItemType Directory -Force | Out-Null
        New-Item -Path (Join-Path $script:buildRoot 'Resource/Schema') -ItemType Directory -Force | Out-Null
        New-Item -Path (Join-Path $script:buildRoot 'Tests/Assets') -ItemType Directory -Force | Out-Null

        Set-Content -Path (Join-Path $script:buildRoot 'Public/Invoke-Thing.ps1') -Value '$true'
        Set-Content -Path (Join-Path $script:buildRoot 'Public/Invoke-Other.psm1') -Value '$true'
        Set-Content -Path (Join-Path $script:buildRoot 'Resource/config.json') -Value '{}'
        Set-Content -Path (Join-Path $script:buildRoot 'Resource/Schema/config.schema.json') -Value '{}'
        Set-Content -Path (Join-Path $script:buildRoot 'Tests/Assets/Fixture.ps1') -Value '$true'
    }

    It 'gets files by extension' {
        InModuleScope Plumber -Parameters @{BuildRoot = $script:buildRoot} {
            $script:PlumberFiles = $null
            $script:PlumberChangedFiles = $null
            $script:PlumberChangedFilesLoaded = $false
            $script:PlumberConfig = @{
                BuildRoot    = $BuildRoot
                ExcludePaths = @{}
                FileScope    = 'All'
            }

            $files = Get-PlumberTaskFile -Task PSScriptAnalyzer -Extension '.ps1'

            $files.Name | Should -Contain 'Invoke-Thing.ps1'
            $files.Name | Should -Contain 'Fixture.ps1'
            $files.Name | Should -Not -Contain 'Invoke-Other.psm1'
        }
    }

    It 'applies task-scoped exclusions' {
        InModuleScope Plumber -Parameters @{BuildRoot = $script:buildRoot} {
            $script:PlumberFiles = $null
            $script:PlumberChangedFiles = $null
            $script:PlumberChangedFilesLoaded = $false
            $script:PlumberConfig = @{
                BuildRoot    = $BuildRoot
                ExcludePaths = @{
                    Backticks = @('Tests/Assets/*')
                }
                FileScope    = 'All'
            }

            $files = Get-PlumberTaskFile -Task Backticks -Extension '.ps1'

            $files.Name | Should -Contain 'Invoke-Thing.ps1'
            $files.Name | Should -Not -Contain 'Fixture.ps1'
        }
    }

    It 'filters files to a path' {
        InModuleScope Plumber -Parameters @{BuildRoot = $script:buildRoot} {
            $script:PlumberFiles = $null
            $script:PlumberChangedFiles = $null
            $script:PlumberChangedFilesLoaded = $false
            $script:PlumberConfig = @{
                BuildRoot    = $BuildRoot
                ExcludePaths = @{}
                FileScope    = 'All'
            }

            $files = Get-PlumberTaskFile -Task JSON -Extension '.json' -Path Resource

            $files.Name | Should -Contain 'config.json'
            $files.Name | Should -Contain 'config.schema.json'
            $files.Name | Should -Not -Contain 'Invoke-Thing.ps1'
        }
    }

    It 'limits files to changed files before extension, path and exclusion filters' {
        InModuleScope Plumber -Parameters @{BuildRoot = $script:buildRoot} {
            $script:PlumberFiles = $null
            $script:PlumberChangedFilesLoaded = $true
            $script:PlumberChangedFiles = @(
                Get-Item (Join-Path $BuildRoot 'Public/Invoke-Thing.ps1')
                Get-Item (Join-Path $BuildRoot 'Resource/config.json')
                Get-Item (Join-Path $BuildRoot 'Tests/Assets/Fixture.ps1')
            )
            $script:PlumberConfig = @{
                BuildRoot    = $BuildRoot
                ExcludePaths = @{
                    JSON = @('Tests/Assets/*')
                }
                FileScope    = 'Changed'
            }

            $files = Get-PlumberTaskFile -Task JSON -Extension '.json' -Path Resource

            $files.Name | Should -Contain 'config.json'
            $files.Name | Should -Not -Contain 'config.schema.json'
            $files.Name | Should -Not -Contain 'Invoke-Thing.ps1'
            $files.Name | Should -Not -Contain 'Fixture.ps1'
        }
    }

    It 'writes the changed file count when changed scope is loaded' {
        InModuleScope Plumber -Parameters @{BuildRoot = $script:buildRoot} {
            Mock Get-PlumberChangedFile {
                Get-Item (Join-Path $BuildRoot 'Public/Invoke-Thing.ps1')
            }
            function Write-Build {
                param ($Color, $Message)

                $null = $Color
                $null = $Message
            }
            Mock Write-Build {}

            $script:PlumberFiles = $null
            $script:PlumberChangedFiles = $null
            $script:PlumberChangedFilesLoaded = $false
            $script:PlumberConfig = @{
                BuildRoot    = $BuildRoot
                ExcludePaths = @{}
                FileScope    = 'Changed'
                ModuleRoot   = Split-Path $PSScriptRoot -Parent
            }

            Get-PlumberTaskFile -Task Backticks | Out-Null

            Should -Invoke Write-Build -Times 1 -Exactly -ParameterFilter {
                $Color -eq 'Yellow' -and $Message -eq 'FileScope Changed: 1 file(s)'
            }
        }
    }

    It 'writes when changed scope has no files' {
        InModuleScope Plumber -Parameters @{BuildRoot = $script:buildRoot} {
            Mock Get-PlumberChangedFile {}
            function Write-Build {
                param ($Color, $Message)

                $null = $Color
                $null = $Message
            }
            Mock Write-Build {}

            $script:PlumberFiles = $null
            $script:PlumberChangedFiles = $null
            $script:PlumberChangedFilesLoaded = $false
            $script:PlumberConfig = @{
                BuildRoot    = $BuildRoot
                ExcludePaths = @{}
                FileScope    = 'Changed'
                ModuleRoot   = Split-Path $PSScriptRoot -Parent
            }

            Get-PlumberTaskFile -Task Backticks | Out-Null

            Should -Invoke Write-Build -Times 1 -Exactly -ParameterFilter {
                $Color -eq 'Yellow' -and $Message -eq 'FileScope Changed: no changed files'
            }
        }
    }

    It 'throws for unsupported file scopes' {
        InModuleScope Plumber -Parameters @{BuildRoot = $script:buildRoot} {
            $script:PlumberFiles = $null
            $script:PlumberChangedFiles = $null
            $script:PlumberChangedFilesLoaded = $false
            $script:PlumberConfig = @{
                BuildRoot    = $BuildRoot
                ExcludePaths = @{}
                FileScope    = 'Touched'
            }

            {Get-PlumberTaskFile -Task JSON} |
                Should -Throw -ExpectedMessage "Unsupported FileScope 'Touched'*"
        }
    }
}
