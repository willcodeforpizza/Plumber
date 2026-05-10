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
            $script:PlumberConfig = @{
                BuildRoot    = $BuildRoot
                ExcludePaths = @{}
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
            $script:PlumberConfig = @{
                BuildRoot    = $BuildRoot
                ExcludePaths = @{
                    Backticks = @('Tests/Assets/*')
                }
            }

            $files = Get-PlumberTaskFile -Task Backticks -Extension '.ps1'

            $files.Name | Should -Contain 'Invoke-Thing.ps1'
            $files.Name | Should -Not -Contain 'Fixture.ps1'
        }
    }

    It 'filters files to a path' {
        InModuleScope Plumber -Parameters @{BuildRoot = $script:buildRoot} {
            $script:PlumberFiles = $null
            $script:PlumberConfig = @{
                BuildRoot    = $BuildRoot
                ExcludePaths = @{}
            }

            $files = Get-PlumberTaskFile -Task JSON -Extension '.json' -Path Resource

            $files.Name | Should -Contain 'config.json'
            $files.Name | Should -Contain 'config.schema.json'
            $files.Name | Should -Not -Contain 'Invoke-Thing.ps1'
        }
    }
}
