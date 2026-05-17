BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../../Plumber.psd1" -Force
    }
}

Describe 'Get-PlumberLineContinuation' {
    BeforeEach {
        $script:filePath = Join-Path $TestDrive "fixture-$([guid]::NewGuid().Guid).ps1"
    }

    It 'flags a real line-continuation backtick' {
        $fixture = @'
Get-Foo `
    -Bar 1
'@
        Set-Content -Path $script:filePath -Value $fixture
        InModuleScope Plumber -Parameters @{FilePath = $script:filePath} {
            $hits = @(Get-PlumberLineContinuation -Path $FilePath)
            $hits.Count | Should -Be 1
            $hits[0].Line | Should -Be 1
        }
    }

    It 'does not flag an escaped backtick pair at end of line' {
        # A trailing pair of backticks is a literal backtick character in
        # PowerShell, not a line continuation.
        $fixture = @'
$x = "ends with ``"
'@
        Set-Content -Path $script:filePath -Value $fixture
        InModuleScope Plumber -Parameters @{FilePath = $script:filePath} {
            $hits = @(Get-PlumberLineContinuation -Path $FilePath)
            $hits.Count | Should -Be 0
        }
    }

    It 'does not flag a trailing backtick inside a here-string' {
        $fixture = @'
$x = @"
first line ending with `
second line
"@
'@
        Set-Content -Path $script:filePath -Value $fixture
        InModuleScope Plumber -Parameters @{FilePath = $script:filePath} {
            $hits = @(Get-PlumberLineContinuation -Path $FilePath)
            $hits.Count | Should -Be 0
        }
    }

    It 'does not flag a trailing backtick inside a block comment' {
        $fixture = @'
<#
    .EXAMPLE
    line with trailing backtick `
    next line of docs
#>
function Test-Thing {}
'@
        Set-Content -Path $script:filePath -Value $fixture
        InModuleScope Plumber -Parameters @{FilePath = $script:filePath} {
            $hits = @(Get-PlumberLineContinuation -Path $FilePath)
            $hits.Count | Should -Be 0
        }
    }

    It 'does not flag a trailing backtick inside a single-quoted string spanning lines' {
        $fixture = @"
`$x = 'one
two ``
three'
"@
        Set-Content -Path $script:filePath -Value $fixture
        InModuleScope Plumber -Parameters @{FilePath = $script:filePath} {
            $hits = @(Get-PlumberLineContinuation -Path $FilePath)
            $hits.Count | Should -Be 0
        }
    }

    It 'reports multiple line continuations with correct line numbers' {
        $fixture = @'
Get-Foo `
    -Bar 1

Get-Baz `
    -Qux 2
'@
        Set-Content -Path $script:filePath -Value $fixture
        InModuleScope Plumber -Parameters @{FilePath = $script:filePath} {
            $hits = @(Get-PlumberLineContinuation -Path $FilePath)
            $hits.Count | Should -Be 2
            $hits[0].Line | Should -Be 1
            $hits[1].Line | Should -Be 4
        }
    }
}
