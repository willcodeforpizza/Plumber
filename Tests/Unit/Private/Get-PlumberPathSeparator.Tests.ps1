BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../../Plumber.psd1" -Force
    }
}

Describe 'Get-PlumberPathSeparator' {
    BeforeEach {
        $script:filePath = Join-Path $TestDrive "fixture-$([guid]::NewGuid().Guid).ps1"
    }

    It 'flags an expandable string with a backslash path separator' {
        '$x = "$BuildRoot\Tests\Unit"' | Set-Content -Path $script:filePath
        InModuleScope Plumber -Parameters @{FilePath = $script:filePath} {
            $hits = @(Get-PlumberPathSeparator -Path $FilePath)
            $hits.Count | Should -Be 1
            $hits[0].Line | Should -Be 1
            $hits[0].Text | Should -Be '"$BuildRoot\Tests\Unit"'
        }
    }

    It 'flags a backslash before a variable reference' {
        '$x = "$BuildRoot\$name.psm1"' | Set-Content -Path $script:filePath
        InModuleScope Plumber -Parameters @{FilePath = $script:filePath} {
            $hits = @(Get-PlumberPathSeparator -Path $FilePath)
            $hits.Count | Should -Be 1
        }
    }

    It 'flags a single-quoted path literal' {
        "`$x = 'C:\Users\foo'" | Set-Content -Path $script:filePath
        InModuleScope Plumber -Parameters @{FilePath = $script:filePath} {
            $hits = @(Get-PlumberPathSeparator -Path $FilePath)
            $hits.Count | Should -Be 1
        }
    }

    It 'does not flag regex character classes' {
        @(
            "`$x -match '\d+'"
            "`$y -match '\s*foo'"
            "`$z -match '\w+\b'"
        ) | Set-Content -Path $script:filePath
        InModuleScope Plumber -Parameters @{FilePath = $script:filePath} {
            $hits = @(Get-PlumberPathSeparator -Path $FilePath)
            $hits.Count | Should -Be 0
        }
    }

    It 'does not flag regex metachar escapes' {
        @(
            "`$x -match '\.'"
            "`$y -replace '\\','/'"
            "`$z -split '\|'"
        ) | Set-Content -Path $script:filePath
        InModuleScope Plumber -Parameters @{FilePath = $script:filePath} {
            $hits = @(Get-PlumberPathSeparator -Path $FilePath)
            $hits.Count | Should -Be 0
        }
    }

    It 'does not flag a single-character backslash literal' {
        "`$x = `$y.Replace('\', '/')" | Set-Content -Path $script:filePath
        InModuleScope Plumber -Parameters @{FilePath = $script:filePath} {
            $hits = @(Get-PlumberPathSeparator -Path $FilePath)
            $hits.Count | Should -Be 0
        }
    }

    It 'does not flag strings used as -match operands even with path-like content' {
        "`$x -match 'Tests\Unit'" | Set-Content -Path $script:filePath
        InModuleScope Plumber -Parameters @{FilePath = $script:filePath} {
            $hits = @(Get-PlumberPathSeparator -Path $FilePath)
            $hits.Count | Should -Be 0
        }
    }

    It 'does not flag strings used as -replace operands' {
        "`$x -replace '\\d+', 'N'" | Set-Content -Path $script:filePath
        InModuleScope Plumber -Parameters @{FilePath = $script:filePath} {
            $hits = @(Get-PlumberPathSeparator -Path $FilePath)
            $hits.Count | Should -Be 0
        }
    }

    It 'reports multiple hits in one file with correct line numbers' {
        @(
            '$a = "$BuildRoot\one"'
            '$b = "ignored"'
            '$c = "$BuildRoot\two"'
        ) | Set-Content -Path $script:filePath
        InModuleScope Plumber -Parameters @{FilePath = $script:filePath} {
            $hits = @(Get-PlumberPathSeparator -Path $FilePath)
            $hits.Count | Should -Be 2
            $hits[0].Line | Should -Be 1
            $hits[1].Line | Should -Be 3
        }
    }

    It 'throws when the file cannot be parsed' {
        'function {' | Set-Content -Path $script:filePath
        InModuleScope Plumber -Parameters @{FilePath = $script:filePath} {
            { Get-PlumberPathSeparator -Path $FilePath } |
                Should -Throw -ExpectedMessage "*Failed to parse*"
        }
    }
}
