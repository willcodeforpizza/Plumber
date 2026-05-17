BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../../Plumber.psd1" -Force
    }
}

Describe 'Get-PlumberToDoComment' {
    BeforeEach {
        $script:filePath = Join-Path $TestDrive "fixture-$([guid]::NewGuid().Guid).ps1"
    }

    It 'flags a leading-comment TODO with a message' {
        '# TODO: refactor this' | Set-Content -Path $script:filePath
        InModuleScope Plumber -Parameters @{FilePath = $script:filePath} {
            $hits = @(Get-PlumberToDoComment -Path $FilePath)
            $hits.Count | Should -Be 1
            $hits[0].Line | Should -Be 1
            $hits[0].Message | Should -Be 'refactor this'
        }
    }

    It 'flags an inline TODO comment after code on the same line' {
        '$x = 1 # TODO: handle nulls' | Set-Content -Path $script:filePath
        InModuleScope Plumber -Parameters @{FilePath = $script:filePath} {
            $hits = @(Get-PlumberToDoComment -Path $FilePath)
            $hits.Count | Should -Be 1
            $hits[0].Message | Should -Be 'handle nulls'
        }
    }

    It 'flags a TODO with no colon and no message' {
        '# TODO' | Set-Content -Path $script:filePath
        InModuleScope Plumber -Parameters @{FilePath = $script:filePath} {
            $hits = @(Get-PlumberToDoComment -Path $FilePath)
            $hits.Count | Should -Be 1
            $hits[0].Message | Should -BeNullOrEmpty
        }
    }

    It 'does not flag TODO inside a string literal' {
        '$message = "current TODO list"' | Set-Content -Path $script:filePath
        InModuleScope Plumber -Parameters @{FilePath = $script:filePath} {
            $hits = @(Get-PlumberToDoComment -Path $FilePath)
            $hits.Count | Should -Be 0
        }
    }

    It 'does not flag TODO inside a block comment' {
        @(
            '<#'
            '    .EXAMPLE'
            '    A failing example: # TODO: forgot this'
            '#>'
            'function Test-Thing {}'
        ) | Set-Content -Path $script:filePath
        InModuleScope Plumber -Parameters @{FilePath = $script:filePath} {
            $hits = @(Get-PlumberToDoComment -Path $FilePath)
            $hits.Count | Should -Be 0
        }
    }

    It 'does not flag TODOMaster (word-boundary required)' {
        '# TODOMaster setting was renamed' | Set-Content -Path $script:filePath
        InModuleScope Plumber -Parameters @{FilePath = $script:filePath} {
            $hits = @(Get-PlumberToDoComment -Path $FilePath)
            $hits.Count | Should -Be 0
        }
    }

    It 'reports multiple TODOs with correct line numbers' {
        @(
            '# TODO: first'
            'function Test-Thing {}'
            '$x = 1 # TODO: second'
        ) | Set-Content -Path $script:filePath
        InModuleScope Plumber -Parameters @{FilePath = $script:filePath} {
            $hits = @(Get-PlumberToDoComment -Path $FilePath)
            $hits.Count | Should -Be 2
            $hits[0].Line | Should -Be 1
            $hits[1].Line | Should -Be 3
        }
    }
}
