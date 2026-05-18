BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../../Plumber.psd1" -Force
    }
}

Describe 'Invoke-PlumberToDo' {
    BeforeEach {
        $script:buildRoot = Join-Path $TestDrive 'ToDoModule'
        $script:publicRoot = Join-Path $script:buildRoot 'Public'
        New-Item -Path $script:publicRoot -ItemType Directory -Force | Out-Null
    }

    It 'reports TODO comments' {
        Set-Content -Path (Join-Path $script:publicRoot 'Invoke-Thing.ps1') -Value @(
            'function Invoke-Thing {'
            '    # TODO: fix this'
            '}'
        )

        InModuleScope Plumber -Parameters @{BuildRoot = $script:buildRoot} {
            $script:PlumberFiles = $null
            $script:PlumberChangedFiles = $null
            $script:PlumberChangedFilesLoaded = $false
            $script:PlumberConfig = @{
                BuildRoot = $BuildRoot
                FileScope = 'All'
                Tasks     = @{
                    ToDo = @{
                        Exclude = @()
                    }
                }
            }

            { Invoke-PlumberToDo -ErrorAction Stop } |
                Should -Throw -ExpectedMessage '*Invoke-Thing.ps1:2 - fix this*'
        }
    }

    It 'ignores TODO markers inside strings' {
        Set-Content -Path (Join-Path $script:publicRoot 'Invoke-Thing.ps1') -Value @(
            'function Invoke-Thing {'
            '    "This text mentions #TODO: without creating a TODO comment"'
            '}'
        )

        InModuleScope Plumber -Parameters @{BuildRoot = $script:buildRoot} {
            $script:PlumberFiles = $null
            $script:PlumberChangedFiles = $null
            $script:PlumberChangedFilesLoaded = $false
            $script:PlumberConfig = @{
                BuildRoot = $BuildRoot
                FileScope = 'All'
                Tasks     = @{
                    ToDo = @{
                        Exclude = @()
                    }
                }
            }

            { Invoke-PlumberToDo -ErrorAction Stop } | Should -Not -Throw
        }
    }
}
