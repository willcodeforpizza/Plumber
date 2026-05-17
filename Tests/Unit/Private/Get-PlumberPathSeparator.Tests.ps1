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

    It 'does not flag regex `\$` followed by `{` (regex escape for literal $)' {
        $fixture = @'
$x -match '\$\{([A-Za-z_]+)\}'
'@
        Set-Content -Path $script:filePath -Value $fixture
        InModuleScope Plumber -Parameters @{FilePath = $script:filePath} {
            $hits = @(Get-PlumberPathSeparator -Path $FilePath)
            $hits.Count | Should -Be 0
        }
    }

    It 'does not flag regex `\$` followed by `(` (regex escape for literal $)' {
        $fixture = @'
$x -match '\$([A-Za-z_]+)'
'@
        Set-Content -Path $script:filePath -Value $fixture
        InModuleScope Plumber -Parameters @{FilePath = $script:filePath} {
            $hits = @(Get-PlumberPathSeparator -Path $FilePath)
            $hits.Count | Should -Be 0
        }
    }

    It 'flags `\$variable` paths even with the tightened $-handling' {
        $fixture = @'
$x = "$BuildRoot\$script:moduleName.psm1"
'@
        Set-Content -Path $script:filePath -Value $fixture
        InModuleScope Plumber -Parameters @{FilePath = $script:filePath} {
            $hits = @(Get-PlumberPathSeparator -Path $FilePath)
            $hits.Count | Should -Be 1
        }
    }

    It 'does not flag strings starting with (?... (regex prefix shape)' {
        $fixture = @'
$pattern = '(?im)(?<!\w)\$playbookName\s*=\s*foo'
'@
        Set-Content -Path $script:filePath -Value $fixture
        InModuleScope Plumber -Parameters @{FilePath = $script:filePath} {
            $hits = @(Get-PlumberPathSeparator -Path $FilePath)
            $hits.Count | Should -Be 0
        }
    }

    It 'does not flag strings assigned to a $*Pattern variable' {
        $fixture = @'
$bracedPattern = '\$\{([A-Za-z_]+)\}'
$bareRegex = '\$([A-Za-z_]+)'
'@
        Set-Content -Path $script:filePath -Value $fixture
        InModuleScope Plumber -Parameters @{FilePath = $script:filePath} {
            $hits = @(Get-PlumberPathSeparator -Path $FilePath)
            $hits.Count | Should -Be 0
        }
    }

    It 'does not flag strings inside the array argument of -replace' {
        # `$x -replace "a", "b"` parses as a binary expression where the
        # right operand is an array literal of ["a", "b"]. Both array
        # elements should count as being in regex context.
        $fixture = @'
$x = $y -replace "'", "'\''"
'@
        Set-Content -Path $script:filePath -Value $fixture
        InModuleScope Plumber -Parameters @{FilePath = $script:filePath} {
            $hits = @(Get-PlumberPathSeparator -Path $FilePath)
            $hits.Count | Should -Be 0
        }
    }
}
