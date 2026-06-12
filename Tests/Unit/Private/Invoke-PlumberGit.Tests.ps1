BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../../Plumber.psd1" -Force
    }
}

Describe 'Invoke-PlumberGit' {
    BeforeEach {
        $script:repoRoot = Join-Path $TestDrive 'GitRepo'
        Remove-Item -Path $script:repoRoot -Recurse -Force -ErrorAction SilentlyContinue
        & git init --quiet --initial-branch=main $script:repoRoot 2>$null | Out-Null
        $commitArgs = @(
            '-C', $script:repoRoot
            '-c', 'user.name=plumber'
            '-c', 'user.email=plumber@example.com'
            'commit', '--quiet', '--allow-empty', '-m', 'init'
        )
        & git @commitArgs 2>$null | Out-Null
    }

    It 'returns stdout lines as strings' {
        InModuleScope Plumber -Parameters @{RepoRoot = $script:repoRoot} {
            $result = Invoke-PlumberGit -ArgumentList @(
                '-C', $RepoRoot, 'rev-parse', '--show-toplevel'
            )

            $result | Should -BeOfType [string]
            $result | Should -Not -BeNullOrEmpty
        }
    }

    It 'does not return stderr output on success' {
        # git checkout -b reports 'Switched to a new branch' on stderr with
        # exit code 0; that line must not appear in the returned output.
        InModuleScope Plumber -Parameters @{RepoRoot = $script:repoRoot} {
            $result = Invoke-PlumberGit -ArgumentList @(
                '-C', $RepoRoot, 'checkout', '-b', 'feature'
            )

            $result | Should -BeNullOrEmpty
        }
    }

    It 'does not emit ErrorRecord objects on success' {
        InModuleScope Plumber -Parameters @{RepoRoot = $script:repoRoot} {
            $result = @(Invoke-PlumberGit -ArgumentList @(
                '-C', $RepoRoot, 'log', '--format=%H'
            ))

            foreach ($line in $result) {
                $line | Should -BeOfType [string]
            }
        }
    }

    It 'throws with stderr detail when git fails' {
        InModuleScope Plumber -Parameters @{RepoRoot = $script:repoRoot} {
            {
                Invoke-PlumberGit -ArgumentList @(
                    '-C', $RepoRoot, 'rev-parse', '--verify', 'doesnotexist'
                )
            } | Should -Throw -ExpectedMessage '*rev-parse --verify doesnotexist failed.*fatal*'
        }
    }
}
